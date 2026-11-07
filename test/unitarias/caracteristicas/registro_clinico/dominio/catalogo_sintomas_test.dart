import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/catalogo_sintomas.dart';

void main() {
  test('los grupos siguen el orden de la lista de enfermería', () {
    expect(gruposSintomas, [
      'Síntomas generales y sistémicos',
      'Cabeza, piel y mucosas',
      'Sistema digestivo y nutrición',
      'Dolor y sistema músculo esquelético',
      'Sistema nervioso y neurosensorial',
      'Vasculares y renales',
    ]);
    expect(filtrosSintomas, ['Todos', 'Escala', ...gruposSintomas]);
  });

  test('cada grupo trae sus síntomas', () {
    expect(sintomasDelGrupo('Síntomas generales y sistémicos'), [
      'Fatiga',
      'Sudoración',
      'Somnolencia',
      'Pérdida de peso',
      'Edema (retención de líquidos en piernas, brazos, cara u otras zonas)',
    ]);
    expect(sintomasDelGrupo('Vasculares y renales'), [
      'Hematomas (moretones inusuales)',
      'Disuria (dolor al orinar)',
    ]);
    expect(catalogoSintomasPediatricos, hasLength(28));
  });

  test('un síntoma que también está en la escala no se duplica', () {
    final nombres = catalogoUnificado.map((s) => s.nombre).toList();
    expect(nombres.where((n) => n == 'Somnolencia'), hasLength(1));
    expect(nombres.toSet(), hasLength(nombres.length));
  });
}
