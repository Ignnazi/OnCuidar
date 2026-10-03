import 'dart:convert';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oncuidar/caracteristicas/recordatorios/recordatorios.dart';
import 'package:oncuidar/core/proveedores/proveedores.dart';
import 'package:oncuidar/core/servicios/servicio_base_datos.dart';
import 'package:oncuidar/core/servicios/servicio_cifrado.dart';
import 'package:oncuidar/core/servicios/servicio_notificaciones.dart';
import 'package:oncuidar/modelos/paciente.dart';
import 'package:oncuidar/modelos/recordatorio.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _clavePrueba = 'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';
const _uid = 'uid27';

class _FakeNotificaciones implements ServicioNotificaciones {
  int permisoSolicitado = 0;
  int canceladasTodas = 0;
  final programados = <Map<String, dynamic>>[];
  final cancelados = <int>[];

  @override
  Future<void> inicializar() async {}

  @override
  Future<bool> solicitarPermiso() async {
    permisoSolicitado++;
    return true;
  }

  @override
  Future<void> programar({
    required int id,
    required String titulo,
    required String cuerpo,
    required DateTime fechaHora,
    List<String>? diasRepeticion,
    bool mensual = false,
  }) async {
    programados.add({
      'id': id,
      'titulo': titulo,
      'cuerpo': cuerpo,
      'fechaHora': fechaHora,
      'dias': List<String>.from(diasRepeticion ?? const []),
      'mensual': mensual,
    });
  }

  @override
  Future<void> cancelar(int id) async => cancelados.add(id);

  @override
  Future<void> cancelarTodas() async => canceladasTodas++;

  @override
  void Function(String? payload)? alTocar;

  @override
  Future<String?> consumirPayloadLanzamiento() async => null;
}

Future<(ServicioBaseDatos, FakeFirebaseFirestore)> _baseDatos() async {
  final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
  await cifrado.fijarClave(_uid, _clavePrueba);
  final firestore = FakeFirebaseFirestore();
  final base = ServicioBaseDatos(
    base: firestore,
    uidPrueba: _uid,
    cifrado: cifrado,
  );
  await base.crearCuidador({
    'displayName': 'Ana Torres',
    'email': 'ana@correo.cl',
    'phone': '+56 9 1111 1111',
    'relationship': 'Madre',
    'address': 'Av. Siempre Viva 742',
  });
  return (base, firestore);
}

Future<String> _sembrarPaciente(ServicioBaseDatos base) async {
  return base.crearPaciente(
    Paciente(id: 'auto', fullName: 'Paciente Test', createdAt: DateTime.now()),
  );
}

