import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/preguntas_frecuentes/dominio/catalogo_preguntas.dart';

void main() {
  test('cada pregunta tiene un id único, su respuesta y su fuente', () {
    final ids = preguntasFrecuentes.map((p) => p.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    for (final p in preguntasFrecuentes) {
      expect(p.respuesta, isNotEmpty, reason: p.id);
      expect(p.fuente, isNotNull, reason: p.id);
      expect(p.claves, isNotEmpty, reason: p.id);
    }
  });

  test('las categorías siguen el orden del material', () {
    expect(categoriasDePreguntas(), [
      'Fiebre y urgencias',
      'Sangrado',
      'Catéter',
      'Alimentación',
      'Molestias digestivas',
      'Efectos del tratamiento',
      'Dolor',
      'Cuidados en casa',
      'Apoyo',
    ]);
  });

  test('la fiebre es urgencia desde 38 °C', () {
    final fiebre = preguntasFrecuentes.firstWhere((p) => p.id == 'fiebre');
    expect(fiebre.respuesta, contains('igual o mayor a 38 °C'));
  });

  test('al empezar el chat sugiere una pregunta por categoría', () {
    final destacadas = preguntasDestacadas();
    expect(
      destacadas.map((p) => p.categoria).toList(),
      categoriasDePreguntas(),
    );
    expect(destacadas.first.id, 'fiebre');
  });

  test('el seguimiento prioriza la categoría de la conversación', () {
    final sugeridas = sugerenciasDeSeguimiento(
      preguntasFrecuentes.where((p) => p.id != 'cateter-cuidados').toList(),
      'Catéter',
    );
    expect(sugeridas, hasLength(3));
    expect(sugeridas.take(2).map((p) => p.id), [
      'cateter-bano',
      'cateter-sale',
    ]);
  });

  test('sin categoría el seguimiento toma las primeras disponibles', () {
    final sugeridas = sugerenciasDeSeguimiento(preguntasFrecuentes, null);
    expect(sugeridas.map((p) => p.id), [
      'fiebre',
      'cuando-urgencia',
      'efectos-quimio-preocupantes',
    ]);
  });

  test('la pantalla de frecuentes muestra solo las más consultadas', () {
    final frecuentes = preguntasMasFrecuentes();
    expect(frecuentes.length, lessThan(preguntasFrecuentes.length));
    expect(frecuentes.map((p) => p.id), [
      'fiebre',
      'cuando-urgencia',
      'efectos-quimio-preocupantes',
      'petequias',
      'cateter-cuidados',
      'cateter-bano',
      'alimentos-recomendados',
      'alimentos-evitar',
      'no-quiere-comer',
      'agua',
      'nauseas-cuidados',
      'mucositis',
      'dolor-escalas',
      'mascotas',
      'vacunas',
      'apoyo',
    ]);
    expect(categoriasDe(frecuentes), [
      'Fiebre y urgencias',
      'Sangrado',
      'Catéter',
      'Alimentación',
      'Molestias digestivas',
      'Dolor',
      'Cuidados en casa',
      'Apoyo',
    ]);
  });

  test('al empezar el chat sugiere 3 al azar de categorías distintas', () {
    final una = preguntasIniciales(Random(1));
    expect(una, hasLength(3));
    expect(una.map((p) => p.categoria).toSet(), hasLength(3));
    expect(
      preguntasIniciales(Random(1)).map((p) => p.id),
      una.map((p) => p.id),
    );
    final varias = {
      for (var semilla = 0; semilla < 20; semilla++)
        preguntasIniciales(Random(semilla)).map((p) => p.id).join(),
    };
    expect(varias.length, greaterThan(1));
  });

  test('ninguna respuesta usa punto y coma', () {
    for (final p in preguntasFrecuentes) {
      expect(p.respuesta, isNot(contains(';')), reason: p.id);
      expect(p.pregunta, isNot(contains(';')), reason: p.id);
    }
    expect(mensajeSinCoincidencia, isNot(contains(';')));
  });
}
