import 'package:oncuidar/caracteristicas/biblioteca/dominio/material_educativo.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
import 'package:oncuidar/nucleo/datos/rutas_api.dart';
import 'package:oncuidar/nucleo/red/cliente_api.dart';
import 'package:oncuidar/nucleo/sincronizacion/cola_escrituras.dart';

/// Catálogo educativo y favoritos del cuidador.
class RepositorioBiblioteca {
  RepositorioBiblioteca(this.bd);

  final BaseDatosSegura bd;

  Stream<List<MaterialEducativo>> contenidoEducativoEnTiempoReal() {
    return bd.flujo<List<MaterialEducativo>>(
      RutasApi.biblioteca,
      convertir: (json) async => [
        for (final e in json as List)
          MaterialEducativo.fromMap(
            (e as Map)['id'] as String,
            e.cast<String, dynamic>(),
          ),
      ],
    );
  }

  Future<MaterialEducativo?> obtenerContenidoEducativo(String id) async {
    try {
      final json = await bd.leer(RutasApi.materialBiblioteca(id));
      return MaterialEducativo.fromMap(id, (json as Map).cast());
    } on ExcepcionApi catch (e) {
      if (e.codigoHttp == 404) return null;
      rethrow;
    }
  }

  Stream<List<String>> idsFavoritosEnTiempoReal() {
    if (!bd.tieneIdentidad()) return Stream.value(const []);
    return bd.flujo<List<String>>(
      RutasApi.favoritos,
      vacio: <String, dynamic>{'ids': <dynamic>[]},
      convertir: (json) async => _idsDe(json),
    );
  }

  Future<void> alternarFavorito(String materialId) async {
    final actuales = await _idsFavoritosGuardados();
    await fijarFavorito(materialId, favorito: !actuales.contains(materialId));
  }

  Future<void> fijarFavorito(String materialId, {required bool favorito}) {
    return bd.escribir(
      RutasApi.favorito(materialId),
      const {},
      operacion: favorito
          ? OperacionPendiente.guardar
          : OperacionPendiente.borrar,
    );
  }

  Future<List<String>> _idsFavoritosGuardados() async {
    try {
      return _idsDe(await bd.leerConCache(RutasApi.favoritos));
    } catch (_) {
      return const [];
    }
  }

  List<String> _idsDe(dynamic json) {
    final ids = json is Map ? json['ids'] : null;
    return ids is List ? [for (final id in ids) id.toString()] : const [];
  }
}
