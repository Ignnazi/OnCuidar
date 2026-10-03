import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/registro_clinico.dart';
import 'package:oncuidar/core/proveedores/proveedores.dart';
import 'package:oncuidar/core/servicios/cola_escrituras.dart';
import 'package:oncuidar/core/servicios/orquestador_sincronizacion.dart';
import 'package:oncuidar/core/servicios/servicio_base_datos.dart';
import 'package:oncuidar/core/servicios/servicio_cifrado.dart';
import 'package:oncuidar/modelos/paciente.dart';
import 'package:oncuidar/modelos/registro_clinico.dart';
import 'package:oncuidar/modelos/recordatorio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ayudas_offline.dart';

const _clavePrueba = 'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';
const _uid = 'uid-integridad';

class _BaseRegistro extends ServicioBaseDatos {
  _BaseRegistro({
    required super.base,
    required super.cifrado,
    this.fallo,
    this.retardo,
  }) : super(uidPrueba: _uid);

  final Object? fallo;
  final Duration? retardo;
  int llamadas = 0;

  @override
  Future<void> guardarRegistroClinico(
    String idPaciente,
    RegistroClinico registro,
  ) async {
    llamadas++;
    if (retardo != null) await Future<void>.delayed(retardo!);
    final error = fallo;
    if (error != null) throw error;
    await super.guardarRegistroClinico(idPaciente, registro);
  }
}

class _BaseDrenaje extends ServicioBaseDatos {
  _BaseDrenaje({
    required super.base,
    required super.cifrado,
    required super.cola,
    required super.conectividad,
  }) : super(uidPrueba: _uid);

  Object? Function(EscrituraPendiente escritura)? falla;
  bool cambioDeSesion = false;
  int aplicadas = 0;

  @override
  Future<void> aplicarEscrituraPendiente(EscrituraPendiente escritura) async {
    aplicadas++;
    final error = falla?.call(escritura);
    if (error != null) throw error;
    await super.aplicarEscrituraPendiente(escritura);
    cambioDeSesion = true;
  }
}

class _Entorno {
  _Entorno({
    required this.firestore,
    required this.cola,
    required this.red,
    required this.base,
    required this.cifrado,
    required this.orquestador,
  });

  final FakeFirebaseFirestore firestore;
  final ColaEscrituras cola;
  final ConectividadFalsa red;
  final _BaseDrenaje base;
  final ServicioCifrado cifrado;
  final OrquestadorSincronizacion orquestador;

  CollectionReference<Map<String, dynamic>> coleccion(
    String paciente,
    String nombre,
  ) => firestore
      .collection('users')
      .doc(_uid)
      .collection('patients')
      .doc(paciente)
      .collection(nombre);
}

Future<_Entorno> _crearEntorno({
  bool enLinea = true,
  Duration retardoBase = const Duration(milliseconds: 1),
  int maxIntentos = 8,
}) async {
  final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
  await cifrado.fijarClave(_uid, _clavePrueba);
  final firestore = FakeFirebaseFirestore();
  final cola = ColaEscrituras();
  final red = ConectividadFalsa(enLinea: enLinea);
  final base = _BaseDrenaje(
    base: firestore,
    cifrado: cifrado,
    cola: cola,
    conectividad: red,
  );
  final orquestador = OrquestadorSincronizacion(
    cola: cola,
    base: base,
    conectividad: red,
    uidActual: () => _uid,
    retardoBase: retardoBase,
    maxIntentosPorEscritura: maxIntentos,
  );
  addTearDown(orquestador.dispose);
  return _Entorno(
    firestore: firestore,
    cola: cola,
    red: red,
    base: base,
    cifrado: cifrado,
    orquestador: orquestador,
  );
}

EscrituraPendiente _escritura(String id) =>
    escrituraDe(id: id, ruta: 'users/$_uid/patients/p1/recordatorios/c1');

Future<Map<String, dynamic>> _payloadDe(
  _Entorno ent,
  DocumentSnapshot<Map<String, dynamic>> doc,
) async {
  final texto = await ent.cifrado.descifrar(
    _uid,
    doc.data()!['datos_cifrados'] as String,
  );
  return jsonDecode(texto) as Map<String, dynamic>;
}

