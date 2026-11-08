import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/historial/datos/formato_exportacion.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/paciente.dart';

void main() {
  test('la ficha incluye todos los datos guardados del cuidador', () {
    final bloques = bloquesPacienteYCuidador(
      null,
      cuidadorParaExportar({
        'nombre': ' Ana Torres ',
        'relacion': 'Madre',
        'telefono': '+56 9 1234 5678',
        'correo': 'ana@correo.cl',
        'direccion': 'Av. Siempre Viva 123',
        'correoRespaldo': 'otro@correo.cl',
      }),
    );

    expect(bloques.single.titulo, 'CUIDADOR');
    expect(bloques.single.filas, [
      ('Nombre', 'Ana Torres'),
      ('Parentesco', 'Madre'),
      ('Teléfono', '+56 9 1234 5678'),
      ('Correo', 'ana@correo.cl'),
      ('Dirección', 'Av. Siempre Viva 123'),
    ]);
  });

  test('los datos vacíos del cuidador no aparecen en la ficha', () {
    final bloques = bloquesPacienteYCuidador(
      null,
      cuidadorParaExportar({
        'nombre': 'Ana',
        'telefono': '  ',
        'relacion': null,
      }),
    );
    expect(bloques.single.filas, [('Nombre', 'Ana')]);
    expect(bloquesPacienteYCuidador(null, cuidadorParaExportar(null)), isEmpty);
  });

  test('la ficha del paciente incluye RUT y fecha de nacimiento', () {
    final bloques = bloquesPacienteYCuidador(
      Paciente(
        id: 'p',
        nombreCompleto: 'Paciente Test',
        rut: '123456785',
        fechaNacimiento: DateTime(2018, 3, 4),
        diagnostico: 'LLA',
        creadoEn: DateTime(2026, 1, 1),
      ),
      null,
    );
    final filas = bloques.single.filas;
    expect(filas.first, ('Nombre', 'Paciente Test'));
    expect(filas, contains(('RUT', '12.345.678-5')));
    expect(filas.map((f) => f.$1), contains('Nacimiento'));
  });
}
