import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/biblioteca/datos/proveedores_biblioteca.dart';
import 'package:oncuidar/caracteristicas/biblioteca/datos/servicio_cache_contenido.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/material_educativo.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/widgets/tarjeta_material.dart';

const _urlMiniatura = 'http://localhost:8080/archivos/miniaturas/prueba.jpg';

class _CacheFalso implements ServicioCacheContenido {
  final Set<String> descargados = {};
  final Set<String> fallar = {};

  @override
  Future<File?> archivoEnCache(String url) async =>
      descargados.contains(url) ? File(url) : null;

  @override
  Future<File> descargar(
    String url, {
    int? tamanoBytes,
    void Function(int descargado, int? total)? alProgresar,
  }) async {
    if (fallar.contains(url)) throw Exception('descarga fallida');
    descargados.add(url);
    return File(url);
  }

  @override
  Future<File> redescargar(String url) => descargar(url);

  @override
  Future<bool> archivoDescargado(String url) async => descargados.contains(url);

  @override
  Future<void> eliminar(String url) async {
    descargados.remove(url);
  }
}

MaterialEducativo _material({
  required String id,
  required String categoria,
  bool esDescargado = false,
  String? urlMiniatura,
}) => MaterialEducativo(
  id: id,
  titulo: 'Material de prueba',
  categoria: categoria,
  tema: 'Tema de prueba',
  cuerpo: 'Cuerpo de prueba.',
  urlArchivo: esDescargado || categoria == 'Videos' || categoria == 'Guías'
      ? 'http://localhost:8080/archivos/prueba.pdf'
      : null,
  tipoArchivo: esDescargado && categoria == 'Guías' ? 'pdf' : null,
  tamanoBytes: esDescargado ? 1500000 : null,
  urlMiniatura: urlMiniatura,
  creadoEn: DateTime.utc(2026, 1, 1),
);

Widget _tarjeta(
  MaterialEducativo material, {
  bool esFavorito = false,
  VoidCallback? alTocar,
  VoidCallback? alAlternarFavorito,
  _CacheFalso? cache,
}) {
  return ProviderScope(
    overrides: [
      servicioCacheContenidoProvider.overrideWithValue(cache ?? _CacheFalso()),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: TarjetaMaterial(
          material: material,
          esFavorito: esFavorito,
          alTocar: alTocar ?? () {},
          alAlternarFavorito: alAlternarFavorito ?? () {},
        ),
      ),
    ),
  );
}

void main() {
  group('TarjetaMaterial', () {
    Icon iconoDeTipo(WidgetTester tester) => tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const Key('iconoTipoMaterial')),
        matching: find.byType(Icon),
      ),
    );

    testWidgets('todos los tipos comparten la tarjeta con ícono de tipo', (
      tester,
    ) async {
      final esperados = {
        'Videos': (Icons.smart_display_rounded, Paleta.categoriaVideo),
        'Guías': (Icons.menu_book_rounded, Paleta.categoriaGuia),
        'PDFs': (Icons.menu_book_rounded, Paleta.categoriaGuia),
        'Infografías': (
          Icons.insert_chart_outlined_rounded,
          Paleta.categoriaInfografia,
        ),
      };
      for (final MapEntry(key: categoria, value: (icono, color))
          in esperados.entries) {
        await tester.pumpWidget(
          _tarjeta(_material(id: categoria, categoria: categoria)),
        );
        expect(find.byKey(const Key('iconoTipoMaterial')), findsOneWidget);
        expect(iconoDeTipo(tester).icon, icono, reason: categoria);
        expect(iconoDeTipo(tester).color, color, reason: categoria);
        expect(find.text('Material de prueba'), findsOneWidget);
        expect(find.text('Tema de prueba'), findsOneWidget);
        expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
      }
    });

    testWidgets('no hay insignia de texto; el tipo queda para lectores', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await tester.pumpWidget(
        _tarjeta(_material(id: 'i', categoria: 'Infografías')),
      );
      expect(find.text('Infografía'), findsNothing);
      expect(find.bySemanticsLabel('Infografía'), findsOneWidget);
      semantica.dispose();
    });

    testWidgets('sin imagen el reemplazo muestra el ícono del tipo', (
      tester,
    ) async {
      await tester.pumpWidget(
        _tarjeta(_material(id: 'i', categoria: 'Infografías')),
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('reemplazoMiniatura')),
          matching: find.byIcon(Icons.insert_chart_outlined_rounded),
        ),
        findsOneWidget,
      );
    });

    testWidgets('un video muestra el botón de reproducción', (tester) async {
      await tester.pumpWidget(
        _tarjeta(_material(id: 'v', categoria: 'Videos')),
      );

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.text('Material de prueba'), findsOneWidget);
      expect(find.text('Tema de prueba'), findsOneWidget);
    });

    testWidgets('un contenido de texto no muestra botón de reproducción', (
      tester,
    ) async {
      await tester.pumpWidget(_tarjeta(_material(id: 'c', categoria: 'Guías')));
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
    });

    testWidgets('un material descargado no muestra marca', (tester) async {
      await tester.pumpWidget(
        _tarjeta(_material(id: 'g', categoria: 'Guías', esDescargado: true)),
      );
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    });

    testWidgets('el favorito alterna el ícono y llama al callback', (
      tester,
    ) async {
      var vezAlternado = 0;
      await tester.pumpWidget(
        _tarjeta(
          _material(id: 'c', categoria: 'Guías'),
          alAlternarFavorito: () => vezAlternado++,
        ),
      );

      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);

      await tester.tap(find.byIcon(Icons.bookmark_border));
      await tester.pump();

      expect(vezAlternado, 1);
      expect(
        find.byIcon(Icons.bookmark_border),
        findsOneWidget,
        reason: 'el estado externo decide el ícono',
      );
    });

    testWidgets('tocar la miniatura invoca alTocar', (tester) async {
      var vezTocado = 0;
      await tester.pumpWidget(
        _tarjeta(
          _material(id: 'c', categoria: 'Guías'),
          alTocar: () => vezTocado++,
        ),
      );

      await tester.tap(find.byKey(const Key('miniaturaTarjetaMaterial')));
      await tester.pump();

      expect(vezTocado, 1);
    });

    testWidgets('tocar la zona blanca no invoca alTocar', (tester) async {
      var vezTocado = 0;
      await tester.pumpWidget(
        _tarjeta(
          _material(id: 'c', categoria: 'Guías'),
          alTocar: () => vezTocado++,
        ),
      );

      await tester.tap(find.text('Material de prueba'));
      await tester.pump();

      expect(vezTocado, 0);
    });

    testWidgets('una miniatura que falla muestra el reemplazo sin excepción', (
      tester,
    ) async {
      await tester.pumpWidget(
        _tarjeta(
          _material(
            id: 'v',
            categoria: 'Videos',
            urlMiniatura: 'https://localhost/miniatura.png',
          ),
          cache: _CacheFalso()..fallar.add('https://localhost/miniatura.png'),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('reemplazoMiniatura')), findsOneWidget);
    });

    testWidgets('una miniatura por red se muestra desde la caché', (
      tester,
    ) async {
      final cache = _CacheFalso();
      await tester.pumpWidget(
        _tarjeta(
          _material(id: 'v', categoria: 'Videos', urlMiniatura: _urlMiniatura),
          cache: cache,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(cache.descargados, contains(_urlMiniatura));
      final imagen = tester.widget<Image>(find.byType(Image).first);
      expect(imagen.image, isA<FileImage>());
    });
  });
}
