import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/paciente.dart';
import 'package:oncuidar/caracteristicas/pacientes/presentacion/proveedores_pacientes.dart';

Future<AsyncValue<Paciente?>> _activo(Stream<List<Paciente>> pacientes) async {
  final contenedor = ProviderContainer(
    overrides: [pacientesProvider.overrideWith((_) => pacientes)],
    retry: (_, _) => null,
  );
  addTearDown(contenedor.dispose);
  final sub = contenedor.listen(pacienteActivoProvider, (_, _) {});
  addTearDown(sub.close);
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
  return contenedor.read(pacienteActivoProvider);
}

void main() {
  test('si no se pudieron cargar los pacientes avisa el error', () async {
    final estado = await _activo(Stream.error(Exception('500')));
    expect(estado.hasError, isTrue);
  });

  test('sin pacientes sigue sin paciente activo', () async {
    final estado = await _activo(Stream.value(const []));
    expect(estado.hasError, isFalse);
    expect(estado.value, isNull);
  });
}
