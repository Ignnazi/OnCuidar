import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/categorias.dart';

void main() {
  test('los filtros no incluyen Checklist', () {
    expect(etiquetasFiltro, ['Todos', 'Videos', 'Guías', 'Infografías']);
  });

  test('Guías y PDFs se etiquetan igual como Guía', () {
    expect(etiquetaCategoria('Guías'), 'Guía');
    expect(etiquetaCategoria('PDFs'), 'Guía');
    expect(etiquetaCategoria('Infografías'), 'Infografía');
    expect(etiquetaCategoria('Videos'), 'Video');
  });

  test('el filtro Guías agrupa guías y PDFs', () {
    expect(coincideFiltro('Guías', 'Guías'), isTrue);
    expect(coincideFiltro('Guías', 'PDFs'), isTrue);
    expect(coincideFiltro('Guías', 'Infografías'), isFalse);
    expect(coincideFiltro('Infografías', 'Infografías'), isTrue);
  });
}
