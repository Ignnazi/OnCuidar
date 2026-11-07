import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/paciente.dart';
import 'package:oncuidar/caracteristicas/pacientes/presentacion/proveedores_pacientes.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/presentacion/proveedores_registro_clinico.dart';

Future<AsyncValue<List<RegistroClinico>>> _registros(
  Stream<List<Paciente>> pacientes,
) async {
  final contenedor = ProviderContainer(
    overrides: [pacientesProvider.overrideWith((_) => pacientes)],
    retry: (_, _) => null,
  );
  addTearDown(contenedor.dispose);
  final sub = contenedor.listen(registrosClinicosProvider, (_, _) {});
  addTearDown(sub.close);
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
  return contenedor.read(registrosClinicosProvider);
}

void main() {
  test('si no se pudieron cargar los pacientes avisa el error', () async {
    final estado = await _registros(Stream.error(Exception('500')));
    expect(estado.hasError, isTrue);
  });

  test('sin pacientes la lista queda vacía', () async {
    final estado = await _registros(Stream.value(const []));
    expect(estado.hasError, isFalse);
    expect(estado.value, isEmpty);
  });
}
