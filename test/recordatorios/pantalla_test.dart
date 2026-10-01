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
import 'package:shared_preferences/shared_preferences.dart';

import 'ayudas_recordatorios.dart';

Widget _pantalla(ServicioBaseDatos base, NotificacionesFalsas notif) {
  final router = GoRouter(
    initialLocation: '/recordatorios',
    routes: [
      GoRoute(
        path: '/recordatorios',
        builder: (c, s) => const RecordatoriosScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (c, s) => const Scaffold(body: Text('Dashboard stub')),
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
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(pantalla);
  await tester.pumpAndSettle();
}

Future<Map<String, dynamic>> _payload(
  FakeFirebaseFirestore firestore,
  String idPaciente,
  String id,
) async {
  final datos =
      (await firestore
              .collection('users')
              .doc(uidRecordatorios)
              .collection('patients')
              .doc(idPaciente)
              .collection('recordatorios')
              .doc(id)
              .get())
          .data()!;
  final cifrado = ServicioCifrado(clavePrueba: clavePruebaRecordatorios);
  await cifrado.fijarClave(uidRecordatorios, clavePruebaRecordatorios);
  return jsonDecode(
        await cifrado.descifrar(
          uidRecordatorios,
          datos['datos_cifrados'] as String,
        ),
      )
      as Map<String, dynamic>;
}

Future<void> _elegirAccion(WidgetTester tester, String id, String accion) async {
  await tester.tap(find.byKey(Key('menuRecordatorio_$id')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key('accion${accion}_$id')));
  await tester.pumpAndSettle();
}

void main() {
  group('Asignación del recordatorio', () {
    testWidgets('dirigirlo al cuidador guarda la asignación y nombra el aviso', (
      tester,
    ) async {
      final (base, firestore) = await baseRecordatorios();
      final idPaciente = await crearPacienteRecordatorios(base);
      final notif = NotificacionesFalsas();
      await _montar(tester, _pantalla(base, notif));

      await tester.tap(find.byKey(const Key('tarjetaRapida_medicamento')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('campoTituloRecordatorio')),
        'Mi control',
      );
      await tester.tap(find.byKey(const Key('asignado_cuidador')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmarRecordatorio')));
      await tester.pumpAndSettle();

      final docs = await firestore
          .collection('users')
          .doc(uidRecordatorios)
          .collection('patients')
          .doc(idPaciente)
          .collection('recordatorios')
          .get();
      final payload = await _payload(firestore, idPaciente, docs.docs.single.id);
      expect(payload['asignadoA'], 'cuidador');
      expect(notif.programados.single['titulo'], 'Cuidador · Medicamento');
      expect(find.text('Cuidador'), findsOneWidget);
    });

    testWidgets('por defecto va dirigido al paciente', (tester) async {
      final (base, firestore) = await baseRecordatorios();
      final idPaciente = await crearPacienteRecordatorios(base);
      final notif = NotificacionesFalsas();
      await _montar(tester, _pantalla(base, notif));

      await tester.tap(find.byKey(const Key('tarjetaRapida_medicamento')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('campoTituloRecordatorio')),
        'Jarabe',
      );
      await tester.tap(find.byKey(const Key('confirmarRecordatorio')));
      await tester.pumpAndSettle();

      final docs = await firestore
          .collection('users')
          .doc(uidRecordatorios)
          .collection('patients')
          .doc(idPaciente)
          .collection('recordatorios')
          .get();
      expect(
        (await _payload(firestore, idPaciente, docs.docs.single.id))['asignadoA'],
        'paciente',
      );
      expect(notif.programados.single['titulo'], 'Paciente Test · Medicamento');
    });
  });

  group('Fecha del recordatorio', () {
    testWidgets('una sola vez guarda la fecha elegida en el selector', (
      tester,
    ) async {
      final (base, firestore) = await baseRecordatorios();
      final idPaciente = await crearPacienteRecordatorios(base);
      final notif = NotificacionesFalsas();
      await _montar(tester, _pantalla(base, notif));
      final anio = DateTime.now().year + 1;

      await tester.tap(find.byKey(const Key('tarjetaRapida_cita')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('campoTituloRecordatorio')),
        'Control anual',
      );
      await tester.tap(find.byKey(const Key('modoRepeticion_unavez')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('campoFechaRecordatorio')));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '12/31/$anio');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmarRecordatorio')));
      await tester.pumpAndSettle();

      final docs = await firestore
          .collection('users')
          .doc(uidRecordatorios)
          .collection('patients')
          .doc(idPaciente)
          .collection('recordatorios')
          .get();
      final payload = await _payload(firestore, idPaciente, docs.docs.single.id);
      final fecha = DateTime.parse(payload['fechaHora'] as String);
      expect((fecha.year, fecha.month, fecha.day), (anio, 12, 31));
      expect(payload['diasRepeticion'], isEmpty);
      final programada = notif.programados.single['fechaHora'] as DateTime;
      expect((programada.year, programada.month, programada.day), (anio, 12, 31));
    });

    testWidgets('mensual guarda el día del mes elegido en el selector', (
      tester,
    ) async {
      final (base, firestore) = await baseRecordatorios();
      final idPaciente = await crearPacienteRecordatorios(base);
      final notif = NotificacionesFalsas();
      await _montar(tester, _pantalla(base, notif));
      final anio = DateTime.now().year + 1;

      await tester.tap(find.byKey(const Key('tarjetaRapida_medicamento')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('campoTituloRecordatorio')),
        'Retirar receta',
      );
      await tester.tap(find.byKey(const Key('modoRepeticion_mensual')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('campoFechaRecordatorio')));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '03/20/$anio');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(
        find.text('Se recordará cada mes el día 20 a la hora indicada.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('confirmarRecordatorio')));
      await tester.pumpAndSettle();

      final docs = await firestore
          .collection('users')
          .doc(uidRecordatorios)
          .collection('patients')
          .doc(idPaciente)
          .collection('recordatorios')
          .get();
      final payload = await _payload(firestore, idPaciente, docs.docs.single.id);
      expect(DateTime.parse(payload['fechaHora'] as String).day, 20);
      expect(payload['recurrencia'], 'mensual');
      expect(notif.programados.single['mensual'], isTrue);
      expect((notif.programados.single['fechaHora'] as DateTime).day, 20);
    });

    testWidgets('editar uno mensual conserva su día y la descripción del aviso', (
      tester,
    ) async {
      final (base, firestore) = await baseRecordatorios();
      final idPaciente = await crearPacienteRecordatorios(base);
      final id = await base.agregarRecordatorio(
        idPaciente,
        recordatorioDe(
          idPaciente,
          titulo: 'Control mensual',
          fechaHora: DateTime(2026, 1, 15, 9),
          recurrencia: 'mensual',
        ),
      );
      final notif = NotificacionesFalsas();
      await _montar(tester, _pantalla(base, notif));

      await _elegirAccion(tester, id, 'Editar');
      expect(
        find.text('Se recordará cada mes el día 15 a la hora indicada.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const Key('campoDescripcionRecordatorio')),
        'Llevar carnet',
      );
      await tester.tap(find.byKey(const Key('confirmarRecordatorio')));
      await tester.pumpAndSettle();

      final payload = await _payload(firestore, idPaciente, id);
      expect(DateTime.parse(payload['fechaHora'] as String).day, 15);
      expect(payload['recurrencia'], 'mensual');
      final aviso = notif.programados.last;
      expect(aviso['cuerpo'], 'Control mensual · Llevar carnet');
      expect(aviso['mensual'], isTrue);
    });

    testWidgets('editar uno de una sola vez no cambia su fecha', (tester) async {
      final (base, firestore) = await baseRecordatorios();
      final idPaciente = await crearPacienteRecordatorios(base);
      final futura = DateTime.now().add(const Duration(days: 10));
      final original = DateTime(futura.year, futura.month, futura.day, 9);
      final id = await base.agregarRecordatorio(
        idPaciente,
        recordatorioDe(idPaciente, fechaHora: original),
      );
      await _montar(tester, _pantalla(base, NotificacionesFalsas()));

      await _elegirAccion(tester, id, 'Editar');
      await tester.tap(find.byKey(const Key('confirmarRecordatorio')));
      await tester.pumpAndSettle();

      final payload = await _payload(firestore, idPaciente, id);
      expect(DateTime.parse(payload['fechaHora'] as String), original);
      expect(payload['diasRepeticion'], isEmpty);
    });

  });
}
