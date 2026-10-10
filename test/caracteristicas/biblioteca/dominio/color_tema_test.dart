import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/color_tema.dart';

void main() {
  const conocidos = [
    'Alimentación',
    'Catéter',
    'Efectos secundarios',
    'El cáncer',
    'Mucosas',
    'Paliativos',
    'Quimioterapia',
    'Salud mental',
    'Signos de alarma',
    'Unidad oncológica',
  ];

  test(
    'los 10 temas conocidos tienen índices distintos y dentro de la paleta',
    () {
      final indices = conocidos.map(indiceColorTema).toSet();
      expect(indices.length, 10);
      expect(indices.every((i) => i >= 0 && i < cantidadAcentosTema), isTrue);
    },
  );

  test('un tema desconocido da siempre el mismo índice', () {
    final primero = indiceColorTema('Nutrición en casa');
    expect(indiceColorTema('Nutrición en casa'), primero);
    expect(primero, inInclusiveRange(0, cantidadAcentosTema - 1));
  });

  test('ignora tildes, mayúsculas y espacios sobrantes', () {
    expect(indiceColorTema('  CATETER '), indiceColorTema('Catéter'));
    expect(
      indiceColorTema('Rehabilitación  Física'),
      indiceColorTema('rehabilitacion fisica'),
    );
  });
}
