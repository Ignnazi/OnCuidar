import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/biblioteca/pantalla_video.dart';
import 'package:oncuidar/caracteristicas/biblioteca/widgets/tarjeta_material.dart';
import 'package:oncuidar/core/proveedores/proveedores.dart';
import 'package:oncuidar/core/servicios/servicio_cache_contenido.dart';
import 'package:oncuidar/modelos/material_educativo.dart';
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
  Future<bool> archivoDescargado(String url) async =>
      descargados.contains(url);

  @override
  Future<void> eliminar(String url) async {
    descargados.remove(url);
  }
}

MaterialEducativo _material({
  required String id,
  required String category,
  bool esDescargado = false,
  String? thumbnailUrl,
}) => MaterialEducativo(
  id: id,
  title: 'Material de prueba',
  category: category,
  topic: 'Tema de prueba',
  body: 'Cuerpo de prueba.',
  fileUrl: esDescargado || category == 'Videos' || category == 'Guías'
      ? 'https://firebasestorage.googleapis.com/v0/b/oncuidar-v1.firebasestorage.app/o/prueba?alt=media'
      : null,
  fileType: esDescargado && category == 'Guías' ? 'pdf' : null,
  fileSizeBytes: esDescargado ? 1500000 : null,
  thumbnailUrl: thumbnailUrl,
  createdAt: DateTime.utc(2026, 1, 1),
);

Widget _tarjeta(
  MaterialEducativo material, {
  bool esFavorito = false,
  bool descargado = false,
  VoidCallback? alTocar,
  VoidCallback? alAlternarFavorito,
  _CacheFalso? cache,
}) {
  return ProviderScope(
    overrides: [
      servicioCacheContenidoProvider.overrideWithValue(
        cache ?? _CacheFalso(),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: TarjetaMaterial(
          material: material,
          esFavorito: esFavorito,
          descargado: descargado,
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
      await guardarAvanceVideo('/videos/b.mp4', const Duration(milliseconds: 900));
      expect(await leerAvanceVideo('/videos/b.mp4'), 0);
    });

    test('cada video mantiene su propio avance', () async {
      SharedPreferences.setMockInitialValues({});
      await guardarAvanceVideo('/videos/c.mp4', const Duration(seconds: 90));
      expect(await leerAvanceVideo('/videos/c.mp4'), 90000);
      expect(await leerAvanceVideo('/videos/d.mp4'), 0);
    });
  });

  group('TarjetaMaterial', () {
    testWidgets('un video muestra insignia y botón de reproducción', (tester) async {
      await tester.pumpWidget(
        _tarjeta(_material(id: 'v', category: 'Videos')),
      );

      expect(find.text('Video'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.text('Material de prueba'), findsOneWidget);
      expect(find.text('Tema de prueba'), findsOneWidget);
    });

    testWidgets('un contenido de texto no muestra botón de reproducción', (
      tester,
    ) async {
      await tester.pumpWidget(
        _tarjeta(_material(id: 'c', category: 'Checklist')),
      );

      expect(find.text('Checklist'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
      expect(find.byIcon(Icons.checklist_rounded), findsOneWidget);
    });

    testWidgets('muestra el indicador de descarga solo cuando está descargado', (
      tester,
    ) async {
      final material = _material(id: 'g', category: 'Guías');
      await tester.pumpWidget(_tarjeta(material));
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);

      final descargado = _material(
        id: 'g',
        category: 'Guías',
        esDescargado: true,
      );
      await tester.pumpWidget(_tarjeta(descargado, descargado: true));
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('el favorito alterna el ícono y llama al callback', (tester) async {
      var vezAlternado = 0;
      await tester.pumpWidget(
        _tarjeta(
          _material(id: 'c', category: 'Checklist'),
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
          _material(id: 'c', category: 'Checklist'),
          alTocar: () => vezTocado++,
        ),
      );

      await tester.tap(
        find.byKey(const Key('miniaturaTarjetaMaterial')),
      );
      await tester.pump();

      expect(vezTocado, 1);
    });

    testWidgets('tocar la zona blanca no invoca alTocar', (tester) async {
      var vezTocado = 0;
      await tester.pumpWidget(
        _tarjeta(
          _material(id: 'c', category: 'Checklist'),
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
            category: 'Videos',
            thumbnailUrl: 'https://localhost/miniatura.png',
          ),
          cache: _CacheFalso()
            ..fallar.add('https://localhost/miniatura.png'),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.ondemand_video_rounded), findsOneWidget);
    });

    testWidgets('una miniatura por red se muestra desde la caché', (
      tester,
    ) async {
      final cache = _CacheFalso();
      await tester.pumpWidget(
        _tarjeta(
          _material(
            id: 'v',
            category: 'Videos',
            thumbnailUrl: _urlMiniatura,
          ),
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