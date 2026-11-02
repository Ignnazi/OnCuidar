import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/nucleo/utilidades/validacion_correo.dart';

void main() {
  group('regexCorreo', () {
    test('acepta correos habituales', () {
      expect(regexCorreo.hasMatch('a@b.cl'), isTrue);
      expect(regexCorreo.hasMatch('nombre.apellido@mail.com'), isTrue);
      expect(regexCorreo.hasMatch('user_1@alumnos.ubiobio.cl'), isTrue);
    });

    test('rechaza correos sin arroba o sin dominio', () {
      expect(regexCorreo.hasMatch('sin-arroba'), isFalse);
      expect(regexCorreo.hasMatch('a@b'), isFalse);
      expect(regexCorreo.hasMatch('@b.cl'), isFalse);
    });

    test('rechaza espacios', () {
      expect(regexCorreo.hasMatch('a @b.cl'), isFalse);
      expect(regexCorreo.hasMatch(' a@b.cl'), isFalse);
    });

    test('exige una extensión de 2 a 4 caracteres', () {
      expect(regexCorreo.hasMatch('a@b.c'), isFalse);
      expect(regexCorreo.hasMatch('a@b.comercial'), isFalse);
    });
  });
}
