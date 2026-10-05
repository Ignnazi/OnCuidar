import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oncuidar/caracteristicas/recordatorios/datos/repositorio_recordatorios.dart';
import 'package:oncuidar/caracteristicas/recordatorios/dominio/recordatorio.dart';
import 'package:oncuidar/caracteristicas/recordatorios/presentacion/pantalla_recordatorios.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
import 'package:oncuidar/nucleo/notificaciones/servicio_notificaciones.dart';
import 'package:oncuidar/nucleo/notificaciones/silencio_avisos.dart';
import 'package:oncuidar/nucleo/proveedores.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../ayudas/recordatorios.dart';

Widget _pantalla(BaseDatosSegura base, NotificacionesFalsas notif) {
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
      baseDatosSeguraProvider.overrideWith((_) => base),
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

void main() {
  group('Pantalla de recordatorios', () {
    testWidgets('muestra estado vacío y los 4 accesos rápidos', (tester) async {
      final (base, _) = await baseRecordatorios();
      final notif = NotificacionesFalsas();
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
        final (base, firestore) = await baseRecordatorios();
        final idPaciente = await crearPacienteRecordatorios(base);
        final notif = NotificacionesFalsas();
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
            .collection('usuarios')
            .doc(uidRecordatorios)
            .collection('pacientes')
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
      final (base, firestore) = await baseRecordatorios();
      final idPaciente = await crearPacienteRecordatorios(base);
      final notif = NotificacionesFalsas();
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
          .collection('usuarios')
          .doc(uidRecordatorios)
          .collection('pacientes')
          .doc(idPaciente)
          .collection('recordatorios')
          .get();
      final datos = docs.docs.single.data();
      expect(datos.containsKey('recurrencia'), isFalse);
      expect(datos.containsKey('diasRepeticion'), isFalse);
      final payload = await payloadRecordatorio(
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
      final (base, firestore) = await baseRecordatorios();
      final idPaciente = await crearPacienteRecordatorios(base);
      final notif = NotificacionesFalsas();
      final fecha = DateTime.now();
      await RepositorioRecordatorios(base).agregarRecordatorio(
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
      final (base, firestore) = await baseRecordatorios();
      final idPaciente = await crearPacienteRecordatorios(base);
      final notif = NotificacionesFalsas();
      final fecha = DateTime.now();
      final id = await RepositorioRecordatorios(base).agregarRecordatorio(
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
          .collection('usuarios')
          .doc(uidRecordatorios)
          .collection('pacientes')
          .doc(idPaciente)
          .collection('recordatorios')
          .get();
      expect(docs.docs, isEmpty);
      expect(notif.cancelados, contains(ServicioNotificaciones.idSeguro(id)));
    });

    testWidgets('desactivar el switch cancela y reactivar reprograma', (
      tester,
    ) async {
      final (base, firestore) = await baseRecordatorios();
      final idPaciente = await crearPacienteRecordatorios(base);
      final notif = NotificacionesFalsas();
      final fecha = DateTime.now();
      final id = await RepositorioRecordatorios(base).agregarRecordatorio(
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

      expect(
        (await docRecordatorio(firestore, idPaciente, id))!['activo'],
        isFalse,
      );
      expect(notif.cancelados, contains(ServicioNotificaciones.idSeguro(id)));

      await tester.tap(find.byKey(Key('switchActivo_$id')));
      await tester.pumpAndSettle();

      expect(
        (await docRecordatorio(firestore, idPaciente, id))!['activo'],
        isTrue,
      );
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

    testWidgets('el diálogo no se cierra con título vacío', (tester) async {
      final (base, _) = await baseRecordatorios();
      await crearPacienteRecordatorios(base);
      final notif = NotificacionesFalsas();
      await _montar(tester, _pantalla(base, notif));

      await tester.tap(find.byKey(const Key('tarjetaRapida_medicamento')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmarRecordatorio')));
      await tester.pumpAndSettle();

      expect(find.text('Nuevo recordatorio'), findsOneWidget);
      expect(notif.programados, isEmpty);
    });

    testWidgets(
      'el interruptor queda abajo a la derecha, a la altura de los días y más grande',
      (tester) async {
        final (base, _) = await baseRecordatorios();
        final idPaciente = await crearPacienteRecordatorios(base);
        final notif = NotificacionesFalsas();
        final fecha = DateTime.now();
        final id = await RepositorioRecordatorios(base).agregarRecordatorio(
          idPaciente,
          Recordatorio(
            id: '',
            pacienteId: idPaciente,
            tipo: 'medicamento',
            titulo: 'Tomar jarabe',
            fechaHora: fecha,
            diasRepeticion: const ['lun', 'mie'],
            activo: true,
            creadoEn: fecha,
          ),
        );
        await _montar(tester, _pantalla(base, notif));

        final interruptor = tester.getRect(find.byKey(Key('switchActivo_$id')));
        final dias = tester.getRect(find.text('Lun'));
        final tarjeta = tester.getRect(
          find
              .ancestor(
                of: find.byKey(Key('switchActivo_$id')),
                matching: find.byType(Container),
              )
              .last,
        );

        expect((interruptor.center.dy - dias.center.dy).abs(), lessThan(12));
        expect(tarjeta.bottom - interruptor.bottom, lessThan(20));
        expect(interruptor.left, greaterThan(dias.right));
        final menu = tester.getRect(find.byKey(Key('menuRecordatorio_$id')));
        expect(interruptor.top, greaterThan(menu.bottom));
        expect(interruptor.width, greaterThan(48));
        expect(interruptor.height, greaterThan(26));
      },
    );

    testWidgets('la campanita silencia solo al paciente activo y se ve gris', (
      tester,
    ) async {
      final (base, _) = await baseRecordatorios();
      final idPaciente = await crearPacienteRecordatorios(base);
      final notif = NotificacionesFalsas();
      final fecha = DateTime.now();
      final id = await RepositorioRecordatorios(base).agregarRecordatorio(
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

      expect(notif.canceladasTodas, 0);
      expect(notif.cancelados, contains(ServicioNotificaciones.idSeguro(id)));
      expect(find.byIcon(Icons.notifications_off), findsOneWidget);
      expect(find.byIcon(Icons.notifications_active), findsNothing);
      expect(await SilencioAvisos.global(), isFalse);
      expect(await SilencioAvisos.pacientes(), {idPaciente});

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

    testWidgets('al reactivar la campanita vuelven los avisos del paciente', (
      tester,
    ) async {
      final (base, _) = await baseRecordatorios();
      final idPaciente = await crearPacienteRecordatorios(base);
      final notif = NotificacionesFalsas();
      final fecha = DateTime.now().add(const Duration(days: 2));
      final id = await RepositorioRecordatorios(base).agregarRecordatorio(
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
      expect(find.byIcon(Icons.notifications_off), findsOneWidget);
      expect(notif.programados, isEmpty);

      await tester.tap(find.byKey(const Key('campanitaSilencio')));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications_active), findsOneWidget);
      expect(find.byIcon(Icons.notifications_off), findsNothing);
      expect(await SilencioAvisos.pacientes(), isEmpty);
      expect(notif.programados, hasLength(1));
      expect(
        notif.programados.single['id'],
        ServicioNotificaciones.idSeguro(id),
      );

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text('Avisos de Paciente reactivados'), findsOneWidget);
    });

    testWidgets(
      'con el silencio general activo la campanita no cambia nada y avisa dónde quitarlo',
      (tester) async {
        final (base, _) = await baseRecordatorios();
        await crearPacienteRecordatorios(base);
        final notif = NotificacionesFalsas();
        await _montar(tester, _pantalla(base, notif));
        SharedPreferences.setMockInitialValues({
          SilencioAvisos.claveGlobal: true,
        });
        await tester.pumpWidget(_pantalla(base, notif));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.notifications_off), findsOneWidget);

        await tester.tap(find.byKey(const Key('campanitaSilencio')));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Todos los avisos están silenciados'),
          findsOneWidget,
        );
        expect(await SilencioAvisos.pacientes(), isEmpty);
        expect(notif.canceladasTodas, 0);
      },
    );
  });
}
