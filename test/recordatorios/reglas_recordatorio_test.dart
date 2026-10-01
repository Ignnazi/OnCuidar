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
import 'package:oncuidar/modelos/recordatorio.dart';
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
  group('Asignación en documentos anteriores', () {
    test('un recordatorio guardado sin asignadoA va dirigido al paciente', () async {
      final (base, firestore) = await baseRecordatorios();
      final idPaciente = await crearPacienteRecordatorios(base);
      final cifrado = ServicioCifrado(clavePrueba: clavePruebaRecordatorios);
      await cifrado.fijarClave(uidRecordatorios, clavePruebaRecordatorios);
      await firestore
          .collection('users')
          .doc(uidRecordatorios)
          .collection('patients')
          .doc(idPaciente)
          .collection('recordatorios')
          .doc('anterior')
          .set({
            'pacienteId': idPaciente,
            'activo': true,
            'creadoEn': DateTime(2026, 1, 1).toIso8601String(),
            'version_encriptacion': 3,
            'titulo_cifrado': await cifrado.cifrar(
              uidRecordatorios,
              'Jarabe de la mañana',
            ),
            'datos_cifrados': await cifrado.cifrar(
              uidRecordatorios,
              jsonEncode(<String, dynamic>{
                'tipo': 'medicamento',
                'fechaHora': DateTime(2026, 12, 1, 9).toIso8601String(),
                'diasRepeticion': <String>[],
              }),
            ),
          });

      final leidos = await base.recordatoriosEnTiempoReal(idPaciente).first;
      expect(leidos.single.titulo, 'Jarabe de la mañana');
      expect(leidos.single.asignadoA, Recordatorio.asignadoAPaciente);
      expect(leidos.single.esParaCuidador, isFalse);
    });
  });

  group('Asignación al editar', () {
    testWidgets('cambiar a cuidador guarda la asignación y renombra el aviso', (
      tester,
    ) async {
      final (base, firestore) = await baseRecordatorios();
      final idPaciente = await crearPacienteRecordatorios(base);
      final id = await base.agregarRecordatorio(
        idPaciente,
        recordatorioDe(idPaciente, titulo: 'Retirar receta'),
      );
      final notif = NotificacionesFalsas();
      await _montar(tester, _pantalla(base, notif));

      await _elegirAccion(tester, id, 'Editar');
      await tester.tap(find.byKey(const Key('asignado_cuidador')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmarRecordatorio')));
      await tester.pumpAndSettle();

      expect((await _payload(firestore, idPaciente, id))['asignadoA'], 'cuidador');
      expect(notif.programados.last['titulo'], 'Cuidador · Medicamento');
      expect(find.text('Cuidador'), findsOneWidget);
    });
  });

  group('Límites del selector de fecha', () {
    IconButton? botonDelCalendario(WidgetTester tester, IconData icono) {
      final encontrados = find.ancestor(
        of: find.byIcon(icono),
        matching: find.byType(IconButton),
      );
      final botones = tester.widgetList<IconButton>(encontrados);
      return botones.isEmpty ? null : botones.first;
    }

    testWidgets('un recordatorio de una sola vez no admite fechas pasadas', (
      tester,
    ) async {
      final (base, _) = await baseRecordatorios();
      await _montar(tester, _pantalla(base, NotificacionesFalsas()));

      await tester.tap(find.byKey(const Key('tarjetaRapida_medicamento')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('modoRepeticion_unavez')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('campoFechaRecordatorio')));
      await tester.pumpAndSettle();

      expect(botonDelCalendario(tester, Icons.chevron_left)?.onPressed, isNull);
      expect(
        botonDelCalendario(tester, Icons.chevron_right)?.onPressed,
        isNotNull,
      );
    });
  });
}