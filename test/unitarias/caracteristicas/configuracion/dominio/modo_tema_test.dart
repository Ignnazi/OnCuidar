import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/configuracion/dominio/modo_tema.dart';

void main() {
  group('ModoTema', () {
    test('automático sigue el brillo del sistema', () {
      expect(ModoTema.sistema.esOscuro(Brightness.dark), isTrue);
      expect(ModoTema.sistema.esOscuro(Brightness.light), isFalse);
    });

    test('claro y oscuro ignoran el sistema', () {
      expect(ModoTema.claro.esOscuro(Brightness.dark), isFalse);
      expect(ModoTema.oscuro.esOscuro(Brightness.light), isTrue);
    });

    test('desdeNombre recupera el guardado y cae a automático', () {
      expect(ModoTema.desdeNombre('oscuro'), ModoTema.oscuro);
      expect(ModoTema.desdeNombre('otro'), ModoTema.sistema);
      expect(ModoTema.desdeNombre(null), ModoTema.sistema);
    });
  });
}