Widget _pantallaRegistro(ServicioCifrado cifrado, ServicioBaseDatos base) {
  final router = GoRouter(
    initialLocation: '/registro-clinico',
    routes: [
      GoRoute(
        path: '/registro-clinico',
        builder: (c, s) => const RegistroClinicoScreen(),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      firebaseAuthProvider.overrideWithValue(
        MockFirebaseAuth(
          mockUser: MockUser(uid: _uid, email: 'cuidador@test.cl'),
        ),
      ),
      servicioCifradoProvider.overrideWithValue(cifrado),
      servicioBaseDatosProvider.overrideWith((_) => base),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<String> _prepararRegistro(
  WidgetTester tester,
  ServicioCifrado cifrado,
  _BaseRegistro base,
) async {
  await base.crearCuidador({
    'displayName': 'Ana Torres',
    'email': 'cuidador@test.cl',
    'phone': '+56 9 1111 1111',
    'relationship': 'Madre',
    'address': 'Av. Siempre Viva 742',
  });
  final idPaciente = await base.crearPaciente(
    Paciente(
      id: 'ignorado',
      fullName: 'Paciente Test',
      createdAt: DateTime(2026, 10, 1),
    ),
  );
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_pantallaRegistro(cifrado, base));
  await tester.pumpAndSettle();
  return idPaciente;
}

Future<void> _tocarGuardar(WidgetTester tester) async {
  final boton = find.text('Guardar registro');
  await tester.ensureVisible(boton);
  await tester.pumpAndSettle();
  await tester.tap(boton);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Registro clínico sin pérdida al fallar la escritura', () {
    testWidgets('si la escritura falla el formulario conserva lo escrito', (
      tester,
    ) async {
      final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
      await cifrado.fijarClave(_uid, _clavePrueba);
      final firestore = FakeFirebaseFirestore();
      final base = _BaseRegistro(
        base: firestore,
        cifrado: cifrado,
        fallo: StateError('Clave de datos no disponible.'),
      );
      await _prepararRegistro(tester, cifrado, base);

      await tester.enterText(find.byType(TextField).at(0), '40.0');
      await tester.enterText(find.byType(TextField).at(4), 'fiebre alta');
      await tester.pumpAndSettle();
      await _tocarGuardar(tester);

      expect(
        find.text('No se pudo guardar. Tu registro sigue en el formulario.'),
        findsOneWidget,
      );
      final observaciones = tester
          .widget<TextField>(find.byType(TextField).at(4))
          .controller;
      expect(
        observaciones?.text,
        'fiebre alta',
        reason: 'el texto escrito no puede perderse si la escritura falla',
      );
      final temperatura = tester
          .widget<TextField>(find.byType(TextField).at(0))
          .controller;
      expect(temperatura?.text, '40.0');
    });

    testWidgets('un doble toque no crea dos registros clínicos', (
      tester,
    ) async {
      final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
      await cifrado.fijarClave(_uid, _clavePrueba);
      final firestore = FakeFirebaseFirestore();
      final base = _BaseRegistro(
        base: firestore,
        cifrado: cifrado,
        retardo: const Duration(milliseconds: 50),
      );
      await _prepararRegistro(tester, cifrado, base);
      final idPaciente =
          (await firestore
                  .collection('users')
                  .doc(_uid)
                  .collection('patients')
                  .get())
              .docs
              .single
              .id;

      final boton = find.text('Guardar registro');
      await tester.ensureVisible(boton);
      await tester.pumpAndSettle();
      await tester.tap(boton);
      await tester.pump();
      expect(
        find.text('Guardando…'),
        findsOneWidget,
        reason: 'el botón debe pasar a estado de carga, no aceptar otro toque',
      );
      await tester.tap(find.text('Guardando…'));
      await tester.pumpAndSettle();

      expect(
        base.llamadas,
        1,
        reason: 'el segundo toque debe ignorarse mientras se guarda',
      );
      final registros = await firestore
          .collection('users')
          .doc(_uid)
          .collection('patients')
          .doc(idPaciente)
          .collection('clinicalRecords')
          .get();
      expect(registros.docs, hasLength(1));
    });
  });

  group('El payload de un recordatorio encolado no se pierde', () {
    test('editarlo sin red conserva tipo y días de repetición', () async {
      final ent = await _crearEntorno(enLinea: false);
      final id = await ent.base.agregarRecordatorio(
        'p1',
        Recordatorio(
          id: 'r1',
          pacienteId: 'p1',
          tipo: 'medicamento',
          titulo: 'Paracetamol',
          fechaHora: DateTime(2026, 10, 1, 8),
          diasRepeticion: const ['lun', 'mar'],
          creadoEn: DateTime(2026, 10, 1),
        ),
      );

      final antesDeDrenar = await ent
          .coleccion('p1', 'recordatorios')
          .doc(id)
          .get();
      expect(
        antesDeDrenar.exists,
        isTrue,
        reason: 'sin red el recordatorio se ve de inmediato y además queda en la cola',
      );

      await ent.base.actualizarRecordatorio(
        'p1',
        id,
        fechaHora: DateTime(2026, 10, 1, 10),
      );

      ent.red.fijar(true);
      await ent.orquestador.drenar();

      final doc = await ent.coleccion('p1', 'recordatorios').doc(id).get();
      final payload = await _payloadDe(ent, doc);
      expect(
        payload['tipo'],
        'medicamento',
        reason: 'editar la hora no puede borrar el tipo del recordatorio',
      );
      expect(payload['diasRepeticion'], ['lun', 'mar']);
      expect(payload['fechaHora'], DateTime(2026, 10, 1, 10).toIso8601String());
    });

    test(
      'un payload ilegible aborta la actualización en vez de borrarlo',
      () async {
        final ent = await _crearEntorno(enLinea: true);
        final ref = ent.coleccion('p1', 'recordatorios').doc('r1');
        await ref.set({
          'pacienteId': 'p1',
          'activo': true,
          'version_encriptacion': 3,
          'datos_cifrados': 'no-es-un-valor-cifrado-valido',
        });

        await expectLater(
          ent.base.actualizarRecordatorio(
            'p1',
            'r1',
            titulo: 'Nuevo título',
            fechaHora: DateTime(2026, 10, 2, 9),
          ),
          throwsA(isA<FormatException>()),
        );

        final doc = await ref.get();
        expect(
          doc.data()!['datos_cifrados'],
          'no-es-un-valor-cifrado-valido',
          reason: 'un descifrado fallido no puede sobrescribir el payload',
        );
      },
    );
  });

  group('La cola nunca se congela ni traga escrituras', () {
    test('tras agotar los intentos la escritura sí llega a fallidas', () async {
      final ent = await _crearEntorno(enLinea: true, maxIntentos: 8);
      ent.base.falla = (_) =>
          FirebaseException(plugin: 'p', code: 'unavailable');
      await ent.cola.encolar(_uid, _escritura('e1'));

      await ent.orquestador.drenar();
      await esperarHasta(
        () async => (await ent.cola.fallidas(_uid)).isNotEmpty,
      );

      expect((await ent.cola.fallidas(_uid)).single.id, 'e1');
      expect(await ent.cola.pendientes(_uid), isEmpty);
    });

    test('unauthenticated se reintenta en vez de caer en fallidas', () async {
      final ent = await _crearEntorno(enLinea: true);
      ent.base.falla = (_) =>
          FirebaseException(plugin: 'p', code: 'unauthenticated');
      await ent.cola.encolar(_uid, _escritura('e1'));

      await ent.orquestador.drenar();

      expect(
        await ent.cola.fallidas(_uid),
        isEmpty,
        reason: 'un fallo de token es transitorio, no una escritura perdida',
      );
      final pendiente = (await ent.cola.pendientes(_uid)).single;
      expect(pendiente.id, 'e1');
      expect(pendiente.intentos, 1);
    });

    test(
      'si cambia la sesión a mitad el drenaje corta sin tirar fallidas',
      () async {
        final ent = await _crearEntorno(enLinea: true);
        String uidActual() => ent.base.cambioDeSesion ? 'otro-uid' : _uid;
        final orquestador = OrquestadorSincronizacion(
          cola: ent.cola,
          base: ent.base,
          conectividad: ent.red,
          uidActual: uidActual,
          retardoBase: const Duration(milliseconds: 1),
        );
        addTearDown(orquestador.dispose);
        await ent.cola.encolar(_uid, _escritura('e1'));
        await ent.cola.encolar(_uid, _escritura('e2'));

        await orquestador.drenar();

        expect(
          (await ent.cola.pendientes(_uid)).single.id,
          'e2',
          reason: 'la escritura del cuidador anterior no debe perderse',
        );
        expect(await ent.cola.fallidas(_uid), isEmpty);
      },
    );
  });

  group('Recuperación de la cola', () {
    test(
      'reintentarFallidas devuelve las escrituras con los intentos en cero',
      () async {
        final cola = ColaEscrituras();
        await cola.encolar(_uid, escrituraDe(id: 'e1'));
        await cola.registrarIntento(_uid, 'e1');
        await cola.moverAFallidas(_uid, 'e1');
        expect((await cola.fallidas(_uid)).single.intentos, 1);

        await cola.reintentarFallidas(_uid);

        expect(await cola.fallidas(_uid), isEmpty);
        expect((await cola.pendientes(_uid)).single.intentos, 0);
      },
    );

    test('una cola corrupta no impide seguir operando', () async {
      SharedPreferences.setMockInitialValues({
        'oncuidar.cola_escrituras.$_uid': '{esto no es json',
      });
      final cola = ColaEscrituras();

      expect(await cola.pendientes(_uid), isEmpty);
      await cola.encolar(_uid, escrituraDe(id: 'e1'));
      expect((await cola.pendientes(_uid)).single.id, 'e1');
    });
  });

  group('Los borrados también se encolan sin red', () {
    test('sin red el borrado se ve de inmediato y llega al servidor', () async {
      final ent = await _crearEntorno(enLinea: true);
      final id = await ent.base.agregarRecordatorio(
        'p1',
        Recordatorio(
          id: 'r1',
          pacienteId: 'p1',
          tipo: 'medicamento',
          titulo: 'Paracetamol',
          fechaHora: DateTime(2026, 10, 1, 8),
          creadoEn: DateTime(2026, 10, 1),
        ),
      );
      expect(
        (await ent.coleccion('p1', 'recordatorios').doc(id).get()).exists,
        isTrue,
      );

      ent.red.fijar(false);
      await ent.base.eliminarRecordatorio('p1', id);

      expect(
        (await ent.coleccion('p1', 'recordatorios').doc(id).get()).exists,
        isFalse,
        reason: 'sin red el borrado se refleja al instante y queda en la cola',
      );
      final encolada = (await ent.cola.pendientes(_uid)).single;
      expect(encolada.operacion, OperacionPendiente.borrar);
      expect(encolada.ruta, endsWith('/recordatorios/$id'));

      ent.red.fijar(true);
      await ent.orquestador.drenar();

      expect(
        (await ent.coleccion('p1', 'recordatorios').doc(id).get()).exists,
        isFalse,
      );
      expect(await ent.cola.pendientes(_uid), isEmpty);
    });

    test(
      'sin red el borrado de un registro clínico llega al servidor',
      () async {
        final ent = await _crearEntorno(enLinea: true);
        await ent.base.guardarRegistroClinico(
          'p1',
          RegistroClinico(
            id: 'rc1',
            pacienteId: 'p1',
            tipoRegistro: 'diario',
            fecha: DateTime(2026, 10, 1, 9),
            creadoEn: DateTime(2026, 10, 1, 9),
          ),
        );

        ent.red.fijar(false);
        await ent.base.eliminarRegistroClinico('p1', 'rc1');

        expect(
          (await ent.cola.pendientes(_uid)).single.operacion,
          OperacionPendiente.borrar,
        );

        ent.red.fijar(true);
        await ent.orquestador.drenar();

        final docs = await ent.coleccion('p1', 'clinicalRecords').get();
        expect(docs.docs, isEmpty);
      },
    );

    test('crear y luego borrar sin red deja el documento ausente', () async {
      final ent = await _crearEntorno(enLinea: false);
      final id = await ent.base.agregarRecordatorio(
        'p1',
        Recordatorio(
          id: 'r1',
          pacienteId: 'p1',
          tipo: 'cita',
          titulo: 'Control',
          fechaHora: DateTime(2026, 11, 3, 11),
          creadoEn: DateTime(2026, 10, 1),
        ),
      );
      await ent.base.eliminarRecordatorio('p1', id);

      final encoladas = await ent.cola.pendientes(_uid);
      expect(encoladas, hasLength(2));
      expect(
        encoladas.map((e) => e.operacion),
        [OperacionPendiente.crear, OperacionPendiente.borrar],
        reason: 'el orden de la cola es lo que hace que el borrado gane',
      );

      ent.red.fijar(true);
      await ent.orquestador.drenar();

      expect(
        (await ent.coleccion('p1', 'recordatorios').doc(id).get()).exists,
        isFalse,
      );
    });

    test(
      'con red el borrado se aplica directo, sin pasar por la cola',
      () async {
        final ent = await _crearEntorno(enLinea: true);
        final id = await ent.base.agregarRecordatorio(
          'p1',
          Recordatorio(
            id: 'r1',
            pacienteId: 'p1',
            tipo: 'medicion',
            titulo: 'Presión',
            fechaHora: DateTime(2026, 10, 5, 7),
            creadoEn: DateTime(2026, 10, 1),
          ),
        );

        await ent.base.eliminarRecordatorio('p1', id);

        expect(await ent.cola.pendientes(_uid), isEmpty);
        expect(
          (await ent.coleccion('p1', 'recordatorios').doc(id).get()).exists,
          isFalse,
        );
      },
    );
  });

  group('El binding de paciente viaja en cada escritura', () {
    test('actualizar un recordatorio lo sigue declarando', () async {
      final ent = await _crearEntorno(enLinea: true);
      final id = await ent.base.agregarRecordatorio(
        'p1',
        Recordatorio(
          id: 'r1',
          pacienteId: 'p1',
          tipo: 'medicamento',
          titulo: 'Paracetamol',
          fechaHora: DateTime(2026, 10, 1, 8),
          creadoEn: DateTime(2026, 10, 1),
        ),
      );

      await ent.base.actualizarRecordatorio('p1', id, activo: false);

      final doc = await ent.coleccion('p1', 'recordatorios').doc(id).get();
      expect(doc.data()!['pacienteId'], 'p1');
    });
  });
}
