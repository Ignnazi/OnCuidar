// ignore_for_file: depend_on_referenced_packages

import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/core/servicios/servicio_cache_contenido.dart';

class _GestorFalso implements CacheManager {
  _GestorFalso(this.carpeta);

  final io.Directory carpeta;
  final guardados = <String, File>{};
  int descargas = 0;

  @override
  Future<FileInfo?> getFileFromCache(
    String key, {
    bool ignoreMemCache = false,
  }) async {
    final archivo = guardados[key];
    if (archivo == null) return null;
    return FileInfo(archivo, FileSource.Cache, DateTime(2100), key);
  }

  @override
  Future<File> getSingleFile(
    String url, {
    String? key,
    Map<String, String>? headers,
  }) async {
    descargas++;
    final archivo = const LocalFileSystem().file(
      '${carpeta.path}/${guardados.length}.bin',
    );
    await archivo.writeAsBytes([1, 2, 3]);
    guardados[key ?? url] = archivo;
    return archivo;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late io.Directory carpeta;
  late _GestorFalso gestor;
  late ServicioCacheContenido servicio;

  setUp(() async {
    carpeta = await io.Directory.systemTemp.createTemp('cache_contenido');
    gestor = _GestorFalso(carpeta);
    servicio = ServicioCacheContenido(gestor: gestor);
  });

  tearDown(() async {
    if (await carpeta.exists()) await carpeta.delete(recursive: true);
  });

  test('la primera vez descarga y la segunda reutiliza el archivo', () async {
    final primero = await servicio.descargar('https://sitio.cl/video.mp4');
    final segundo = await servicio.descargar('https://sitio.cl/video.mp4');

    expect(gestor.descargas, 1);
    expect(segundo.path, primero.path);
  });

  test(
    'repetir la sincronización de varios archivos no descarga de nuevo',
    () async {
      final urls = [
        'https://sitio.cl/video.mp4',
        'https://sitio.cl/guia.pdf',
        'https://sitio.cl/info.png',
      ];
      for (final url in urls) {
        await servicio.descargar(url);
      }
      expect(gestor.descargas, 3);

      for (var vuelta = 0; vuelta < 3; vuelta++) {
        for (final url in urls) {
          await servicio.descargar(url);
        }
      }
      expect(gestor.descargas, 3, reason: 'ya estaban guardados');
    },
  );

  test(
    'si el archivo guardado desapareció del disco se vuelve a bajar',
    () async {
      await servicio.descargar('https://sitio.cl/video.mp4');
      await gestor.guardados['https://sitio.cl/video.mp4']!.delete();

      await servicio.descargar('https://sitio.cl/video.mp4');

      expect(gestor.descargas, 2);
    },
  );
}
