import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/autenticacion/dominio/validaciones_registro.dart';

void main() {
  group('Campos obligatorios', () {
    test('vacío o con solo espacios muestra el mensaje', () {
      expect(
        validarObligatorio(null, 'Ingresa tu nombre'),
        'Ingresa tu nombre',
      );
      expect(
        validarObligatorio('   ', 'Ingresa tu nombre'),
        'Ingresa tu nombre',
      );
    });

    test('con texto no hay error', () {
      expect(validarObligatorio('Ana', 'Ingresa tu nombre'), isNull);
    });
  });

  group('Correo', () {
    test('vacío pide el correo', () {
      expect(validarCorreo(''), 'Ingresa tu correo');
    });

    test('con formato inválido se rechaza', () {
      expect(validarCorreo('ana@'), 'Ingresa un correo válido');
      expect(validarCorreo('ana.correo.cl'), 'Ingresa un correo válido');
    });

    test('válido, aun con espacios alrededor, se acepta', () {
      expect(validarCorreo('  ana@correo.cl '), isNull);
    });

    test('opcional y vacío se acepta', () {
      expect(validarCorreo('', opcional: true), isNull);
    });
  });

  group('RUT del paciente', () {
    test('vacío pide el RUT', () {
      expect(validarRutPaciente(''), 'Ingresa el RUT del paciente');
    });

    test('con dígito verificador incorrecto se rechaza', () {
      expect(validarRutPaciente('12.345.678-0'), 'RUT no válido');
    });

    test('válido se acepta', () {
      expect(validarRutPaciente('12.345.678-5'), isNull);
    });
  });

  group('Contraseña', () {
    test('menos de 6 caracteres se rechaza', () {
      expect(validarContrasena('12345'), 'Mínimo 6 caracteres');
    });

    test('la confirmación debe coincidir', () {
      expect(
        validarConfirmacion('otra123', 'secreto123'),
        'Las contraseñas no coinciden',
      );
      expect(validarConfirmacion('secreto123', 'secreto123'), isNull);
    });
  });

  group('Edad', () {
    test('fuera de 0 a 120 o no numérica se rechaza', () {
      expect(validarEdad('130'), 'Edad no válida');
      expect(validarEdad('diez'), 'Edad no válida');
      expect(validarEdad('8'), isNull);
    });
  });
}
