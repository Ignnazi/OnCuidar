import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/paciente.dart';
import 'package:oncuidar/caracteristicas/pacientes/presentacion/proveedores_pacientes.dart';
import 'package:oncuidar/caracteristicas/recordatorios/presentacion/pantalla_recordatorios.dart';
import 'package:oncuidar/caracteristicas/recordatorios/presentacion/proveedores_recordatorios.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('abrir desde un aviso selecciona a su paciente sin errores', (
    tester,
  ) async {
    final contenedor = ProviderContainer(
      overrides: [
        pacientesProvider.overrideWith(
          (_) => Stream.value([
            Paciente(
              id: 'p1',
              nombreCompleto: 'Ana Uno',
              creadoEn: DateTime(2026),
            ),
            Paciente(
              id: 'p2',
              nombreCompleto: 'Berta Dos',
              creadoEn: DateTime(2026),
            ),
          ]),
        ),
        recordatoriosProvider.overrideWith((_) => Stream.value(const [])),
      ],
    );
    addTearDown(contenedor.dispose);
    final sub = contenedor.listen(pacienteActivoProvider, (_, _) {});
    addTearDown(sub.close);
    await tester.pump();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: contenedor,
        child: const MaterialApp(home: RecordatoriosScreen(idPaciente: 'p2')),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(contenedor.read(idPacienteSeleccionadoProvider), 'p2');
    expect(contenedor.read(pacienteActivoProvider).value?.id, 'p2');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });
}
