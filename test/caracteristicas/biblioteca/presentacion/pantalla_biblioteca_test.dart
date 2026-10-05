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
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/pantalla_biblioteca.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/pantalla_visor_imagen.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/widgets/encabezado_seccion.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/widgets/tarjeta_material.dart';
import 'package:oncuidar/caracteristicas/perfil/datos/repositorio_cuidador.dart';
import 'package:oncuidar/compartido/widgets/insignia_conteo.dart';
import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
import 'package:oncuidar/nucleo/proveedores.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _clavePrueba = 'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';
const _uid = 'uid-1';

MockFirebaseAuth _auth() => MockFirebaseAuth(
  mockUser: MockUser(uid: _uid, email: 'cuidador@test.cl'),
);

MaterialEducativo _video() => MaterialEducativo(
  id: 'videos-como-medir-la-fiebre',
  titulo: 'Cómo medir la fiebre',
  categoria: 'Videos',
  tema: 'Fiebre',
  cuerpo: 'Video paso a paso.',
  urlArchivo:
      'https://firebasestorage.googleapis.com/v0/b/oncuidar-v1.firebasestorage.app/o/videos%2Fprueba.mp4?alt=media',
  tipoArchivo: 'video',
  tamanoBytes: 20000000,
  urlMiniatura: 'assets/images/miniaturas/video_fiebre.png',
  creadoEn: DateTime.utc(2026, 1, 1),
);

MaterialEducativo _guia() => MaterialEducativo(
  id: 'guias-manual-de-control-de-sintomas',
  titulo: 'Manual de Control de Síntomas',
  categoria: 'Guías',
  tema: 'Cuidados Paliativos',
  cuerpo: 'Guía práctica.',
  urlArchivo:
      'https://firebasestorage.googleapis.com/v0/b/oncuidar-v1.firebasestorage.app/o/Guias%2Fprueba.pdf?alt=media',
  tipoArchivo: 'pdf',
  tamanoBytes: 3000000,
  urlMiniatura: 'assets/images/miniaturas/guia_sintomas.png',
  creadoEn: DateTime.utc(2026, 1, 2),
);

