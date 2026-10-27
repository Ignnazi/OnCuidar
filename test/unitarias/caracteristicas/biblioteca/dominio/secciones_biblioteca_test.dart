import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/material_educativo.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/secciones_biblioteca.dart';

MaterialEducativo _material(String id, String categoria) => MaterialEducativo(
  id: id,
  titulo: id,
  categoria: categoria,
  tema: '',
  cuerpo: '',
  creadoEn: DateTime.utc(2026, 1, 1),
);

List<String> _resumen(List<SeccionBiblioteca> secciones) => [
  for (final s in secciones)
    '${s.titulo}: ${s.materiales.map((m) => m.id).join(', ')}',
];

void main() {
  test('ordena videos, guías e infografías aunque lleguen mezclados', () {
    final secciones = agruparPorSeccion([
      _material('inf-1', 'Infografías'),
      _material('guia-1', 'Guías'),
      _material('video-1', 'Videos'),
      _material('pdf-1', 'PDFs'),
      _material('video-2', 'Videos'),
    ]);

    expect(_resumen(secciones), [
      'Videos: video-1, video-2',
      'Guías: guia-1, pdf-1',
      'Infografías: inf-1',
    ]);
  });

  test('omite las secciones vacías', () {
    final secciones = agruparPorSeccion([
      _material('inf-1', 'Infografías'),
      _material('video-1', 'Videos'),
    ]);
    expect(secciones.map((s) => s.titulo), ['Videos', 'Infografías']);
  });

  test('sin materiales no hay secciones', () {
    expect(agruparPorSeccion(const []), isEmpty);
  });

  test('una categoría desconocida va al final en Otros', () {
    final secciones = agruparPorSeccion([
      _material('raro-1', 'Podcasts'),
      _material('guia-1', 'Guías'),
    ]);
    expect(_resumen(secciones), ['Guías: guia-1', 'Otros: raro-1']);
  });
}
