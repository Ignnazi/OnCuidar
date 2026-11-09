import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/nucleo/datos/flujo_recurso.dart';

void main() {
  test('con el mismo JSON vuelve a convertir si cambió el estado', () async {
    var clave = 'sin_clave';
    final emitidos = <String>[];
    final flujo = FlujoRecurso<String>(
      consultar: () async => [
        {'id': 'p1'},
      ],
      leerCache: () async => null,
      guardarCache: (_) async {},
      aplicarPendientes: (json) async => json,
      cambios: const Stream.empty(),
      convertir: (_) async => clave == 'con_clave' ? 'Ana' : '',
      vacio: const [],
      intervalo: const Duration(milliseconds: 20),
      estado: () => clave,
    );
    final sub = flujo.stream.listen(emitidos.add);
    addTearDown(sub.cancel);

    await Future<void>.delayed(const Duration(milliseconds: 70));
    expect(emitidos, ['']);

    clave = 'con_clave';
    await Future<void>.delayed(const Duration(milliseconds: 70));
    expect(emitidos, ['', 'Ana']);
  });
}
