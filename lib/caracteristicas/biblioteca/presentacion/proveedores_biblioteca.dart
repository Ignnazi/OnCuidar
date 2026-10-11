import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oncuidar/caracteristicas/biblioteca/datos/proveedores_biblioteca.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/estado_descarga_contenido.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/material_educativo.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/progreso_descarga.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/temas_biblioteca.dart';
import 'package:oncuidar/nucleo/proveedores.dart';
import 'package:oncuidar/nucleo/sesion/servicio_sesion.dart';

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
    this.fase = FaseDescarga.ninguna,
    this.porcentaje = 0,
  });

  final bool activa;
  final int completadas;
  final int total;
  final int fallidas;
  final bool terminada;

  final FaseDescarga fase;

  final int porcentaje;

  bool get conErrores => fallidas > 0;

  double get progreso => total == 0 ? 0 : completadas / total;

  SincronizacionEstado copia({
    bool? activa,
    int? completadas,
    int? total,
    int? fallidas,
    bool? terminada,
    FaseDescarga? fase,
    int? porcentaje,
  }) {
    return SincronizacionEstado(
      activa: activa ?? this.activa,
      completadas: completadas ?? this.completadas,
      total: total ?? this.total,
      fallidas: fallidas ?? this.fallidas,
      terminada: terminada ?? this.terminada,
      fase: fase ?? this.fase,
      porcentaje: porcentaje ?? this.porcentaje,
    );
  }
}

