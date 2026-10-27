import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/nucleo/almacen/almacen_secreto.dart';
import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
import 'package:oncuidar/nucleo/red/cliente_api.dart';
import 'package:oncuidar/nucleo/sincronizacion/cola_escrituras.dart';
import 'package:oncuidar/nucleo/sincronizacion/orquestador_sincronizacion.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../ayudas/offline.dart';

/// Servidor falso que anota lo que recibe y puede responder con un error
class BaseFalsa extends BaseDatosSegura {
  BaseFalsa._(ClienteApi api)
    : super(
        api: api,
        cifrado: ServicioCifrado(api: api, almacen: AlmacenSecretoMemoria()),
      );

  factory BaseFalsa() => BaseFalsa._(
    ClienteApi(urlBase: 'http://localhost', obtenerToken: () => null),
  );

  final recibidas = <String>[];
  Object? error;
  Future<void> Function(EscrituraPendiente)? alRecibir;

  @override
  Future<void> aplicarEscrituraPendiente(EscrituraPendiente escritura) async {
    if (error != null) throw error!;
    recibidas.add(escritura.id);
    await alRecibir?.call(escritura);
  }
}

void main() {
  late ColaEscrituras cola;
  late BaseFalsa base;
  late ConectividadFalsa red;
  late OrquestadorSincronizacion orquestador;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cola = ColaEscrituras();
    base = BaseFalsa();
    red = ConectividadFalsa();
    orquestador = OrquestadorSincronizacion(
      cola: cola,
      base: base,
      conectividad: red,
      uidActual: () => 'u1',
      retardoBase: const Duration(hours: 1),
    );
  });

  tearDown(() => orquestador.dispose());

  Future<void> encolar(List<String> ids) async {
    for (final id in ids) {
      await cola.encolar('u1', escrituraDe(id: id));
    }
  }

  test('envía las escrituras en orden y vacía la cola', () async {
    await encolar(['e1', 'e2', 'e3']);
    await orquestador.drenar();
    expect(base.recibidas, ['e1', 'e2', 'e3']);
    expect(await cola.pendientes('u1'), isEmpty);
  });

  test('sin conexión no envía nada y al volver la red sí', () async {
    red.fijar(false);
    await encolar(['e1']);
    await orquestador.drenar();
    expect(base.recibidas, isEmpty);

    red.fijar(true);
    await orquestador.drenar();
    expect(base.recibidas, ['e1']);
  });

  test('dos sincronizaciones a la vez no envían dos veces lo mismo', () async {
    await encolar(['e1', 'e2']);
    await Future.wait([orquestador.drenar(), orquestador.drenar()]);
    expect(base.recibidas, ['e1', 'e2']);
  });

  test('un error de red deja la escritura pendiente para reintentar', () async {
    await encolar(['e1']);
    base.error = const ExcepcionApi.sinRed();
    await orquestador.drenar();
    final pendientes = await cola.pendientes('u1');
    expect(pendientes.single.intentos, 1);

    base.error = null;
    await orquestador.drenar();
    expect(base.recibidas, ['e1']);
  });

  test('un dato rechazado por el servidor pasa a fallidas', () async {
    await encolar(['e1', 'e2']);
    base.error = const ExcepcionApi(400, 'Datos inválidos');
    await orquestador.drenar();
    expect(await cola.resumen('u1'), const ResumenCola(fallidas: 2));
  });

  test('si la sesión vence los registros pendientes no se pierden', () async {
    await encolar(['e1', 'e2']);
    base.error = const ExcepcionApi(
      401,
      'Token inválido o vencido',
      esTokenInvalido: true,
    );
    await orquestador.drenar();
    final pendientes = await cola.pendientes('u1');
    expect(pendientes.map((e) => e.id), ['e1', 'e2']);
    expect(pendientes.first.intentos, 0);

    base.error = null;
    await orquestador.drenar();
    expect(base.recibidas, ['e1', 'e2']);
  });

  test('un error de red repetido nunca descarta el registro', () async {
    await encolar(['e1']);
    base.error = const ExcepcionApi.sinRed();
    for (var i = 0; i < 12; i++) {
      await orquestador.drenar();
    }
    expect(await cola.resumen('u1'), const ResumenCola(pendientes: 1));
  });

  test('lo que se quita mientras se envía ya no se manda', () async {
    await encolar(['e1']);
    await cola.encolar(
      'u1',
      escrituraDe(
        id: 'e2',
        pacienteId: 'p2',
        ruta: 'usuarios/u1/pacientes/p2/recordatorios/c1',
      ),
    );
    base.alRecibir = (_) => cola.quitarDePaciente('u1', 'p2');
    await orquestador.drenar();
    expect(base.recibidas, ['e1']);
  });

  test(
    'lo que llega durante un envío sale en la misma sincronización',
    () async {
      await encolar(['e1']);
      base.alRecibir = (e) async {
        if (e.id == 'e1') {
          await cola.encolar('u1', escrituraDe(id: 'e2'));
          await orquestador.drenar();
        }
      };
      await orquestador.drenar();
      expect(base.recibidas, ['e1', 'e2']);
      expect(await cola.pendientes('u1'), isEmpty);
    },
  );
}
