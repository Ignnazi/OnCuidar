import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oncuidar/caracteristicas/biblioteca/datos/proveedores_biblioteca.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/material_educativo.dart';

class DescargasContenidoNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void marcarDescargado(String url) {
    if (state.contains(url)) return;
    state = {...state, url};
  }
}

final contenidosDescargadosProvider =
    NotifierProvider<DescargasContenidoNotifier, Set<String>>(
      DescargasContenidoNotifier.new,
    );

class SincronizacionEstado {
  const SincronizacionEstado({
    this.activa = false,
    this.completadas = 0,
    this.total = 0,
    this.fallidas = 0,
    this.terminada = false,
  });

  final bool activa;
  final int completadas;
  final int total;
  final int fallidas;
  final bool terminada;

  bool get conErrores => fallidas > 0;

  double get progreso => total == 0 ? 0 : completadas / total;

  SincronizacionEstado copia({
    bool? activa,
    int? completadas,
    int? total,
    int? fallidas,
    bool? terminada,
  }) {
    return SincronizacionEstado(
      activa: activa ?? this.activa,
      completadas: completadas ?? this.completadas,
      total: total ?? this.total,
      fallidas: fallidas ?? this.fallidas,
      terminada: terminada ?? this.terminada,
    );
  }
}

const _tamanoLoteDescargas = 3;

Iterable<String> _urlsDelMaterial(MaterialEducativo material) sync* {
  final archivo = material.urlArchivo;
  if (archivo != null && archivo.isNotEmpty) yield archivo;
  final imagen = material.urlImagen;
  if (imagen != null && imagen.isNotEmpty && !imagen.startsWith('assets/')) {
    yield imagen;
  }
  final miniatura = material.urlMiniatura;
  if (miniatura != null &&
      miniatura.isNotEmpty &&
      !miniatura.startsWith('assets/')) {
    yield miniatura;
  }
}

class SincronizacionNotifier extends Notifier<SincronizacionEstado> {
  bool _enCurso = false;

  @override
  SincronizacionEstado build() => const SincronizacionEstado();

  Future<void> sincronizar(List<MaterialEducativo> contenidos) async {
    if (_enCurso) return;
    _enCurso = true;
    try {
      await _sincronizarContenido(contenidos);
    } finally {
      _enCurso = false;
    }
  }

  Future<void> sincronizarAlIniciarSesion() async {
    if (_enCurso) return;
    _enCurso = true;
    try {
      final cacheMetadata = ref.read(servicioCacheMetadataProvider);
      final (cacheados, marca) = await cacheMetadata.obtenerCatalogoCache();
      final cacheVigente =
          cacheados.isNotEmpty && cacheMetadata.esReciente(timestamp: marca);
      final List<MaterialEducativo> contenidos;
      if (cacheVigente) {
        contenidos = cacheados;
      } else {
        final repositorio = ref.read(repositorioBibliotecaProvider);
        contenidos = await repositorio
            .contenidoEducativoEnTiempoReal()
            .first
            .timeout(const Duration(seconds: 8));
      }
      await _sincronizarContenido(contenidos, guardarCatalogo: !cacheVigente);
    } catch (_) {
      state = const SincronizacionEstado(terminada: true, fallidas: 1);
    } finally {
      _enCurso = false;
    }
  }

  Future<void> _sincronizarContenido(
    List<MaterialEducativo> contenidos, {
    bool guardarCatalogo = true,
  }) async {
    final urls = <String>[
      for (final material in contenidos) ..._urlsDelMaterial(material),
    ];
    if (urls.isEmpty) {
      state = const SincronizacionEstado(terminada: true);
      return;
    }
    if (guardarCatalogo) {
      try {
        await ref
            .read(servicioCacheMetadataProvider)
            .guardarCatalogo(contenidos);
      } catch (_) {}
    }
    final cache = ref.read(servicioCacheContenidoProvider);
    state = SincronizacionEstado(activa: true, total: urls.length);
    var completadas = 0;
    var fallidas = 0;
    for (var inicio = 0; inicio < urls.length; inicio += _tamanoLoteDescargas) {
      final fin = (inicio + _tamanoLoteDescargas < urls.length)
          ? inicio + _tamanoLoteDescargas
          : urls.length;
      final lote = urls.sublist(inicio, fin);
      final resultados = await Future.wait(
        lote.map((url) async {
          try {
            await cache.descargar(url);
            return url;
          } catch (_) {
            return null;
          }
        }),
      );
      for (final url in resultados) {
        if (url == null) {
          fallidas++;
        } else {
          completadas++;
          ref
              .read(contenidosDescargadosProvider.notifier)
              .marcarDescargado(url);
        }
      }
      state = state.copia(completadas: completadas, fallidas: fallidas);
    }
    state = SincronizacionEstado(
      completadas: completadas,
      fallidas: fallidas,
      total: urls.length,
      terminada: true,
    );
  }
}

final sincronizacionBibliotecaProvider =
    NotifierProvider<SincronizacionNotifier, SincronizacionEstado>(
      SincronizacionNotifier.new,
    );

final contenidosEducativosProvider =
    StreamProvider.autoDispose<List<MaterialEducativo>>((ref) async* {
      final cacheMetadata = ref.watch(servicioCacheMetadataProvider);
      final (cacheados, marca) = await cacheMetadata.obtenerCatalogoCache();
      if (cacheados.isNotEmpty && cacheMetadata.esReciente(timestamp: marca)) {
        yield cacheados;
        return;
      }
      final repositorio = ref.watch(repositorioBibliotecaProvider);
      try {
        await for (final contenidos
            in repositorio.contenidoEducativoEnTiempoReal()) {
          try {
            await cacheMetadata.guardarCatalogo(contenidos);
          } catch (_) {}
          unawaited(
            ref
                .read(sincronizacionBibliotecaProvider.notifier)
                .sincronizar(contenidos),
          );
          yield contenidos;
        }
      } catch (_) {
        if (cacheados.isNotEmpty) {
          yield cacheados;
        } else {
          rethrow;
        }
      }
    });

final idsFavoritosProvider = StreamProvider.autoDispose<List<String>>((ref) {
  return ref.watch(repositorioBibliotecaProvider).idsFavoritosEnTiempoReal();
});

final contenidoDetalleProvider = FutureProvider.autoDispose
    .family<MaterialEducativo?, String>((ref, id) {
      return ref
          .watch(repositorioBibliotecaProvider)
          .obtenerContenidoEducativo(id);
    });
