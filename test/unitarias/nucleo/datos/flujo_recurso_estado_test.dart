import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/nucleo/datos/flujo_recurso.dart';

import '../../../ayudas/offline.dart';

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

    await esperarHasta(() async => emitidos.isNotEmpty);
    expect(emitidos, ['']);

    clave = 'con_clave';
    await esperarHasta(() async => emitidos.length == 2);
    expect(emitidos, ['', 'Ana']);
  });
}
