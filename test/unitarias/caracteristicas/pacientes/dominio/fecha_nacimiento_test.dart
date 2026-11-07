import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/fecha_nacimiento.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/paciente.dart';

final _hoy = DateTime(2026, 11, 7);

void main() {
  group('edad en años', () {
    test('cuenta los años cumplidos', () {
      expect(edadEnAnios(DateTime(2018, 3, 10), _hoy), 8);
    });

    test('antes del cumpleaños de este año tiene uno menos', () {
      expect(edadEnAnios(DateTime(2018, 12, 1), _hoy), 7);
      expect(edadEnAnios(DateTime(2018, 11, 8), _hoy), 7);
    });

    test('el día del cumpleaños ya los cumplió', () {
      expect(edadEnAnios(DateTime(2018, 11, 7), _hoy), 8);
    });

    test('un bebé de meses tiene 0 años', () {
      expect(edadEnAnios(DateTime(2026, 4, 1), _hoy), 0);
    });
  });

  group('leer y escribir la fecha', () {
    test('lee dd/mm/aaaa', () {
      expect(leerFechaNacimiento('10/03/2018'), DateTime(2018, 3, 10));
      expect(leerFechaNacimiento(' 1/3/2018 '), DateTime(2018, 3, 1));
    });

    test('rechaza fechas que no existen o mal escritas', () {
      expect(leerFechaNacimiento('31/02/2018'), isNull);
      expect(leerFechaNacimiento('2018-03-10'), isNull);
      expect(leerFechaNacimiento('diez'), isNull);
    });

    test('escribe con ceros a la izquierda', () {
      expect(formatearFechaNacimiento(DateTime(2018, 3, 1)), '01/03/2018');
    });
  });

  group('validación', () {
    test('mensajes de error', () {
      expect(
        validarFechaNacimiento('', hoy: _hoy),
        'Ingresa la fecha de nacimiento',
      );
      expect(
        validarFechaNacimiento('10-03-2018', hoy: _hoy),
        'Usa el formato dd/mm/aaaa',
      );
      expect(
        validarFechaNacimiento('08/11/2026', hoy: _hoy),
        'La fecha no puede ser futura',
      );
      expect(
        validarFechaNacimiento('01/01/1900', hoy: _hoy),
        'Revisa el año de nacimiento',
      );
      expect(validarFechaNacimiento('10/03/2018', hoy: _hoy), isNull);
    });
  });

  group('edad actual del paciente', () {
    Paciente paciente({int? edad, DateTime? nacimiento}) => Paciente(
      id: 'p1',
      nombreCompleto: 'Tomás',
      edad: edad,
      fechaNacimiento: nacimiento,
      creadoEn: DateTime(2026),
    );

    test('con fecha de nacimiento se calcula y no usa la edad guardada', () {
      final p = paciente(edad: 4, nacimiento: DateTime(2018, 3, 10));
      expect(p.edadAl(_hoy), 8);
    });

    test('sin fecha usa la edad que se registró antes', () {
      expect(paciente(edad: 4).edadAl(_hoy), 4);
    });

    test('sin ninguna de las dos no hay edad', () {
      expect(paciente().edadAl(_hoy), isNull);
    });
  });
}
