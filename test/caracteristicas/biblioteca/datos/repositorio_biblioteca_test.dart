import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/biblioteca/datos/repositorio_biblioteca.dart';
import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';

const _clavePrueba = 'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';
const _uid = 'uid-favoritos';

void main() {
  late FakeFirebaseFirestore firestore;
  late RepositorioBiblioteca repositorio;

  Future<List<String>> guardados() async {
    final doc = await firestore.collection('usuarios').doc(_uid).get();
    return List<String>.from(doc.data()?['idsFavoritos'] ?? const []);
  }

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repositorio = RepositorioBiblioteca(
      BaseDatosSegura(
        base: firestore,
        uidPrueba: _uid,
        cifrado: ServicioCifrado(clavePrueba: _clavePrueba),
      ),
    );
  });

  test('dos favoritos marcados a la vez se conservan ambos', () async {
    await Future.wait([
      repositorio.alternarFavorito('guia-1'),
      repositorio.alternarFavorito('video-1'),
    ]);
    expect(await guardados(), unorderedEquals(['guia-1', 'video-1']));
  });

  test('marcar un favorito no pisa los ya guardados en el servidor', () async {
    await firestore.collection('usuarios').doc(_uid).set({
      'idsFavoritos': ['guia-1'],
    });
    await repositorio.fijarFavorito('video-1', favorito: true);
    expect(await guardados(), ['guia-1', 'video-1']);
  });

  test('quitar un favorito solo quita ese id', () async {
    await firestore.collection('usuarios').doc(_uid).set({
      'idsFavoritos': ['guia-1', 'video-1'],
    });
    await repositorio.fijarFavorito('guia-1', favorito: false);
    expect(await guardados(), ['video-1']);
  });

  test('fijar dos veces el mismo favorito no lo duplica', () async {
    await repositorio.fijarFavorito('guia-1', favorito: true);
    await repositorio.fijarFavorito('guia-1', favorito: true);
    expect(await guardados(), ['guia-1']);
  });
}
