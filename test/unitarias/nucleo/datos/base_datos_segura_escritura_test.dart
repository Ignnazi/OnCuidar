import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oncuidar/nucleo/almacen/almacen_secreto.dart';
import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';
import 'package:oncuidar/nucleo/conectividad/servicio_conectividad.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
import 'package:oncuidar/nucleo/red/cliente_api.dart';
import 'package:oncuidar/nucleo/sesion/servicio_sesion.dart';
import 'package:oncuidar/nucleo/sincronizacion/cola_escrituras.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../ayudas/offline.dart';

class SesionFalsa extends ServicioSesion {
  SesionFalsa(ClienteApi api)
    : super(api: api, almacen: AlmacenSecretoMemoria());

  SesionUsuario? usuario;

  @override
  SesionUsuario? get actual => usuario;
}

/// Cambia de cuenta justo mientras se revisa la red
class RedQueCambiaSesion extends ServicioConectividad {
  RedQueCambiaSesion(this.alRevisar);

  final void Function() alRevisar;

  @override
  Future<bool> estaEnLinea() async {
    alRevisar();
    return true;
  }

  @override
  Stream<bool> enLinea() => const Stream.empty();
}

void main() {
  late ColaEscrituras cola;

  BaseDatosSegura baseQueResponde(int codigo) {
    final api = ClienteApi(
      urlBase: 'http://localhost',
      obtenerToken: () => 't1',
      cliente: MockClient(
        (_) async => http.Response('{"error":"falla"}', codigo),
      ),
    );
    return BaseDatosSegura(
      api: api,
      uidPrueba: 'u1',
      cifrado: ServicioCifrado(api: api, almacen: AlmacenSecretoMemoria()),
      cola: cola,
      conectividad: ConectividadFalsa(),
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'oncuidar.flujo.u1./pacientes': '[]',
    });
    cola = ColaEscrituras();
  });

  for (final codigo in [500, 502, 503]) {
    test('un $codigo con red deja la escritura en la cola', () async {
      final base = baseQueResponde(codigo);

      await base.escribir(
        '/pacientes/p1',
        {'archivado': false},
        operacion: OperacionPendiente.crear,
        idPaciente: 'p1',
      );

      final pendientes = await cola.pendientes('u1');
      expect(pendientes.map((e) => e.ruta), ['/pacientes/p1']);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('oncuidar.flujo.u1./pacientes'), contains('p1'));
    });
  }

  test('un 400 se sigue avisando y no se encola', () async {
    final base = baseQueResponde(400);

    await expectLater(
      base.escribir('/pacientes/p1', {
        'archivado': false,
      }, operacion: OperacionPendiente.crear),
      throwsA(isA<ExcepcionApi>()),
    );
    expect(await cola.pendientes('u1'), isEmpty);
  });

  test(
    'si cambia la cuenta al escribir, queda en la cola de quien escribió',
    () async {
      final enviados = <String?>[];
      late final SesionFalsa sesion;
      final api = ClienteApi(
        urlBase: 'http://localhost',
        obtenerToken: () => sesion.actual?.token,
        cliente: MockClient((pedido) async {
          enviados.add(pedido.headers['Authorization']);
          return http.Response('{}', 200);
        }),
      );
      sesion = SesionFalsa(api)
        ..usuario = const SesionUsuario(
          uid: 'u1',
          correo: 'a@b.cl',
          token: 't1',
        );
      final base = BaseDatosSegura(
        api: api,
        sesion: sesion,
        cifrado: ServicioCifrado(api: api, almacen: AlmacenSecretoMemoria()),
        cola: cola,
        conectividad: RedQueCambiaSesion(
          () => sesion.usuario = const SesionUsuario(
            uid: 'u2',
            correo: 'c@d.cl',
            token: 't2',
          ),
        ),
      );

      await base.escribir(
        '/pacientes/p1',
        {'archivado': false},
        operacion: OperacionPendiente.crear,
        idPaciente: 'p1',
      );

      expect(enviados, isEmpty);
      expect((await cola.pendientes('u1')).map((e) => e.ruta), [
        '/pacientes/p1',
      ]);
      expect(await cola.pendientes('u2'), isEmpty);
    },
  );
}
