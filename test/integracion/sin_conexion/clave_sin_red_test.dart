import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/recordatorios/datos/repositorio_recordatorios.dart';
import 'package:oncuidar/caracteristicas/recordatorios/dominio/recordatorio.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/datos/repositorio_registros_clinicos.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';
import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
import 'package:oncuidar/nucleo/sincronizacion/cola_escrituras.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../ayudas/offline.dart';

const _clavePrueba = 'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';
const _uid = 'uid-clave';

RegistroClinico _registro() => RegistroClinico(
  id: 'r1',
  pacienteId: 'pacienteA',
  fecha: DateTime(2026, 10, 1),
  creadoEn: DateTime(2026, 10, 1),
  tipoRegistro: 'diario',
  observaciones: 'Reservado',
);

Recordatorio _recordatorio() => Recordatorio(
  id: '',
  pacienteId: 'pacienteA',
  tipo: 'cita',
  titulo: 'Control',
  fechaHora: DateTime(2026, 10, 2, 10),
  creadoEn: DateTime(2026, 10, 1),
);

void main() {
  late FakeFirebaseFirestore firestore;
  late ColaEscrituras cola;
  late ConectividadFalsa red;
  late ServicioCifrado cifrado;
  late BaseDatosSegura base;
  late RepositorioRegistrosClinicos registros;

  void armar({required bool enLinea, required bool claveGuardada}) {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({
      if (claveGuardada) 'oncuidar.data-key.$_uid': _clavePrueba,
    });
    firestore = FakeFirebaseFirestore();
    cola = ColaEscrituras();
    red = ConectividadFalsa(enLinea: enLinea);
    cifrado = ServicioCifrado();
    base = BaseDatosSegura(
      base: firestore,
      uidPrueba: _uid,
      cifrado: cifrado,
      cola: cola,
      conectividad: red,
    );
    registros = RepositorioRegistrosClinicos(base);
  }

  Future<void> afirmarNadaEscrito() async {
    expect(await cola.pendientes(_uid), isEmpty);
    final pacientes = await firestore
        .collection('usuarios')
        .doc(_uid)
        .collection('pacientes')
        .doc('pacienteA')
        .collection('recordatorios')
        .get();
    expect(pacientes.docs, isEmpty);
  }

  group('Sin red y sin clave guardada en el dispositivo', () {
    setUp(() => armar(enLinea: false, claveGuardada: false));

    test(
      'un registro clínico falla con un error explícito y no se encola',
      () async {
        await expectLater(
          registros.guardarRegistroClinico('pacienteA', _registro()),
          throwsA(isA<ClaveNoDisponibleSinConexion>()),
        );
        await afirmarNadaEscrito();
      },
    );

    test(
      'un recordatorio falla con un error explícito y no se encola',
      () async {
        await expectLater(
          RepositorioRecordatorios(
            base,
          ).agregarRecordatorio('pacienteA', _recordatorio()),
          throwsA(isA<ClaveNoDisponibleSinConexion>()),
        );
        await afirmarNadaEscrito();
      },
    );

    test('el mensaje para la persona está en español y es claro', () {
      const mensaje = ClaveNoDisponibleSinConexion.mensaje;
      expect(mensaje, contains('Sin conexión'));
      expect(mensaje, contains('clave de cifrado'));
      expect(const ClaveNoDisponibleSinConexion().toString(), mensaje);
    });

    test(
      'verificarEscrituraDisponible permite avisar antes de guardar',
      () async {
        await expectLater(
          base.verificarEscrituraDisponible(),
          throwsA(isA<ClaveNoDisponibleSinConexion>()),
        );
      },
    );
  });

  group('Sin red pero con la clave guardada en el dispositivo', () {
    setUp(() => armar(enLinea: false, claveGuardada: true));

    test('restaura la clave sin red y encola el registro cifrado', () async {
      expect(cifrado.tieneClave(_uid), isFalse);
      await registros.guardarRegistroClinico('pacienteA', _registro());

      expect(cifrado.tieneClave(_uid), isTrue);
      final pendiente = (await cola.pendientes(_uid)).single;
      expect(pendiente.datos['paciente_id'], 'pacienteA');
      expect(pendiente.datos.toString(), isNot(contains('Reservado')));
      expect(pendiente.datos['contenido_registro_cifrado'], isNotNull);
    });

    test('también encola recordatorios', () async {
      await RepositorioRecordatorios(
        base,
      ).agregarRecordatorio('pacienteA', _recordatorio());
      expect(await cola.pendientes(_uid), hasLength(1));
    });
  });

  group('Con conexión y sin clave', () {
    setUp(() => armar(enLinea: true, claveGuardada: false));

    test(
      'conserva el comportamiento previo: error de clave no cargada',
      () async {
        await expectLater(
          RepositorioRecordatorios(
            base,
          ).agregarRecordatorio('pacienteA', _recordatorio()),
          throwsA(isA<StateError>()),
        );
        expect(await cola.pendientes(_uid), isEmpty);
      },
    );
  });
}
