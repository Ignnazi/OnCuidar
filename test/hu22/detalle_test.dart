import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oncuidar/caracteristicas/biblioteca/pantalla_detalle.dart';
import 'package:oncuidar/caracteristicas/biblioteca/parseo_contenido.dart';
import 'package:oncuidar/core/proveedores/proveedores.dart';
import 'package:oncuidar/core/servicios/servicio_base_datos.dart';
import 'package:oncuidar/core/servicios/servicio_cache_contenido.dart';
import 'package:oncuidar/core/servicios/servicio_cache_metadata.dart';
import 'package:oncuidar/core/servicios/servicio_cifrado.dart';
import 'package:oncuidar/modelos/material_educativo.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _clavePrueba = 'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';
const _uid = 'uid-1';

MockFirebaseAuth _auth() => MockFirebaseAuth(
  mockUser: MockUser(uid: _uid, email: 'cuidador@test.cl'),
);

MaterialEducativo _guia() => MaterialEducativo(
  id: 'guias-manual-de-control-de-sintomas',
  title: 'Manual de Control de Síntomas',
  category: 'Guías',
  topic: 'Cuidados Paliativos',
  body:
      '# Dolor\nAdministra el analgésico según horario.\n\n# Náuseas\nOfrece comidas pequeñas.',
  imageUrl: 'https://localhost/imagen.jpg',
  fileUrl:
      'https://firebasestorage.googleapis.com/v0/b/oncuidar-v1.firebasestorage.app/o/Guias%2Fprueba.pdf?alt=media',
  fileType: 'pdf',
  fileSizeBytes: 3000000,
  createdAt: DateTime.utc(2026, 1, 2),
);

MaterialEducativo _simple() => MaterialEducativo(
  id: 'checklist-preparacion-para-consulta-oncologica',
  title: 'Preparación para consulta oncológica',
  category: 'Checklist',
  topic: 'Consulta médica',
  body: '- Traer carnet de salud',
  createdAt: DateTime.utc(2026, 1, 3),
);

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

Future<(ServicioBaseDatos, FakeFirebaseFirestore)> _baseConContenido(
  List<MaterialEducativo> contenido,
) async {
  final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
  await cifrado.fijarClave(_uid, _clavePrueba);
  final firestore = FakeFirebaseFirestore();
  final base = ServicioBaseDatos(
    base: firestore,
    uidPrueba: _uid,
    cifrado: cifrado,
  );
  await base.crearCuidador({
    'displayName': 'Ana Torres',
    'email': 'cuidador@test.cl',
    'phone': '+56 9 1111 1111',
    'relationship': 'Madre',
    'address': 'Av. Siempre Viva 742',
  });
  for (final item in contenido) {
    await firestore
        .collection('educationalContent')
        .doc(item.id)
        .set(item.toMap());
  }
  return (base, firestore);
}

Widget _pantalla(ServicioBaseDatos base, _CacheFalso cache, String id) {
  final router = GoRouter(
    initialLocation: '/biblioteca/$id',
    routes: [
      GoRoute(
        path: '/biblioteca',
        builder: (c, s) => const Scaffold(body: Text('Biblioteca stub')),
      ),
      GoRoute(
        path: '/biblioteca/:id',
        builder: (c, s) =>
            PantallaDetalleMaterial(id: s.pathParameters['id'] ?? ''),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      firebaseAuthProvider.overrideWithValue(_auth()),
      servicioBaseDatosProvider.overrideWith((_) => base),
      servicioCacheContenidoProvider.overrideWithValue(cache),
      servicioCacheMetadataProvider.overrideWithValue(ServicioCacheMetadata()),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _montar(
  WidgetTester tester,
  ServicioBaseDatos base,
  _CacheFalso cache,
  String id,
) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_pantalla(base, cache, id));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('parsearCuerpo', () {
    test('reconoce secciones con # y descarta líneas vacías', () {
      final bloques = parsearCuerpo('# Dolor\n\nPárrafo uno.\n# Náuseas\n');
      expect(bloques, hasLength(3));
      expect(bloques[0].esTitulo, isTrue);
      expect(bloques[0].texto, 'Dolor');
      expect(bloques[1].esTitulo, isFalse);
      expect(bloques[1].texto, 'Párrafo uno.');
      expect(bloques[2].esTitulo, isTrue);
      expect(bloques[2].texto, 'Náuseas');
    });
  });

  testWidgets('el detalle muestra título, tema, insignia y secciones', (
    tester,
  ) async {
    final (base, _) = await _baseConContenido([_guia()]);
    await _montar(tester, base, _CacheFalso(), _guia().id);

    expect(find.text('Material educativo'), findsOneWidget);
    expect(find.text('Manual de Control de Síntomas'), findsOneWidget);
    expect(find.text('Cuidados Paliativos'), findsWidgets);
    expect(find.text('Guía'), findsOneWidget);
    expect(find.text('Dolor'), findsOneWidget);
    expect(
      find.text('Administra el analgésico según horario.'),
      findsOneWidget,
    );
    expect(find.text('Náuseas'), findsOneWidget);
    expect(find.text('Abrir archivo adjunto'), findsOneWidget);
  });

  testWidgets('marcar favorito desde el detalle persiste en Firestore', (
    tester,
  ) async {
    final (base, firestore) = await _baseConContenido([_guia()]);
    await _montar(tester, base, _CacheFalso(), _guia().id);

    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    await tester.tap(find.byIcon(Icons.bookmark_border));
    await tester.pumpAndSettle();

    final doc = await firestore.collection('users').doc(_uid).get();
    final favoritos = List<String>.from(doc.data()?['favoriteArticleIds']);
    expect(favoritos, contains(_guia().id));
    expect(find.byIcon(Icons.bookmark), findsOneWidget);
  });

  testWidgets('una imagen rota se reemplaza sin lanzar excepción', (
    tester,
  ) async {
    final (base, _) = await _baseConContenido([_guia()]);
    await _montar(tester, base, _CacheFalso(), _guia().id);

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('tocar la imagen abre el visor ampliable y se cierra', (
    tester,
  ) async {
    final (base, _) = await _baseConContenido([_guia()]);
    await _montar(tester, base, _CacheFalso(), _guia().id);

    expect(find.byType(InteractiveViewer), findsNothing);

    await tester.tap(find.byType(Image).first);
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveViewer), findsNothing);
  });

  testWidgets('abrir adjunto que falla muestra el aviso', (tester) async {
    final (base, _) = await _baseConContenido([_guia()]);
    final cache = _CacheFalso()
      ..fallar.add(
        'https://firebasestorage.googleapis.com/v0/b/oncuidar-v1.firebasestorage.app/o/Guias%2Fprueba.pdf?alt=media',
      );
    await _montar(tester, base, cache, _guia().id);

    await tester.tap(find.text('Abrir archivo adjunto'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Error al abrir el archivo'), findsOneWidget);
  });

  testWidgets('el detalle de un checklist muestra la lista interactiva', (
    tester,
  ) async {
    final (base, _) = await _baseConContenido([_simple()]);
    await _montar(tester, base, _CacheFalso(), _simple().id);

    expect(find.text('Preparación para consulta oncológica'), findsOneWidget);
    expect(find.text('Traer carnet de salud'), findsOneWidget);
    expect(find.text('0/1'), findsOneWidget);
  });

  testWidgets('un material inexistente muestra el estado vacío', (
    tester,
  ) async {
    final (base, _) = await _baseConContenido([_simple()]);
    await _montar(tester, base, _CacheFalso(), 'id-inexistente');

    expect(find.text('Material no encontrado.'), findsOneWidget);
  });
}
