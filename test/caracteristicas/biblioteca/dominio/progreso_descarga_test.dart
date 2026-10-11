import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/estado_descarga_contenido.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/progreso_descarga.dart';

void main() {
  test('pondera por bytes: un video grande pesa más que una imagen', () {
    final p = ProgresoDescarga({'video': 9000, 'imagen': 1000});
    p.completar('imagen');
    expect(p.porcentaje, 10);
    p.avanzar('video', 4500);
    expect(p.porcentaje, 55);
  });

  test('empieza en 0 y llega a 100 solo al terminar todo', () {
    final p = ProgresoDescarga({'a': 100, 'b': 100});
    expect(p.porcentaje, 0);
    p.completar('a');
    p.avanzar('b', 100);
    expect(p.porcentaje, 99, reason: 'b aún no está completa');
    expect(p.terminado, isFalse);
    p.completar('b');
    expect(p.porcentaje, 100);
    expect(p.terminado, isTrue);
  });

  test('nunca retrocede aunque el total real sea mayor al estimado', () {
    final p = ProgresoDescarga({
      'a': null,
      'b': null,
    }, estimacionPorDefecto: 100);
    p.avanzar('a', 100);
    final antes = p.porcentaje;
    p.avanzar('a', 120, total: 1000);
    expect(p.porcentaje, greaterThanOrEqualTo(antes));
    var previo = p.porcentaje;
    for (var d = 200; d <= 1000; d += 200) {
      p.avanzar('a', d, total: 1000);
      expect(p.porcentaje, greaterThanOrEqualTo(previo));
      previo = p.porcentaje;
    }
  });

  test('tamaños desconocidos usan el promedio de los conocidos', () {
    final p = ProgresoDescarga({'a': 1000, 'b': null});
    p.completar('a');
    expect(p.porcentaje, 50);
  });

  test('sin ningún tamaño usa la estimación por defecto y no pasa de 99', () {
    final p = ProgresoDescarga({'a': null}, estimacionPorDefecto: 100);
    p.avanzar('a', 5000);
    expect(p.porcentaje, 99);
  });

  test('una descarga fallida cuenta como resuelta y permite terminar', () {
    final p = ProgresoDescarga({'a': 100, 'b': 100});
    p.completar('a');
    p.descartar('b');
    expect(p.terminado, isTrue);
    expect(p.porcentaje, 100);
  });

  test('ignora urls desconocidas y retrocesos de bytes', () {
    final p = ProgresoDescarga({'a': 100, 'b': 100});
    p.avanzar('x', 50);
    p.avanzar('a', 80);
    p.avanzar('a', 20);
    expect(p.porcentaje, 40);
  });

  test('el anuncio al lector sube de 10 en 10', () {
    expect(porcentajeAnunciable(0), 0);
    expect(porcentajeAnunciable(9), 0);
    expect(porcentajeAnunciable(45), 40);
    expect(porcentajeAnunciable(100), 100);
  });
}
