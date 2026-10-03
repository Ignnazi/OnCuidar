import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/biblioteca/datos/proveedores_biblioteca.dart';
import 'package:oncuidar/caracteristicas/biblioteca/datos/servicio_cache_contenido.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/material_educativo.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/pantalla_video.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/widgets/tarjeta_material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _urlMiniatura =
    'https://firebasestorage.googleapis.com/v0/b/oncuidar-v1.firebasestorage.app/o/miniaturas%2Fprueba.png?alt=media';

class _CacheFalso implements ServicioCacheContenido {
  final Set<String> descargados = {};
  final Set<String> fallar = {};

  @override
  Future<File?> archivoEnCache(String url) async =>
      descargados.contains(url) ? File(url) : null;

  @override
  Future<File> descargar(String url) async {
    if (fallar.contains(url)) throw Exception('descarga fallida');
    descargados.add(url);
    return File(url);
  }

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
      ? 'https://firebasestorage.googleapis.com/v0/b/oncuidar-v1.firebasestorage.app/o/prueba?alt=media'
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
  group('formatearDuracion', () {
    test('formatea cero, minutos y horas', () {
      expect(formatearDuracion(Duration.zero), '00:00');
      expect(formatearDuracion(const Duration(seconds: 65)), '01:05');
      expect(formatearDuracion(const Duration(seconds: 3599)), '59:59');
      expect(formatearDuracion(const Duration(seconds: 3661)), '1:01:01');
    });
  });

  group('Avance persistente del video (HU-21)', () {
    test('la clave es estable por ruta', () {
      expect(
        claveAvanceVideo('/videos/uno.mp4'),
        claveAvanceVideo('/videos/uno.mp4'),
      );
      expect(
        claveAvanceVideo('/videos/uno.mp4'),
        isNot(claveAvanceVideo('/videos/dos.mp4')),
      );
    });

    test('guarda y devuelve el avance entre sesiones', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await leerAvanceVideo('/videos/a.mp4'), 0);

      await guardarAvanceVideo(
        '/videos/a.mp4',
        const Duration(minutes: 4, seconds: 30),
      );
      expect(await leerAvanceVideo('/videos/a.mp4'), 270000);
    });

    test('posiciones triviales no se guardan', () async {
      SharedPreferences.setMockInitialValues({});
      await guardarAvanceVideo(
        '/videos/b.mp4',
        const Duration(milliseconds: 900),
      );
      expect(await leerAvanceVideo('/videos/b.mp4'), 0);
    });

    test('la pantalla retoma desde el avance guardado con su id', () async {
      SharedPreferences.setMockInitialValues({});
      await guardarAvanceVideo('video-1', const Duration(seconds: 30));
      expect(
        await posicionParaRetomar('video-1', const Duration(minutes: 5)),
        const Duration(seconds: 30),
      );
      expect(
        await posicionParaRetomar('video-2', const Duration(minutes: 5)),
        isNull,
      );
    });

    test('si quedó casi al final reinicia desde el principio', () async {
      SharedPreferences.setMockInitialValues({});
      await guardarAvanceVideo('video-1', const Duration(seconds: 299));
      expect(
        await posicionParaRetomar('video-1', const Duration(minutes: 5)),
        isNull,
      );
    });

    test('cada video mantiene su propio avance', () async {
      SharedPreferences.setMockInitialValues({});
      await guardarAvanceVideo('/videos/c.mp4', const Duration(seconds: 90));
      expect(await leerAvanceVideo('/videos/c.mp4'), 90000);
      expect(await leerAvanceVideo('/videos/d.mp4'), 0);
    });
  });

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

    testWidgets('un PDF se ve igual que una guía', (tester) async {
      await tester.pumpWidget(_tarjeta(_material(id: 'p', categoria: 'PDFs')));
      expect(iconoDeTipo(tester).icon, Icons.menu_book_rounded);
      expect(estiloTipoMaterial('PDFs'), estiloTipoMaterial('Guías'));
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
