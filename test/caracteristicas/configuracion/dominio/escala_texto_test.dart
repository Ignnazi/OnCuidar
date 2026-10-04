import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/configuracion/dominio/escala_texto.dart';

void main() {
  group('EscalaTexto', () {
    test('los factores crecen de normal a muy grande', () {
      expect(EscalaTexto.normal.factor, 1.0);
      expect(EscalaTexto.grande.factor, greaterThan(1.0));
      expect(
        EscalaTexto.muyGrande.factor,
        greaterThan(EscalaTexto.grande.factor),
      );
    });

    test('desdeNombre recupera la escala guardada', () {
      expect(EscalaTexto.desdeNombre('grande'), EscalaTexto.grande);
      expect(EscalaTexto.desdeNombre('muyGrande'), EscalaTexto.muyGrande);
    });

    test('un nombre desconocido o ausente cae a normal', () {
      expect(EscalaTexto.desdeNombre('enorme'), EscalaTexto.normal);
      expect(EscalaTexto.desdeNombre(null), EscalaTexto.normal);
    });
  });
}
