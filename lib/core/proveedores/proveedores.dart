import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:shared_preferences/shared_preferences.dart';
import '../../modelos/checklist_usuario.dart';
import '../../modelos/material_educativo.dart';
import '../../modelos/paciente.dart';
import '../../modelos/registro_clinico.dart';
import '../servicios/servicio_base_datos.dart';
import '../servicios/servicio_cache_contenido.dart';
import '../servicios/servicio_cache_metadata.dart';
import '../servicios/servicio_cifrado.dart';
import '../servicios/servicio_registro.dart';

final servicioCifradoProvider = Provider<ServicioCifrado>((ref) {
  return ServicioCifrado();
});

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final estadoAutenticacionProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

class BloqueoCifradoNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void fijarDesbloqueado(bool valor) => state = valor;
}

final bloqueoCifradoProvider = NotifierProvider<BloqueoCifradoNotifier, bool>(
  BloqueoCifradoNotifier.new,
);

final servicioBaseDatosProvider = Provider<ServicioBaseDatos>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return ServicioBaseDatos(
    base: FirebaseFirestore.instance,
    auth: auth,
    cifrado: ref.watch(servicioCifradoProvider),
  );
});

final cuidadorProvider =
    StreamProvider.autoDispose<Map<String, dynamic>?>((ref) {
  return ref.watch(servicioBaseDatosProvider).cuidadorEnTiempoReal();
});

final servicioRegistroProvider = Provider<ServicioRegistro>((ref) {
  return ServicioRegistro(
    auth: ref.watch(firebaseAuthProvider),
    cifrado: ref.watch(servicioCifradoProvider),
    baseDatos: ref.watch(servicioBaseDatosProvider),
    alDesbloquear: () =>
        ref.read(bloqueoCifradoProvider.notifier).fijarDesbloqueado(true),
  );
});

const _clavePacienteSeleccionado = 'selected_patient_id';

final patientsListProvider = StreamProvider.autoDispose<List<Paciente>>((ref) {
  return ref.watch(servicioBaseDatosProvider).pacientesEnTiempoReal();
});

final archivedPatientsListProvider = StreamProvider.autoDispose<List<Paciente>>(
  (ref) {
    return ref
        .watch(servicioBaseDatosProvider)
        .pacientesArchivadosEnTiempoReal();
  },
);

class SelectedPatientNotifier extends Notifier<String?> {
  @override
  String? build() {
    _cargarDelPrefs();
    return null;
  }

  Future<void> _cargarDelPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final guardado = prefs.getString(_clavePacienteSeleccionado);
      if (guardado != null) state = guardado;
    } catch (_) {
      // Si falla, se sigue igual.
    }
  }

  Future<void> select(String? idPaciente) async {
    state = idPaciente;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (idPaciente == null) {
        await prefs.remove(_clavePacienteSeleccionado);
      } else {
        await prefs.setString(_clavePacienteSeleccionado, idPaciente);
      }
    } catch (_) {
      // Si falla, se sigue igual.
    }
  }
}

final selectedPatientIdProvider =
    NotifierProvider<SelectedPatientNotifier, String?>(
      SelectedPatientNotifier.new,
    );

final currentPatientProvider = StreamProvider.autoDispose<Paciente?>((
  ref,
) async* {
  final pacientesAsync = ref.watch(patientsListProvider);
  if (pacientesAsync is AsyncLoading) return;
  final pacientes = pacientesAsync.value ?? const <Paciente>[];
  if (pacientes.isEmpty) {
    yield null;
    return;
  }
  final seleccionadoId = ref.watch(selectedPatientIdProvider);
  if (seleccionadoId != null) {
    for (final paciente in pacientes) {
      if (paciente.id == seleccionadoId) {
        yield paciente;
        return;
      }
    }
  }
  yield pacientes.first;
});


final registrosClinicosProvider =
    StreamProvider.autoDispose<List<RegistroClinico>>((ref) {
      final pacienteAsync = ref.watch(currentPatientProvider);
      if (pacienteAsync is AsyncLoading) return Stream.empty();
      final paciente = pacienteAsync.value;
      if (paciente == null) return Stream.value(const []);
      return ref
          .watch(servicioBaseDatosProvider)
          .registrosClinicosEnTiempoReal(paciente.id);
    });

final registroEnEdicionProvider = StateProvider<RegistroClinico?>((ref) => null);

final servicioCacheContenidoProvider = Provider<ServicioCacheContenido>((ref) {
  return ServicioCacheContenido();
});

final servicioCacheMetadataProvider = Provider<ServicioCacheMetadata>((ref) {
  return ServicioCacheMetadata();
});

class DescargasContenidoNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void marcarDescargado(String url) {
    if (state.contains(url)) return;
    state = {...state, url};
  }

  void marcarEliminado(String url) {
    if (!state.contains(url)) return;
    state = {...state}..remove(url);
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
  final archivo = material.fileUrl;
  if (archivo != null && archivo.isNotEmpty) yield archivo;
  final imagen = material.imageUrl;
  if (imagen != null && imagen.isNotEmpty && !imagen.startsWith('assets/')) {
    yield imagen;
  }
  final miniatura = material.thumbnailUrl;
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
        final base = ref.read(servicioBaseDatosProvider);
        contenidos = await base
            .contenidoEducativoEnTiempoReal()
            .first
            .timeout(const Duration(seconds: 8));
      }
      await _sincronizarContenido(
        contenidos,
        guardarCatalogo: !cacheVigente,
      );
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
        await ref.read(servicioCacheMetadataProvider).guardarCatalogo(contenidos);
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
  final base = ref.watch(servicioBaseDatosProvider);
  try {
    await for (final contenidos in base.contenidoEducativoEnTiempoReal()) {
      try {
        await cacheMetadata.guardarCatalogo(contenidos);
      } catch (_) {}
      ref
          .read(sincronizacionBibliotecaProvider.notifier)
          .sincronizar(contenidos);
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
  return ref.watch(servicioBaseDatosProvider).idsFavoritosEnTiempoReal();
});

final contenidoDetalleProvider =
    FutureProvider.autoDispose.family<MaterialEducativo?, String>((ref, id) {
  return ref.watch(servicioBaseDatosProvider).obtenerContenidoEducativo(id);
});

final listasChecklistProvider =
    StreamProvider.autoDispose<List<ChecklistUsuario>>((ref) {
      final pacienteAsync = ref.watch(currentPatientProvider);
      if (pacienteAsync is AsyncLoading) return Stream.empty();
      final paciente = pacienteAsync.value;
      if (paciente == null) return Stream.value(const []);
      return ref
          .watch(servicioBaseDatosProvider)
          .listasChecklistTiempoReal(paciente.id);
    });
