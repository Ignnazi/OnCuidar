import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/material_educativo.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';

/// Catálogo educativo y favoritos del cuidador.
class RepositorioBiblioteca {
  RepositorioBiblioteca(this.bd);

  final BaseDatosSegura bd;

  CollectionReference _contenidoEducativo() =>
      bd.firestore.collection('materialEducativo');

  Stream<List<MaterialEducativo>> contenidoEducativoEnTiempoReal() {
    return _contenidoEducativo().snapshots().map(
      (snap) => [
        for (final doc in snap.docs)
          MaterialEducativo.fromMap(doc.id, doc.data() as Map<String, dynamic>),
      ],
    );
  }

  Future<MaterialEducativo?> obtenerContenidoEducativo(String id) async {
    final doc = await _contenidoEducativo().doc(id).get();
    if (!doc.exists) return null;
    return MaterialEducativo.fromMap(
      doc.id,
      doc.data() as Map<String, dynamic>,
    );
  }

  Stream<List<String>> idsFavoritosEnTiempoReal() {
    if (!bd.tieneIdentidad()) return Stream.value(const []);
    return bd.docUsuario.snapshots().map((snap) {
      final datos = snap.data() as Map<String, dynamic>?;
      return List<String>.from(datos?['idsFavoritos'] ?? const []);
    });
  }

  Future<void> alternarFavorito(String materialId) async {
    var favoritos = <String>[];
    try {
      final doc = await bd.docUsuario.get(
        const GetOptions(source: Source.cache),
      );
      final datos = doc.data() as Map<String, dynamic>?;
      favoritos = List<String>.from(datos?['idsFavoritos'] ?? const []);
    } catch (_) {
      try {
        final doc = await bd.docUsuario.get();
        final datos = doc.data() as Map<String, dynamic>?;
        favoritos = List<String>.from(datos?['idsFavoritos'] ?? const []);
      } catch (_) {
        favoritos = const [];
      }
    }
    if (favoritos.contains(materialId)) {
      favoritos.remove(materialId);
    } else {
      favoritos.add(materialId);
    }
    await bd.sinEsperarSinRed(
      () => bd.docUsuario.set({
        'idsFavoritos': favoritos,
      }, SetOptions(merge: true)),
    );
  }
}