const _tamanoLoteDescargas = 3;
const _duracionMensajeLista = Duration(seconds: 3);
const _esperaMaximaConexion = Duration(minutes: 5);
const _maximoEsperasSinRed = 5;

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
  int _generacion = 0;
  Timer? _temporizadorOcultar;
  Completer<void>? _esperaConexion;
  Map<String, int?> _porReintentar = {};

  @override
  SincronizacionEstado build() {
    ref.listen<AsyncValue<bool>>(estadoConexionProvider, (previo, actual) {
      if (actual.value == true) _alReconectar();
      if (actual.value == false) _alDesconectar();
    });
    ref.listen<AsyncValue<SesionUsuario?>>(estadoAutenticacionProvider, (
      previo,
      actual,
    ) {
      if (previo?.value != null && actual.value == null) cancelar();
    });
    ref.onDispose(() => _temporizadorOcultar?.cancel());
    return const SincronizacionEstado();
  }

  bool get _sinConexion => ref.read(estadoConexionProvider).value == false;

  void cancelar() {
    _generacion++;
    _enCurso = false;
    _temporizadorOcultar?.cancel();
    _porReintentar = {};
    _liberarEspera();
    state = const SincronizacionEstado();
  }

  void _liberarEspera() {
    final espera = _esperaConexion;
    _esperaConexion = null;
    if (espera != null && !espera.isCompleted) espera.complete();
  }

  void _alDesconectar() {
    if (state.fase == FaseDescarga.descargando) {
      state = state.copia(fase: FaseDescarga.pausada);
    }
  }

  void _alReconectar() {
    _liberarEspera();
    if (state.fase == FaseDescarga.pausada && _enCurso) {
      state = state.copia(fase: FaseDescarga.descargando);
    } else if (state.fase == FaseDescarga.conErrores &&
        !_enCurso &&
        _porReintentar.isNotEmpty) {
      unawaited(_reintentarPendientes());
    }
  }

  Future<void> _ejecutar(Future<void> Function() tarea) async {
    if (_enCurso) return;
    _enCurso = true;
    final generacion = _generacion;
    try {
      await tarea();
    } finally {
      if (generacion == _generacion) _enCurso = false;
    }
  }

  Future<void> sincronizar(List<MaterialEducativo> contenidos) =>
      _ejecutar(() => _sincronizarContenido(contenidos));

  Future<void> _reintentarPendientes() => _ejecutar(() async {
    final pendientes = _porReintentar;
    _porReintentar = {};
    await _descargarPendientes(pendientes);
  });

  Future<void> sincronizarAlIniciarSesion() => _ejecutar(() async {
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
    }
  });

  Future<void> _sincronizarContenido(
    List<MaterialEducativo> contenidos, {
    bool guardarCatalogo = true,
  }) async {
    final generacion = _generacion;
    final tamanos = <String, int?>{};
    for (final material in contenidos) {
      for (final url in _urlsDelMaterial(material)) {
        tamanos.putIfAbsent(
          url,
          () => url == material.urlArchivo ? material.tamanoBytes : null,
        );
      }
    }
    if (tamanos.isEmpty) {
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
    final pendientes = <String, int?>{};
    for (final entrada in tamanos.entries) {
      if (await cache.archivoDescargado(entrada.key)) {
        ref
            .read(contenidosDescargadosProvider.notifier)
            .marcarDescargado(entrada.key);
      } else {
        pendientes[entrada.key] = entrada.value;
      }
    }
    if (generacion != _generacion) return;
    if (pendientes.isEmpty) {
      state = SincronizacionEstado(
        completadas: tamanos.length,
        total: tamanos.length,
        terminada: true,
      );
      return;
    }
    await _descargarPendientes(pendientes);
  }

  Future<void> _descargarPendientes(Map<String, int?> pendientes) async {
    final generacion = _generacion;
    _temporizadorOcultar?.cancel();
    final cache = ref.read(servicioCacheContenidoProvider);
    final progreso = ProgresoDescarga(pendientes);
    final urls = pendientes.keys.toList();
    state = SincronizacionEstado(
      activa: true,
      total: urls.length,
      fase: _sinConexion ? FaseDescarga.pausada : FaseDescarga.descargando,
    );
    var completadas = 0;
    final fallidas = <String>[];

    void publicar() {
      if (generacion != _generacion) return;
      final porcentaje = progreso.porcentaje;
      if (porcentaje != state.porcentaje) {
        state = state.copia(porcentaje: porcentaje);
      }
    }

    Future<bool> descargarUna(String url) async {
      var esperas = 0;
      while (true) {
        try {
          final archivo = await cache.descargar(
            url,
            tamanoBytes: pendientes[url],
            alProgresar: (descargado, total) {
              progreso.avanzar(url, descargado, total: total);
              publicar();
            },
          );
          progreso.completar(url, tamanoReal: await archivo.length());
          return true;
        } catch (_) {
          if (generacion != _generacion) return false;
          if (!_sinConexion || esperas >= _maximoEsperasSinRed) return false;
          esperas++;
          _alDesconectar();
          _esperaConexion ??= Completer<void>();
          await _esperaConexion!.future.timeout(
            _esperaMaximaConexion,
            onTimeout: () {},
          );
          if (generacion != _generacion) return false;
          _alReconectar();
        }
      }
    }

    for (var inicio = 0; inicio < urls.length; inicio += _tamanoLoteDescargas) {
      final fin = (inicio + _tamanoLoteDescargas < urls.length)
          ? inicio + _tamanoLoteDescargas
          : urls.length;
      final lote = urls.sublist(inicio, fin);
      final resultados = await Future.wait(
        lote.map((url) async => (url, await descargarUna(url))),
      );
      if (generacion != _generacion) return;
      for (final (url, ok) in resultados) {
        if (ok) {
          completadas++;
          ref
              .read(contenidosDescargadosProvider.notifier)
              .marcarDescargado(url);
        } else {
          fallidas.add(url);
          progreso.descartar(url);
        }
      }
      state = state.copia(
        completadas: completadas,
        fallidas: fallidas.length,
        porcentaje: progreso.porcentaje,
      );
    }
    _porReintentar = {for (final url in fallidas) url: pendientes[url]};
    state = SincronizacionEstado(
      completadas: completadas,
      fallidas: fallidas.length,
      total: urls.length,
      terminada: true,
      fase: fallidas.isEmpty ? FaseDescarga.lista : FaseDescarga.conErrores,
      porcentaje: fallidas.isEmpty ? 100 : state.porcentaje,
    );
    if (fallidas.isEmpty) {
      _temporizadorOcultar = Timer(_duracionMensajeLista, () {
        if (generacion == _generacion) {
          state = state.copia(fase: FaseDescarga.ninguna);
        }
      });
    }
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

class TemaSeleccionadoNotifier extends Notifier<String> {
  @override
  String build() => temaTodas;

  void seleccionar(String tema) => state = tema;

  void reiniciarSiNoExiste(Iterable<String> temas) {
    final vigente = temaVigente(state, temas);
    if (vigente != state) state = vigente;
  }
}

final temaSeleccionadoProvider =
    NotifierProvider.autoDispose<TemaSeleccionadoNotifier, String>(
      TemaSeleccionadoNotifier.new,
    );
