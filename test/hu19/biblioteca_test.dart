import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oncuidar/caracteristicas/biblioteca/biblioteca.dart';
import 'package:oncuidar/caracteristicas/biblioteca/widgets/tarjeta_material.dart';
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

MaterialEducativo _video() => MaterialEducativo(
  id: 'videos-como-medir-la-fiebre',
  title: 'Cómo medir la fiebre',
  category: 'Videos',
  topic: 'Fiebre',
  body: 'Video paso a paso.',
  fileUrl:
      'https://firebasestorage.googleapis.com/v0/b/oncuidar-v1.firebasestorage.app/o/videos%2Fprueba.mp4?alt=media',
  fileType: 'video',
  fileSizeBytes: 20000000,
  thumbnailUrl: 'assets/images/miniaturas/video_fiebre.png',
  createdAt: DateTime.utc(2026, 1, 1),
);

MaterialEducativo _guia() => MaterialEducativo(
  id: 'guias-manual-de-control-de-sintomas',
  title: 'Manual de Control de Síntomas',
  category: 'Guías',
  topic: 'Cuidados Paliativos',
  body: 'Guía práctica.',
  fileUrl:
      'https://firebasestorage.googleapis.com/v0/b/oncuidar-v1.firebasestorage.app/o/Guias%2Fprueba.pdf?alt=media',
  fileType: 'pdf',
  fileSizeBytes: 3000000,
  thumbnailUrl: 'assets/images/miniaturas/guia_sintomas.png',
  createdAt: DateTime.utc(2026, 1, 2),
);

