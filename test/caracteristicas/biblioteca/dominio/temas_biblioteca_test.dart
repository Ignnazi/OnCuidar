import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/material_educativo.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/temas_biblioteca.dart';

MaterialEducativo _material(String id, String categoria, String tema) =>
    MaterialEducativo(
      id: id,
      titulo: id,
      categoria: categoria,
      tema: tema,
      cuerpo: '',
      creadoEn: DateTime.utc(2026, 1, 1),
    );

void main() {
  final catalogo = [
    _material('a', 'Videos', 'Cuidados Paliativos'),
    _material('b', 'Guías', 'Alimentación y cuidados'),
    _material('c', 'PDFs', ' cuidados paliativos '),
    _material('d', 'Videos', ''),
    _material('e', 'Infografías', 'Conociendo la quimioterapia'),
  ];

  test('temas distintos: sin vacíos ni repetidos, en orden alfabético', () {
    expect(temasDistintos(catalogo), [
      'Alimentación y cuidados',
      'Conociendo la quimioterapia',
      'Cuidados Paliativos',
    ]);
  });

  test('tipo y tema se combinan; «Todas» no filtra por tema', () {
    String ids(String filtro, String tema) => filtrarPorTipoYTema(
      catalogo,
      filtro: filtro,
      tema: tema,
    ).map((m) => m.id).join(',');

    expect(ids('Todos', 'Cuidados Paliativos'), 'a,c');
    expect(ids('Guías', 'Cuidados Paliativos'), 'c');
    expect(ids('Videos', temaTodas), 'a,d');
    expect(ids('Infografías', 'Cuidados Paliativos'), '');
  });

  test('un tema que ya no existe vuelve a «Todas»', () {
    expect(temaVigente('Otro', ['A']), temaTodas);
    expect(temaVigente('A', ['A']), 'A');
  });
}
