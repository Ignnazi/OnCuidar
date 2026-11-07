import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/paciente.dart';
import 'package:oncuidar/caracteristicas/pacientes/presentacion/proveedores_pacientes.dart';
import 'package:oncuidar/caracteristicas/recordatorios/dominio/recordatorio.dart';
import 'package:oncuidar/caracteristicas/recordatorios/presentacion/proveedores_recordatorios.dart';

Future<AsyncValue<List<Recordatorio>>> _recordatorios(
  Stream<List<Paciente>> pacientes,
) async {
  final contenedor = ProviderContainer(
    overrides: [pacientesProvider.overrideWith((_) => pacientes)],
    retry: (_, _) => null,
  );
  addTearDown(contenedor.dispose);
  final sub = contenedor.listen(recordatoriosProvider, (_, _) {});
  addTearDown(sub.close);
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
  return contenedor.read(recordatoriosProvider);
}

void main() {
  test('si no se pudieron cargar los pacientes avisa el error', () async {
    final estado = await _recordatorios(Stream.error(Exception('500')));
    expect(estado.hasError, isTrue);
  });

  test('sin pacientes la lista queda vacía', () async {
    final estado = await _recordatorios(Stream.value(const []));
    expect(estado.hasError, isFalse);
    expect(estado.value, isEmpty);
  });
}
