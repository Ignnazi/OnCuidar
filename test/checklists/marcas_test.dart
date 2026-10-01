import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/modelos/checklist_usuario.dart';

void main() {
  group('filtrarMarcas', () {
    test('descarta los índices fuera del rango de ítems', () {
      expect(filtrarMarcas([-2, 0, 3, 9], 3), [0]);
    });

    test('ordena y elimina duplicados', () {
      expect(filtrarMarcas([2, 0, 2, 1], 3), [0, 1, 2]);
    });

    test('una lista sin ítems se queda sin marcas', () {
      expect(filtrarMarcas([0, 1], 0), isEmpty);
    });

    test('no puede superar el total de ítems', () {
      final marcas = filtrarMarcas([0, 1, 2, 3, 4], 2);
      expect(marcas, [0, 1]);
      expect(marcas.length, lessThanOrEqualTo(2));
    });
  });

  group('recalcularMarcas', () {
    test('conserva la marca cuando el ítem no cambió de posición', () {
      expect(
        recalcularMarcas(
          itemsAnteriores: ['Preparar mochila', 'Llevar carnet'],
          marcasAnteriores: [1],
          itemsNuevos: ['Preparar mochila', 'Llevar carnet'],
        ),
        [1],
      );
    });

    test('un ítem borrado en el medio desplaza las marcas siguientes', () {
      expect(
        recalcularMarcas(
          itemsAnteriores: ['Agua', 'Cena', 'Medicamento'],
          marcasAnteriores: [2],
          itemsNuevos: ['Agua', 'Cena'],
        ),
        isEmpty,
        reason: 'el ítem marcado fue el que se eliminó',
      );
      expect(
        recalcularMarcas(
          itemsAnteriores: ['Agua', 'Cena', 'Medicamento'],
          marcasAnteriores: [2],
          itemsNuevos: ['Agua', 'Medicamento'],
        ),
        [1],
      );
    });

    test('un ítem renombrado pierde la marca: el texto ya no coincide', () {
      expect(
        recalcularMarcas(
          itemsAnteriores: ['Agua'],
          marcasAnteriores: [0],
          itemsNuevos: ['Agua con gas'],
        ),
        isEmpty,
      );
    });

    test('agregar un ítem sin marcar no altera las marcas existentes', () {
      expect(
        recalcularMarcas(
          itemsAnteriores: ['Agua', 'Cena'],
          marcasAnteriores: [1],
          itemsNuevos: ['Agua', 'Cena', 'Pasta de dientes'],
        ),
        [1],
      );
    });

    test('los espacios sobrantes no impiden reconocer el ítem', () {
      expect(
        recalcularMarcas(
          itemsAnteriores: ['Agua'],
          marcasAnteriores: [0],
          itemsNuevos: ['  Agua  '],
        ),
        [0],
      );
    });

    test('el resultado nunca supera el total de ítems nuevos', () {
      final marcas = recalcularMarcas(
        itemsAnteriores: ['Agua', 'Agua'],
        marcasAnteriores: [0, 1, 0],
        itemsNuevos: ['Agua'],
      );
      expect(marcas, [0]);
      expect(marcas.length, lessThanOrEqualTo(1));
    });

    test('las marcas anteriores fuera de rango se ignoran', () {
      expect(
        recalcularMarcas(
          itemsAnteriores: ['Agua'],
          marcasAnteriores: [7],
          itemsNuevos: ['Agua', 'Cena'],
        ),
        isEmpty,
      );
    });
  });

  group('ChecklistUsuario', () {
    ChecklistUsuario lista(List<String> items, List<int> marcas) =>
        ChecklistUsuario(
          id: 'l1',
          titulo: 'Rutina diaria',
          items: items,
          indicesMarcados: marcas,
          creadoEn: DateTime(2026, 9, 30),
        );

    test('marcasValidas acota marcas corruptas al total de ítems', () {
      expect(lista(['Agua'], [0, 5, 5]).marcasValidas, [0]);
    });

    test('completada solo cuando todas las marcas son válidas', () {
      expect(lista(['Agua', 'Cena'], [0, 1]).completada, isTrue);
      expect(lista(['Agua', 'Cena'], [0, 1, 9]).completada, isTrue);
      expect(lista(['Agua', 'Cena'], [0]).completada, isFalse);
      expect(lista(const [], const []).completada, isFalse);
    });

    test('completadaEn se serializa y se relee en claro', () {
      final fecha = DateTime(2026, 9, 30, 11, 30);
      final mapa = lista(['Agua'], [0]).toMap();
      expect(mapa.containsKey('completadaEn'), isFalse);

      final conFecha = ChecklistUsuario(
        id: 'l1',
        titulo: 'Rutina diaria',
        items: const ['Agua'],
        indicesMarcados: const [0],
        creadoEn: DateTime(2026, 9, 30),
        completadaEn: fecha,
      ).toMap();
      expect(conFecha['completadaEn'], fecha.toIso8601String());

      final leida = ChecklistUsuario.fromMap('l1', conFecha);
      expect(leida.completadaEn, isNotNull);
      expect(leida.completada, isTrue);
    });
  });
}