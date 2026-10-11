import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/biblioteca/datos/servicio_cache_contenido.dart';

void main() {
  test('acepta el archivo cuando el tamaño coincide', () {
    expect(descargaCompleta(esperado: 1000, real: 1000), isTrue);
  });

  test('rechaza el archivo cuando el tamaño difiere', () {
    expect(descargaCompleta(esperado: 1000, real: 640), isFalse);
  });

  test('acepta cualquier tamaño si el material no lo declara', () {
    expect(descargaCompleta(esperado: null, real: 640), isTrue);
    expect(descargaCompleta(esperado: 0, real: 640), isTrue);
  });
}