Widget _pantalla(ServicioBaseDatos base, _FakeNotificaciones notif) {
  final router = GoRouter(
    initialLocation: '/recordatorios',
    routes: [
      GoRoute(
        path: '/recordatorios',
        builder: (c, s) => const RecordatoriosScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (c, s) =>
            const Scaffold(body: Center(child: Text('Dashboard stub'))),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      servicioBaseDatosProvider.overrideWith((_) => base),
      servicioNotificacionesProvider.overrideWithValue(notif),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _montar(WidgetTester tester, Widget pantalla) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(pantalla);
  await tester.pumpAndSettle();
}

Future<Map<String, dynamic>?> _doc(
  FakeFirebaseFirestore firestore,
  String idPaciente,
  String idRecordatorio,
) async {
  return (await firestore
          .collection('users')
          .doc(_uid)
          .collection('patients')
          .doc(idPaciente)
          .collection('recordatorios')
          .doc(idRecordatorio)
          .get())
      .data();
}

Future<Map<String, dynamic>> _payloadRecordatorio(
  FakeFirebaseFirestore firestore,
  String idPaciente,
  String idRecordatorio,
) async {
  final datos = await _doc(firestore, idPaciente, idRecordatorio);
  final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
  await cifrado.fijarClave(_uid, _clavePrueba);
  final texto = await cifrado.descifrar(
    _uid,
    datos!['datos_cifrados'] as String,
  );
  return (jsonDecode(texto) as Map<String, dynamic>).cast<String, dynamic>();
}

void main() {
  group('ServicioBaseDatos — Recordatorios', () {
    test('agregarRecordatorio cifra título y descripción', () async {
      final (base, firestore) = await _baseDatos();
      final idPaciente = await _sembrarPaciente(base);
      final fecha = DateTime.now();
      final id = await base.agregarRecordatorio(
        idPaciente,
        Recordatorio(
          id: '',
          pacienteId: idPaciente,
          tipo: 'medicamento',
          titulo: 'Dar paracetamol',
          descripcion: '500 mg con agua',
          fechaHora: fecha,
          diasRepeticion: const ['lun', 'mie'],
          activo: true,
          creadoEn: fecha,
        ),
      );
      final datos = await _doc(firestore, idPaciente, id);
      expect(datos, isNotNull);
      expect(datos!.containsKey('titulo'), isFalse);
      expect(datos.containsKey('descripcion'), isFalse);
      expect(datos['titulo_cifrado'], isA<String>());
      expect(datos['titulo_cifrado'], isNot('Dar paracetamol'));
      expect(datos['descripcion_cifrada'], isA<String>());
      expect(datos.containsKey('tipo'), isFalse);
      expect(datos.containsKey('fechaHora'), isFalse);
      expect(datos.containsKey('diasRepeticion'), isFalse);
      expect(datos['version_encriptacion'], 3);
      final payload = await _payloadRecordatorio(firestore, idPaciente, id);
      expect(payload['tipo'], 'medicamento');
      expect(payload['diasRepeticion'], ['lun', 'mie']);
    });

    test('el stream devuelve los recordatorios descifrados', () async {
      final (base, _) = await _baseDatos();
      final idPaciente = await _sembrarPaciente(base);
      final fecha = DateTime.now();
      await base.agregarRecordatorio(
        idPaciente,
        Recordatorio(
          id: '',
          pacienteId: idPaciente,
          tipo: 'cita',
          titulo: 'Control médico',
          fechaHora: fecha,
          activo: true,
          creadoEn: fecha,
        ),
      );
      final recordatorios = await base
          .recordatoriosEnTiempoReal(idPaciente)
          .first;
      expect(recordatorios, hasLength(1));
      expect(recordatorios.first.titulo, 'Control médico');
      expect(recordatorios.first.tipo, 'cita');
    });

    test('la recurrencia mensual se persiste y se descifra', () async {
      final (base, firestore) = await _baseDatos();
      final idPaciente = await _sembrarPaciente(base);
      final fecha = DateTime.now();
      final id = await base.agregarRecordatorio(
        idPaciente,
        Recordatorio(
          id: '',
          pacienteId: idPaciente,
          tipo: 'medicamento',
          titulo: 'Vitamina mensual',
          fechaHora: fecha,
          activo: true,
          creadoEn: fecha,
          recurrencia: 'mensual',
        ),
      );
      final datos = await _doc(firestore, idPaciente, id);
      final payload = await _payloadRecordatorio(firestore, idPaciente, id);
      expect(payload['recurrencia'], 'mensual');
      expect(datos!.containsKey('completadoEn'), isFalse);

      var recordatorios = await base
          .recordatoriosEnTiempoReal(idPaciente)
          .first;
      expect(recordatorios.single.esMensual, isTrue);

      await base.actualizarRecordatorio(idPaciente, id, recurrencia: '');
      recordatorios = await base.recordatoriosEnTiempoReal(idPaciente).first;
      expect(recordatorios.single.recurrencia, isNull);
    });

    test(
      'reagendarNotificaciones cancela todo y reprograma solo activos',
      () async {
        final (base, _) = await _baseDatos();
        final idPaciente = await _sembrarPaciente(base);
        final fecha = DateTime(2026, 9, 21, 9, 0);
        await base.agregarRecordatorio(
          idPaciente,
          Recordatorio(
            id: '',
            pacienteId: idPaciente,
            tipo: 'medicamento',
            titulo: 'Diario',
            fechaHora: fecha,
            diasRepeticion: const ['lun', 'mie'],
            activo: true,
            creadoEn: fecha,
          ),
        );
        await base.agregarRecordatorio(
          idPaciente,
          Recordatorio(
            id: '',
            pacienteId: idPaciente,
            tipo: 'cita',
            titulo: 'Control del mes',
            fechaHora: fecha,
            activo: true,
            creadoEn: fecha,
            recurrencia: 'mensual',
          ),
        );
        await base.agregarRecordatorio(
          idPaciente,
          Recordatorio(
            id: '',
            pacienteId: idPaciente,
            tipo: 'otro',
            titulo: 'Apagado',
            fechaHora: fecha,
            activo: false,
            creadoEn: fecha,
          ),
        );
        final notif = _FakeNotificaciones();
        await base.reagendarNotificaciones(notif);

        expect(notif.canceladasTodas, 1);
        expect(notif.programados, hasLength(2));
        expect(notif.programados.map((p) => p['mensual']).toSet(), {
          false,
          true,
        });
        expect(notif.programados.map((p) => p['titulo']).toSet(), {
          'Paciente Test · Medicamento',
          'Paciente Test · Cita médica',
        });
      },
    );
  });

  group('Pantalla de recordatorios', () {
    testWidgets('muestra estado vacío y los 4 accesos rápidos', (tester) async {
      final (base, _) = await _baseDatos();
      final notif = _FakeNotificaciones();
      await _montar(tester, _pantalla(base, notif));

      expect(find.text('No tienes recordatorios.'), findsOneWidget);
      expect(
        find.text('Usa las tarjetas de arriba para crear uno.'),
        findsOneWidget,
      );
      for (final etiqueta in ['Medicamento', 'Medición', 'Cita médica']) {
        expect(find.text(etiqueta), findsOneWidget);
      }
      expect(find.byKey(const Key('tarjetaRapida_otro')), findsOneWidget);
    });

    testWidgets(
      'crear recordatorio guarda cifrado y programa la notificación',
      (tester) async {
        final (base, firestore) = await _baseDatos();
        final idPaciente = await _sembrarPaciente(base);
        final notif = _FakeNotificaciones();
        await _montar(tester, _pantalla(base, notif));

        await tester.tap(find.byKey(const Key('tarjetaRapida_medicamento')));
        await tester.pumpAndSettle();
        expect(find.text('Nuevo recordatorio'), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('campoTituloRecordatorio')),
          'Dar paracetamol al niño',
        );
        await tester.tap(find.byKey(const Key('confirmarRecordatorio')));
        await tester.pumpAndSettle();

        expect(find.text('Dar paracetamol al niño'), findsOneWidget);
        expect(notif.permisoSolicitado, 1);
        expect(notif.programados, isNotEmpty);
        expect(
          notif.programados.single['titulo'],
          'Paciente Test · Medicamento',
        );
        expect(notif.cancelados, isEmpty);

        final docs = await firestore
            .collection('users')
            .doc(_uid)
            .collection('patients')
            .doc(idPaciente)
            .collection('recordatorios')
            .get();
        expect(docs.docs, hasLength(1));
        final datos = docs.docs.first.data();
        expect(datos.containsKey('titulo'), isFalse);
        expect(datos['titulo_cifrado'], isNot('Dar paracetamol al niño'));
      },
    );

    testWidgets('modo mensual persiste recurrencia y programa con mensual', (
      tester,
    ) async {
      final (base, firestore) = await _baseDatos();
      final idPaciente = await _sembrarPaciente(base);
      final notif = _FakeNotificaciones();
      await _montar(tester, _pantalla(base, notif));

      await tester.tap(find.byKey(const Key('tarjetaRapida_medicamento')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('modoRepeticion_mensual')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('campoTituloRecordatorio')),
        'Cita mensual',
      );
      await tester.tap(find.byKey(const Key('confirmarRecordatorio')));
      await tester.pumpAndSettle();

      final docs = await firestore
          .collection('users')
          .doc(_uid)
          .collection('patients')
          .doc(idPaciente)
          .collection('recordatorios')
          .get();
      final datos = docs.docs.single.data();
      expect(datos.containsKey('recurrencia'), isFalse);
      expect(datos.containsKey('diasRepeticion'), isFalse);
      final payload = await _payloadRecordatorio(
        firestore,
        idPaciente,
        docs.docs.single.id,
      );
      expect(payload['recurrencia'], 'mensual');
      expect(payload['diasRepeticion'], isEmpty);
      expect(notif.programados.single['mensual'], isTrue);
      expect(notif.programados.single['dias'], isEmpty);
    });

    testWidgets('la tarjeta muestra el paciente del recordatorio', (
      tester,
    ) async {
      final (base, firestore) = await _baseDatos();
      final idPaciente = await _sembrarPaciente(base);
      final notif = _FakeNotificaciones();
      final fecha = DateTime.now();
      await base.agregarRecordatorio(
        idPaciente,
        Recordatorio(
          id: '',
          pacienteId: idPaciente,
          tipo: 'medicamento',
          titulo: 'Tomar jarabe',
          fechaHora: fecha,
          activo: true,
          creadoEn: fecha,
        ),
      );
      await _montar(tester, _pantalla(base, notif));

      expect(find.text('Paciente Test'), findsOneWidget);
    });

    testWidgets('el menú de 3 puntos edita y elimina', (tester) async {
      final (base, firestore) = await _baseDatos();
      final idPaciente = await _sembrarPaciente(base);
      final notif = _FakeNotificaciones();
      final fecha = DateTime.now();
      final id = await base.agregarRecordatorio(
        idPaciente,
        Recordatorio(
          id: '',
          pacienteId: idPaciente,
          tipo: 'cita',
          titulo: 'Control con especialista',
          fechaHora: fecha,
          activo: true,
          creadoEn: fecha,
        ),
      );
      await _montar(tester, _pantalla(base, notif));

      await tester.tap(find.byKey(Key('menuRecordatorio_$id')));
      await tester.pumpAndSettle();

      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Eliminar'), findsOneWidget);

      await tester.tap(find.byKey(Key('accionEditar_$id')));
      await tester.pumpAndSettle();

      expect(find.text('Editar recordatorio'), findsOneWidget);
      await tester.tap(find.byKey(const Key('cancelarRecordatorio')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key('menuRecordatorio_$id')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('accionEliminar_$id')));
      await tester.pumpAndSettle();

      expect(find.text('¿Eliminar este recordatorio?'), findsOneWidget);
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      final docs = await firestore
          .collection('users')
          .doc(_uid)
          .collection('patients')
          .doc(idPaciente)
          .collection('recordatorios')
          .get();
      expect(docs.docs, isEmpty);
      expect(notif.cancelados, contains(ServicioNotificaciones.idSeguro(id)));
    });

    testWidgets('desactivar el switch cancela y reactivar reprograma', (
      tester,
    ) async {
      final (base, firestore) = await _baseDatos();
      final idPaciente = await _sembrarPaciente(base);
      final notif = _FakeNotificaciones();
      final fecha = DateTime.now();
      final id = await base.agregarRecordatorio(
        idPaciente,
        Recordatorio(
          id: '',
          pacienteId: idPaciente,
          tipo: 'medicion',
          titulo: 'Medir temperatura',
          fechaHora: fecha,
          diasRepeticion: const [
            'lun',
            'mar',
            'mie',
            'jue',
            'vie',
            'sab',
            'dom',
          ],
          activo: true,
          creadoEn: fecha,
        ),
      );
      await _montar(tester, _pantalla(base, notif));
      await tester.tap(find.byKey(Key('switchActivo_$id')));
      await tester.pumpAndSettle();

      expect((await _doc(firestore, idPaciente, id))!['activo'], isFalse);
      expect(notif.cancelados, contains(ServicioNotificaciones.idSeguro(id)));

      await tester.tap(find.byKey(Key('switchActivo_$id')));
      await tester.pumpAndSettle();

      expect((await _doc(firestore, idPaciente, id))!['activo'], isTrue);
      expect(notif.programados, hasLength(1));
      expect(notif.programados.single['dias'], [
        'lun',
        'mar',
        'mie',
        'jue',
        'vie',
        'sab',
        'dom',
      ]);
    });

    testWidgets('el menú permite eliminar con confirmación', (tester) async {
      final (base, firestore) = await _baseDatos();
      final idPaciente = await _sembrarPaciente(base);
      final notif = _FakeNotificaciones();
      final fecha = DateTime.now();
      final id = await base.agregarRecordatorio(
        idPaciente,
        Recordatorio(
          id: '',
          pacienteId: idPaciente,
          tipo: 'cita',
          titulo: 'Control con especialista',
          fechaHora: fecha,
          activo: true,
          creadoEn: fecha,
        ),
      );
      await _montar(tester, _pantalla(base, notif));

      await tester.tap(find.byKey(Key('menuRecordatorio_$id')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('accionEliminar_$id')));
      await tester.pumpAndSettle();

      expect(find.text('¿Eliminar este recordatorio?'), findsOneWidget);
      expect(find.text('Eliminar'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      final docs = await firestore
          .collection('users')
          .doc(_uid)
          .collection('patients')
          .doc(idPaciente)
          .collection('recordatorios')
          .get();
      expect(docs.docs, isEmpty);
      expect(notif.cancelados, contains(ServicioNotificaciones.idSeguro(id)));
      expect(find.text('No tienes recordatorios.'), findsOneWidget);
    });

    testWidgets('el diálogo no se cierra con título vacío', (tester) async {
      final (base, _) = await _baseDatos();
      await _sembrarPaciente(base);
      final notif = _FakeNotificaciones();
      await _montar(tester, _pantalla(base, notif));

      await tester.tap(find.byKey(const Key('tarjetaRapida_medicamento')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmarRecordatorio')));
      await tester.pumpAndSettle();

      expect(find.text('Nuevo recordatorio'), findsOneWidget);
      expect(notif.programados, isEmpty);
    });

    testWidgets('la campanita silencia todas las notificaciones y se ve gris', (
      tester,
    ) async {
      final (base, _) = await _baseDatos();
      final idPaciente = await _sembrarPaciente(base);
      final notif = _FakeNotificaciones();
      final fecha = DateTime.now();
      final id = await base.agregarRecordatorio(
        idPaciente,
        Recordatorio(
          id: '',
          pacienteId: idPaciente,
          tipo: 'medicamento',
          titulo: 'Tomar jarabe',
          fechaHora: fecha,
          activo: true,
          creadoEn: fecha,
        ),
      );
      await _montar(tester, _pantalla(base, notif));

      expect(find.byIcon(Icons.notifications_active), findsOneWidget);
      expect(find.byIcon(Icons.notifications_off), findsNothing);

      await tester.tap(find.byKey(const Key('campanitaSilencio')));
      await tester.pumpAndSettle();

      expect(notif.canceladasTodas, 1);
      expect(find.byIcon(Icons.notifications_off), findsOneWidget);
      expect(find.byIcon(Icons.notifications_active), findsNothing);

      final opacidad = tester.widget<Opacity>(
        find
            .ancestor(
              of: find.byKey(Key('switchActivo_$id')),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(opacidad.opacity, 0.55);
    });

    testWidgets(
      'al reactivar la campanita vuelve a la configuración original',
      (tester) async {
        final (base, _) = await _baseDatos();
        final idPaciente = await _sembrarPaciente(base);
        final notif = _FakeNotificaciones();
        final fecha = DateTime.now().add(const Duration(days: 2));
        final id = await base.agregarRecordatorio(
          idPaciente,
          Recordatorio(
            id: '',
            pacienteId: idPaciente,
            tipo: 'medicamento',
            titulo: 'Tomar jarabe',
            fechaHora: fecha,
            activo: true,
            creadoEn: fecha,
          ),
        );
        await _montar(tester, _pantalla(base, notif));

        await tester.tap(find.byKey(const Key('campanitaSilencio')));
        await tester.pumpAndSettle();
        expect(notif.canceladasTodas, 1);
        expect(find.byIcon(Icons.notifications_off), findsOneWidget);

        await tester.tap(find.byKey(const Key('campanitaSilencio')));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.notifications_active), findsOneWidget);
        expect(find.byIcon(Icons.notifications_off), findsNothing);
        expect(notif.canceladasTodas, 2);
        expect(notif.programados, hasLength(1));
        expect(
          notif.programados.single['id'],
          ServicioNotificaciones.idSeguro(id),
        );

        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        expect(find.text('Notificaciones reactivadas'), findsOneWidget);
      },
    );
  });
}
