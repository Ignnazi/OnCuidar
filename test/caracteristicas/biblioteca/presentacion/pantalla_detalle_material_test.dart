import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oncuidar/caracteristicas/biblioteca/datos/proveedores_biblioteca.dart';
import 'package:oncuidar/caracteristicas/biblioteca/datos/servicio_cache_contenido.dart';
import 'package:oncuidar/caracteristicas/biblioteca/datos/servicio_cache_metadata.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/material_educativo.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/parseo_contenido.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/pantalla_detalle_material.dart';
import 'package:oncuidar/caracteristicas/perfil/datos/repositorio_cuidador.dart';
import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
import 'package:oncuidar/nucleo/proveedores.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _clavePrueba = 'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';
const _uid = 'uid-1';

MockFirebaseAuth _auth() => MockFirebaseAuth(
  mockUser: MockUser(uid: _uid, email: 'cuidador@test.cl'),
);

MaterialEducativo _guia() => MaterialEducativo(
  id: 'guias-manual-de-control-de-sintomas',
  titulo: 'Manual de Control de Síntomas',
  categoria: 'Guías',
  tema: 'Cuidados Paliativos',
  cuerpo:
      '# Dolor\nAdministra el analgésico según horario.\n\n# Náuseas\nOfrece comidas pequeñas.',
  urlImagen: 'https://localhost/imagen.jpg',
  urlArchivo:
      'https://firebasestorage.googleapis.com/v0/b/oncuidar-v1.firebasestorage.app/o/Guias%2Fprueba.pdf?alt=media',
  tipoArchivo: 'pdf',
  tamanoBytes: 3000000,
  creadoEn: DateTime.utc(2026, 1, 2),
);

MaterialEducativo _simple() => MaterialEducativo(
  id: 'checklist-preparacion-para-consulta-oncologica',
  titulo: 'Preparación para consulta oncológica',
  categoria: 'Checklist',
  tema: 'Consulta médica',
  cuerpo: '- Traer carnet de salud',
  creadoEn: DateTime.utc(2026, 1, 3),
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

Future<(BaseDatosSegura, FakeFirebaseFirestore)> _baseConContenido(
  List<MaterialEducativo> contenido,
) async {
  final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
  await cifrado.fijarClave(_uid, _clavePrueba);
  final firestore = FakeFirebaseFirestore();
  final base = BaseDatosSegura(
    base: firestore,
    uidPrueba: _uid,
    cifrado: cifrado,
  );
  await RepositorioCuidador(base).crearCuidador({
    'nombre': 'Ana Torres',
    'correo': 'cuidador@test.cl',
    'telefono': '+56 9 1111 1111',
    'relacion': 'Madre',
    'direccion': 'Av. Siempre Viva 742',
  });
  for (final item in contenido) {
    await firestore
        .collection('materialEducativo')
        .doc(item.id)
        .set(item.toMap());
  }
  return (base, firestore);
}

Widget _pantalla(BaseDatosSegura base, _CacheFalso cache, String id) {
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
      baseDatosSeguraProvider.overrideWith((_) => base),
      servicioCacheContenidoProvider.overrideWithValue(cache),
      servicioCacheMetadataProvider.overrideWithValue(ServicioCacheMetadata()),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _montar(
  WidgetTester tester,
  BaseDatosSegura base,
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

    final doc = await firestore.collection('usuarios').doc(_uid).get();
    final favoritos = List<String>.from(doc.data()?['idsFavoritos']);
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

  testWidgets(
    'una guía sin adjunto muestra sus secciones y ningún botón (CA-19.4)',
    (tester) async {
      final sinArchivo = MaterialEducativo(
        id: 'guias-alimentacion',
        titulo: 'Guía de alimentación',
        categoria: 'Guías',
        tema: 'Alimentación',
        cuerpo:
            '# Desayuno\nFrutas cocidas.\n\n# Agua\nSolo hervida o embotellada.',
        creadoEn: DateTime.utc(2026, 1, 4),
      );
      final (base, _) = await _baseConContenido([sinArchivo]);
      await _montar(tester, base, _CacheFalso(), sinArchivo.id);

      expect(find.text('Desayuno'), findsOneWidget);
      expect(find.text('Frutas cocidas.'), findsOneWidget);
      expect(find.text('Agua'), findsOneWidget);
      expect(find.text('Abrir archivo adjunto'), findsNothing);
    },
  );
}