MaterialEducativo _checklist() => MaterialEducativo(
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

Widget _pantalla(
  ServicioBaseDatos base,
  _CacheFalso cache, {
  void Function(String id)? alAbrirDetalle,
}) {
  final router = GoRouter(
    initialLocation: '/biblioteca',
    routes: [
      GoRoute(path: '/biblioteca', builder: (c, s) => const BibliotecaScreen()),
      GoRoute(
        path: '/biblioteca/:id',
        builder: (c, s) {
          alAbrirDetalle?.call(s.pathParameters['id'] ?? '');
          return const Scaffold(body: Text('Detalle stub'));
        },
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
  _CacheFalso cache, {
  void Function(String id)? alAbrirDetalle,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    _pantalla(base, cache, alAbrirDetalle: alAbrirDetalle),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('lista los materiales desde Firestore con su insignia', (
    tester,
  ) async {
    final (base, _) = await _baseConContenido([
      _video(),
      _guia(),
      _checklist(),
    ]);
    await _montar(tester, base, _CacheFalso());

    expect(find.text('Biblioteca educativa'), findsOneWidget);
    expect(find.text('Cómo medir la fiebre'), findsOneWidget);
    expect(find.text('Manual de Control de Síntomas'), findsOneWidget);
    expect(find.text('Preparación para consulta oncológica'), findsOneWidget);
    expect(find.text('Video'), findsOneWidget);
    expect(find.text('Guía'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(TarjetaMaterial),
        matching: find.text('Checklist'),
      ),
      findsOneWidget,
      reason: 'la insignia de la tarjeta dice Checklist',
    );
  });

  testWidgets('la búsqueda filtra por título', (tester) async {
    final (base, _) = await _baseConContenido([
      _video(),
      _guia(),
      _checklist(),
    ]);
    await _montar(tester, base, _CacheFalso());

    await tester.tap(find.byKey(const Key('alternarBusquedaBiblioteca')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'fiebre');
    await tester.pumpAndSettle();

    expect(find.text('Cómo medir la fiebre'), findsOneWidget);
    expect(find.text('Manual de Control de Síntomas'), findsNothing);
    expect(find.text('Preparación para consulta oncológica'), findsNothing);
  });

  testWidgets('el filtro por categoría muestra solo esa categoría', (
    tester,
  ) async {
    final (base, _) = await _baseConContenido([
      _video(),
      _guia(),
      _checklist(),
    ]);
    await _montar(tester, base, _CacheFalso());

    await tester.tap(find.text('Videos'));
    await tester.pumpAndSettle();

    expect(find.text('Cómo medir la fiebre'), findsOneWidget);
    expect(find.text('Manual de Control de Síntomas'), findsNothing);

    await tester.tap(find.text('Checklist'));
    await tester.pumpAndSettle();

    expect(find.text('Preparación para consulta oncológica'), findsOneWidget);
    expect(find.text('Cómo medir la fiebre'), findsNothing);
  });

  testWidgets('marcar favorito y filtrar por favoritos', (tester) async {
    final (base, firestore) = await _baseConContenido([
      _video(),
      _guia(),
      _checklist(),
    ]);
    await _montar(tester, base, _CacheFalso());

    final tarjetaGuia = find.byWidgetPredicate(
      (w) =>
          w is TarjetaMaterial &&
          w.material.id == 'guias-manual-de-control-de-sintomas',
    );
    await tester.tap(
      find.descendant(
        of: tarjetaGuia,
        matching: find.byIcon(Icons.bookmark_border),
      ),
    );
    await tester.pumpAndSettle();

    final doc = await firestore.collection('users').doc(_uid).get();
    final favoritos = List<String>.from(doc.data()?['favoriteArticleIds']);
    expect(favoritos, contains('guias-manual-de-control-de-sintomas'));

    await tester.tap(find.byKey(const Key('alternarFavoritos')));
    await tester.pumpAndSettle();

    expect(find.text('Manual de Control de Síntomas'), findsOneWidget);
    expect(find.text('Cómo medir la fiebre'), findsNothing);
    expect(find.text('Preparación para consulta oncológica'), findsNothing);
  });

  testWidgets('sin favoritos muestra estado vacío al filtrar', (tester) async {
    final (base, _) = await _baseConContenido([
      _video(),
      _guia(),
      _checklist(),
    ]);
    await _montar(tester, base, _CacheFalso());

    await tester.tap(find.byKey(const Key('alternarFavoritos')));
    await tester.pumpAndSettle();

    expect(
      find.text('No tienes materiales guardados todavía.'),
      findsOneWidget,
    );
  });

  testWidgets('sin resultados de búsqueda muestra estado vacío', (
    tester,
  ) async {
    final (base, _) = await _baseConContenido([
      _video(),
      _guia(),
      _checklist(),
    ]);
    await _montar(tester, base, _CacheFalso());

    await tester.tap(find.byKey(const Key('alternarBusquedaBiblioteca')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();

    expect(find.text('No se encontraron materiales.'), findsOneWidget);
  });

  testWidgets('tocar un checklist abre la hoja interactiva sin ir al detalle', (
    tester,
  ) async {
    final (base, _) = await _baseConContenido([
      _video(),
      _guia(),
      _checklist(),
    ]);
    String? detalleAbierto;
    await _montar(
      tester,
      base,
      _CacheFalso(),
      alAbrirDetalle: (id) => detalleAbierto = id,
    );

    final tarjetaChecklist = find.byWidgetPredicate(
      (w) =>
          w is TarjetaMaterial &&
          w.material.id == 'checklist-preparacion-para-consulta-oncologica',
    );
    await tester.tap(
      find.descendant(
        of: tarjetaChecklist,
        matching: find.byKey(const Key('miniaturaTarjetaMaterial')),
      ),
    );
    await tester.pumpAndSettle();

    expect(detalleAbierto, isNull);
    expect(find.text('Traer carnet de salud'), findsOneWidget);
  });

  testWidgets('tocar un video sin descarga avisa del error', (tester) async {
    final (base, _) = await _baseConContenido([
      _video(),
      _guia(),
      _checklist(),
    ]);
    final cache = _CacheFalso()
      ..fallar.add(
        'https://firebasestorage.googleapis.com/v0/b/oncuidar-v1.firebasestorage.app/o/videos%2Fprueba.mp4?alt=media',
      );
    String? detalleAbierto;
    await _montar(
      tester,
      base,
      cache,
      alAbrirDetalle: (id) => detalleAbierto = id,
    );

    final tarjetaVideo = find.byWidgetPredicate(
      (w) =>
          w is TarjetaMaterial &&
          w.material.id == 'videos-como-medir-la-fiebre',
    );
    await tester.tap(
      find.descendant(
        of: tarjetaVideo,
        matching: find.byKey(const Key('miniaturaTarjetaMaterial')),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(detalleAbierto, isNull);
    expect(find.textContaining('No se pudo preparar el video'), findsOneWidget);
  });
}
