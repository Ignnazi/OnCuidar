import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/acciones_material.dart';

void main() {
  group('mensajeFavorito', () {
    test('indica el tipo de material con su género', () {
      expect(
        mensajeFavorito('Videos', agregado: true),
        'Video añadido a tus favoritos',
      );
      expect(
        mensajeFavorito('Guías', agregado: true),
        'Guía añadida a tus favoritos',
      );
      expect(
        mensajeFavorito('Infografías', agregado: true),
        'Infografía añadida a tus favoritos',
      );
    });

    test('al quitar usa la forma de quitado', () {
      expect(
        mensajeFavorito('Videos', agregado: false),
        'Video quitado de tus favoritos',
      );
      expect(
        mensajeFavorito('Infografías', agregado: false),
        'Infografía quitada de tus favoritos',
      );
    });

    test('sin categoría habla de material', () {
      expect(
        mensajeFavorito(null, agregado: true),
        'Material añadido a tus favoritos',
      );
    });
  });
}
