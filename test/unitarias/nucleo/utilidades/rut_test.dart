import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/nucleo/utilidades/rut.dart';

void main() {
  group('formatearRut', () {
    test('agrega puntos y guion', () {
      expect(formatearRut('123456785'), '12.345.678-5');
    });

    test('ignora puntos, guiones y espacios ya escritos', () {
      expect(formatearRut('12.345.678-5'), '12.345.678-5');
      expect(formatearRut(' 12 345 678 5 '), '12.345.678-5');
    });

    test('pasa la K a mayúscula', () {
      expect(formatearRut('1234567k'), '1.234.567-K');
    });

    test('devuelve vacío si no hay dígitos ni K', () {
      expect(formatearRut(''), '');
      expect(formatearRut('abc'), '');
    });

    test('con un solo carácter no agrega separadores', () {
      expect(formatearRut('5'), '5');
    });

    test('con dos caracteres solo agrega el guion', () {
      expect(formatearRut('12'), '1-2');
    });
  });

  group('validarRut', () {
    test('acepta RUT con dígito verificador correcto', () {
      expect(validarRut('11.111.111-1'), isTrue);
      expect(validarRut('12.345.678-5'), isTrue);
    });

    test('acepta el dígito verificador K en mayúscula o minúscula', () {
      expect(validarRut('6-K'), isTrue);
      expect(validarRut('6-k'), isTrue);
    });

    test('rechaza un dígito verificador incorrecto', () {
      expect(validarRut('12.345.678-9'), isFalse);
    });

    test('rechaza textos demasiado cortos o sin cuerpo numérico', () {
      expect(validarRut(''), isFalse);
      expect(validarRut('5'), isFalse);
      expect(validarRut('K'), isFalse);
    });

    test('acepta el RUT sin formato', () {
      expect(validarRut('123456785'), isTrue);
    });
  });
}
