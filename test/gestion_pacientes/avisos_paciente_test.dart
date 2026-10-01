import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/perfil/gestion_pacientes.dart';
import 'package:oncuidar/core/proveedores/proveedores.dart';
import 'package:oncuidar/core/servicios/servicio_base_datos.dart';
import 'package:oncuidar/core/servicios/servicio_notificaciones.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../recordatorios/ayudas_recordatorios.dart';

Widget _pantalla(ServicioBaseDatos base, NotificacionesFalsas notif) {
  return ProviderScope(
    overrides: [
      servicioBaseDatosProvider.overrideWith((_) => base),
      servicioNotificacionesProvider.overrideWithValue(notif),
    ],
    child: const MaterialApp(home: Scaffold(body: GestionPacientes())),
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

Future<void> _accionDelMenu(WidgetTester tester, String etiqueta) async {
  await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(etiqueta).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('archivar desde el perfil cancela los avisos del paciente', (
    tester,
  ) async {
    final (base, _) = await baseRecordatorios();
    final idPaciente = await crearPacienteRecordatorios(
      base,
      nombre: 'Rosa Pérez',
    );
    final id1 = await base.agregarRecordatorio(
      idPaciente,
      recordatorioDe(idPaciente, titulo: 'Jarabe'),
    );
    final id2 = await base.agregarRecordatorio(
      idPaciente,
      recordatorioDe(idPaciente, titulo: 'Control'),
    );
    final notif = NotificacionesFalsas();
    await _montar(tester, _pantalla(base, notif));

    await _accionDelMenu(tester, 'Archivar paciente');
    await tester.tap(find.text('Archivar'));
    await tester.pumpAndSettle();

    expect(
      notif.cancelados,
      containsAll([
        ServicioNotificaciones.idSeguro(id1),
        ServicioNotificaciones.idSeguro(id2),
      ]),
    );
    expect(await base.pacientesEnTiempoReal().first, isEmpty);
  });

  testWidgets('eliminar desde el perfil cancela los avisos antes de borrar', (
    tester,
  ) async {
    final (base, _) = await baseRecordatorios();
    final idPaciente = await crearPacienteRecordatorios(base);
    final id = await base.agregarRecordatorio(
      idPaciente,
      recordatorioDe(idPaciente, titulo: 'Jarabe'),
    );
    final notif = NotificacionesFalsas();
    await _montar(tester, _pantalla(base, notif));

    await _accionDelMenu(tester, 'Eliminar paciente');
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(notif.cancelados, contains(ServicioNotificaciones.idSeguro(id)));
    expect(await base.pacientesEnTiempoReal().first, isEmpty);
  });

  testWidgets('restaurar desde el perfil vuelve a programar los avisos', (
    tester,
  ) async {
    final (base, _) = await baseRecordatorios();
    final idPaciente = await crearPacienteRecordatorios(
      base,
      nombre: 'Rosa Pérez',
    );
    await base.agregarRecordatorio(
      idPaciente,
      recordatorioDe(idPaciente, titulo: 'Jarabe'),
    );
    await base.archivarPaciente(idPaciente);
    final notif = NotificacionesFalsas();
    await _montar(tester, _pantalla(base, notif));

    await tester.tap(find.text('Archivados (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Restaurar Rosa Pérez'));
    await tester.pumpAndSettle();

    expect(notif.programados.map((p) => p['cuerpo']), ['Jarabe']);
    expect((await base.pacientesEnTiempoReal().first).single.id, idPaciente);
  });
}