MaterialEducativo _infografia() => MaterialEducativo(
  id: 'infografias-guia-de-seguimiento',
  titulo: 'Guía de seguimiento',
  categoria: 'Infografías',
  tema: 'Seguimiento',
  cuerpo: 'Infografía de controles.',
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

Widget _pantalla(
  BaseDatosSegura base,
  _CacheFalso cache, {
  void Function(String id)? alAbrirDetalle,
  String? abrir,
}) {
  final router = GoRouter(
    initialLocation: abrir == null ? '/biblioteca' : '/biblioteca?abrir=$abrir',
    routes: [
      GoRoute(
        path: '/biblioteca',
        builder: (c, s) =>
            BibliotecaScreen(abrirId: s.uri.queryParameters['abrir']),
      ),
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
  _CacheFalso cache, {
  void Function(String id)? alAbrirDetalle,
  String? abrir,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    _pantalla(base, cache, alAbrirDetalle: alAbrirDetalle, abrir: abrir),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('lista los materiales desde Firestore con su ícono de tipo', (
    tester,
  ) async {
    final (base, _) = await _baseConContenido([
      _video(),
      _guia(),
      _infografia(),
    ]);
    await _montar(tester, base, _CacheFalso());

    expect(find.text('Biblioteca educativa'), findsOneWidget);
    expect(find.text('Cómo medir la fiebre'), findsOneWidget);
    expect(find.text('Manual de Control de Síntomas'), findsOneWidget);
    expect(find.text('Guía de seguimiento'), findsOneWidget);
    expect(find.byKey(const Key('iconoTipoMaterial')), findsNWidgets(3));
    expect(
      find.text('Checklist'),
      findsNothing,
      reason: 'la categoría Checklist ya no existe',
    );
  });

  testWidgets('Todos agrupa por tipo con encabezado y cantidad', (
    tester,
  ) async {
    final (base, _) = await _baseConContenido([
      _infografia(),
      _guia(),
      _video(),
    ]);
    await _montar(tester, base, _CacheFalso());

    final secciones = ['Videos', 'Guías', 'Infografías'];
    final alturas = [
      for (final titulo in secciones)
        tester.getTopLeft(find.byKey(Key('seccion_$titulo'))).dy,
    ];
    expect(alturas, orderedEquals([...alturas]..sort()));
    for (final titulo in secciones) {
      expect(
        find.descendant(
          of: find.byKey(Key('seccion_$titulo')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
    }
    final video = tester.getTopLeft(find.text('Cómo medir la fiebre')).dy;
    final guia = tester
        .getTopLeft(find.text('Manual de Control de Síntomas'))
        .dy;
    expect(video, lessThan(alturas[1]));
    expect(guia, greaterThan(alturas[1]));
    expect(guia, lessThan(alturas[2]));
  });

  testWidgets('un filtro de tipo muestra la lista sin secciones', (
    tester,
  ) async {
    final (base, _) = await _baseConContenido([_video(), _guia()]);
    await _montar(tester, base, _CacheFalso());
    expect(find.byType(EncabezadoSeccion), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('filtro_Guías')));
    await tester.pumpAndSettle();

    expect(find.byType(EncabezadoSeccion), findsNothing);
    expect(find.text('Manual de Control de Síntomas'), findsOneWidget);
  });

  testWidgets('la búsqueda filtra por título', (tester) async {
    final (base, _) = await _baseConContenido([
      _video(),
      _guia(),
      _infografia(),
    ]);
    await _montar(tester, base, _CacheFalso());

    await tester.tap(find.byKey(const Key('alternarBusquedaBiblioteca')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'fiebre');
    await tester.pumpAndSettle();

    expect(find.text('Cómo medir la fiebre'), findsOneWidget);
    expect(find.text('Manual de Control de Síntomas'), findsNothing);
    expect(find.text('Guía de seguimiento'), findsNothing);
  });

  testWidgets('el filtro por categoría muestra solo esa categoría', (
    tester,
  ) async {
    final (base, _) = await _baseConContenido([
      _video(),
      _guia(),
      _infografia(),
    ]);
    await _montar(tester, base, _CacheFalso());

    await tester.tap(find.byKey(const Key('filtro_Videos')));
    await tester.pumpAndSettle();

    expect(find.text('Cómo medir la fiebre'), findsOneWidget);
    expect(find.text('Manual de Control de Síntomas'), findsNothing);

    await tester.tap(find.byKey(const Key('filtro_Infografías')));
    await tester.pumpAndSettle();

    expect(find.text('Guía de seguimiento'), findsOneWidget);
    expect(find.text('Cómo medir la fiebre'), findsNothing);
  });

  testWidgets('marcar favorito y filtrar por favoritos', (tester) async {
    final (base, firestore) = await _baseConContenido([
      _video(),
      _guia(),
      _infografia(),
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

    final doc = await firestore.collection('usuarios').doc(_uid).get();
    final favoritos = List<String>.from(doc.data()?['idsFavoritos']);
    expect(favoritos, contains('guias-manual-de-control-de-sintomas'));

    final insignia = tester.widget<Container>(
      find.descendant(
        of: find.byKey(const Key('insigniaFavoritos')),
        matching: find.byType(Container),
      ),
    );
    expect(
      (insignia.decoration! as BoxDecoration).color,
      InsigniaConteo.colorFondo(),
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('insigniaFavoritos')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('alternarFavoritos')));
    await tester.pumpAndSettle();

    expect(find.text('Manual de Control de Síntomas'), findsOneWidget);
    expect(find.text('Cómo medir la fiebre'), findsNothing);
    expect(find.text('Guía de seguimiento'), findsNothing);
  });

  testWidgets('sin favoritos muestra estado vacío al filtrar', (tester) async {
    final (base, _) = await _baseConContenido([
      _video(),
      _guia(),
      _infografia(),
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
      _infografia(),
    ]);
    await _montar(tester, base, _CacheFalso());

    await tester.tap(find.byKey(const Key('alternarBusquedaBiblioteca')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();

    expect(find.text('No se encontraron materiales.'), findsOneWidget);
  });

  testWidgets('entrar con ?abrir= abre ese material sin pasar por el detalle', (
    tester,
  ) async {
    final (base, _) = await _baseConContenido([_video(), _guia()]);
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
      abrir: 'videos-como-medir-la-fiebre',
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(detalleAbierto, isNull);
    expect(find.textContaining('No se pudo preparar el video'), findsOneWidget);
  });

  testWidgets('tocar un video sin descarga avisa del error', (tester) async {
    final (base, _) = await _baseConContenido([
      _video(),
      _guia(),
      _infografia(),
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

  testWidgets('el catálogo lista todo sin marca de descargado (CA-17.1)', (
    tester,
  ) async {
    final (base, _) = await _baseConContenido([_video(), _guia()]);
    final cache = _CacheFalso()
      ..descargados.add(_guia().urlArchivo!)
      ..fallar.add(_video().urlArchivo!);
    await _montar(tester, base, cache);

    expect(find.text(_video().titulo), findsOneWidget);
    expect(find.text(_guia().titulo), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
  });

  testWidgets(
    'una infografía sin adjunto se abre en el visor con zoom y se cierra (CA-19.3)',
    (tester) async {
      final infografia = MaterialEducativo(
        id: 'infografias-lavado-de-manos',
        titulo: 'Lavado de manos',
        categoria: 'Infografías',
        tema: 'Higiene',
        cuerpo: 'Pasos del lavado de manos.',
        urlImagen: 'https://localhost/lavado.png',
        creadoEn: DateTime.utc(2026, 1, 5),
      );
      final (base, _) = await _baseConContenido([infografia]);
      await _montar(tester, base, _CacheFalso());

      await tester.tap(find.byKey(const Key('miniaturaTarjetaMaterial')));
      await tester.pumpAndSettle();

      expect(find.byType(PantallaVisorImagen), findsOneWidget);
      final visor = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      expect(visor.minScale, 1);
      expect(visor.maxScale, 8);
      expect(
        find.descendant(
          of: find.byType(PantallaVisorImagen),
          matching: find.text('Lavado de manos'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('cerrarVisorImagen')));
      await tester.pumpAndSettle();
      expect(find.byType(PantallaVisorImagen), findsNothing);
    },
  );
}
