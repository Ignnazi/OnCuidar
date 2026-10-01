import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/core/servicios/cola_escrituras.dart';
import 'package:oncuidar/core/servicios/servicio_base_datos.dart';
import 'package:oncuidar/core/servicios/servicio_cifrado.dart';
import 'package:oncuidar/modelos/recordatorio.dart';
import 'package:oncuidar/modelos/registro_clinico.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ayudas_offline.dart';

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
  late ServicioBaseDatos base;

  void armar({required bool enLinea, required bool claveGuardada}) {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({
      if (claveGuardada) 'oncuidar.data-key.$_uid': _clavePrueba,
    });
    firestore = FakeFirebaseFirestore();
    cola = ColaEscrituras();
    red = ConectividadFalsa(enLinea: enLinea);
    cifrado = ServicioCifrado();
    base = ServicioBaseDatos(
      base: firestore,
      uidPrueba: _uid,
      cifrado: cifrado,
      cola: cola,
      conectividad: red,
    );
  }

  Future<void> afirmarNadaEscrito() async {
    expect(await cola.pendientes(_uid), isEmpty);
    final pacientes = await firestore
        .collection('users')
        .doc(_uid)
        .collection('patients')
        .doc('pacienteA')
        .collection('userChecklists')
        .get();
    expect(pacientes.docs, isEmpty);
  }

  group('Sin red y sin clave guardada en el dispositivo', () {
    setUp(() => armar(enLinea: false, claveGuardada: false));

    test(
      'un registro clínico falla con un error explícito y no se encola',
      () async {
        await expectLater(
          base.guardarRegistroClinico('pacienteA', _registro()),
          throwsA(isA<ClaveNoDisponibleSinConexion>()),
        );
        await afirmarNadaEscrito();
      },
    );

    test('un checklist falla con un error explícito y no se encola', () async {
      await expectLater(
        base.crearListaChecklist('pacienteA', titulo: 'Rutina', items: ['x']),
        throwsA(isA<ClaveNoDisponibleSinConexion>()),
      );
      await afirmarNadaEscrito();
    });

    test(
      'un recordatorio falla con un error explícito y no se encola',
      () async {
        await expectLater(
          base.agregarRecordatorio('pacienteA', _recordatorio()),
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
      await base.guardarRegistroClinico('pacienteA', _registro());

      expect(cifrado.tieneClave(_uid), isTrue);
      final pendiente = (await cola.pendientes(_uid)).single;
      expect(pendiente.datos['paciente_id'], 'pacienteA');
      expect(pendiente.datos.toString(), isNot(contains('Reservado')));
      expect(pendiente.datos['contenido_registro_cifrado'], isNotNull);
    });

    test('también encola checklists y recordatorios', () async {
      await base.crearListaChecklist(
        'pacienteA',
        titulo: 'Rutina',
        items: ['x'],
      );
      await base.agregarRecordatorio('pacienteA', _recordatorio());
      expect(await cola.pendientes(_uid), hasLength(2));
    });
  });

  group('Con conexión y sin clave', () {
    setUp(() => armar(enLinea: true, claveGuardada: false));

    test(
      'conserva el comportamiento previo: error de clave no cargada',
      () async {
        await expectLater(
          base.crearListaChecklist('pacienteA', titulo: 'Rutina', items: ['x']),
          throwsA(isA<StateError>()),
        );
        expect(await cola.pendientes(_uid), isEmpty);
      },
    );
  });
}
