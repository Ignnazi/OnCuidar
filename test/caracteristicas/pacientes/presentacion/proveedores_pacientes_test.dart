import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/pacientes/presentacion/proveedores_pacientes.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _esperar(bool Function() condicion) async {
  for (var i = 0; i < 100; i++) {
    if (condicion()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('La condición no se cumplió a tiempo');
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('el paciente elegido sigue seleccionado tras reiniciar', () async {
    final antes = ProviderContainer();
    await antes
        .read(idPacienteSeleccionadoProvider.notifier)
        .seleccionar('paciente-b');
    expect(antes.read(idPacienteSeleccionadoProvider), 'paciente-b');
    antes.dispose();

    final despues = ProviderContainer();
    addTearDown(despues.dispose);
    despues.read(idPacienteSeleccionadoProvider);
    await _esperar(
      () => despues.read(idPacienteSeleccionadoProvider) == 'paciente-b',
    );
  });

  test('al quitar la selección no queda nada guardado', () async {
    final antes = ProviderContainer();
    await antes
        .read(idPacienteSeleccionadoProvider.notifier)
        .seleccionar('paciente-a');
    await antes.read(idPacienteSeleccionadoProvider.notifier).seleccionar(null);
    antes.dispose();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('selected_patient_id'), isNull);
    final despues = ProviderContainer();
    addTearDown(despues.dispose);
    expect(despues.read(idPacienteSeleccionadoProvider), isNull);
  });
}
