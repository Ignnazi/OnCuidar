import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/biblioteca/datos/proveedores_biblioteca.dart';
import 'package:oncuidar/caracteristicas/biblioteca/datos/repositorio_biblioteca.dart';
import 'package:oncuidar/caracteristicas/biblioteca/datos/servicio_cache_contenido.dart';
import 'package:oncuidar/caracteristicas/biblioteca/datos/servicio_cache_metadata.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/material_educativo.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/proveedores_biblioteca.dart';
import 'package:oncuidar/caracteristicas/perfil/datos/repositorio_cuidador.dart';
import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
import 'package:oncuidar/nucleo/proveedores.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _clavePrueba = 'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';
const _uid = 'uid-1';

const _urlVideo =
    'https://firebasestorage.googleapis.com/v0/b/oncuidar-v1.firebasestorage.app/o/videos%2Fprueba.mp4?alt=media';
const _urlPdf =
    'https://firebasestorage.googleapis.com/v0/b/oncuidar-v1.firebasestorage.app/o/Guias%2Fprueba.pdf?alt=media';
const _urlMiniatura =
    'https://firebasestorage.googleapis.com/v0/b/oncuidar-v1.firebasestorage.app/o/miniaturas%2Fprueba.png?alt=media';
const _urlImagen =
    'https://firebasestorage.googleapis.com/v0/b/oncuidar-v1.firebasestorage.app/o/infografias%2Fprueba.png?alt=media';

MaterialEducativo _video() => MaterialEducativo(
  id: 'videos-como-medir-la-fiebre',
  titulo: 'Cómo medir la fiebre',
  categoria: 'Videos',
  tema: 'Fiebre',
  cuerpo: 'Video paso a paso.',
  urlArchivo: _urlVideo,
  tipoArchivo: 'video',
  tamanoBytes: 20000000,
  creadoEn: DateTime.utc(2026, 1, 1),
);

MaterialEducativo _videoConImagenes() => MaterialEducativo(
  id: 'videos-como-medir-la-fiebre',
  titulo: 'Cómo medir la fiebre',
  categoria: 'Videos',
  tema: 'Fiebre',
  cuerpo: 'Video paso a paso.',
  urlArchivo: _urlVideo,
  urlMiniatura: _urlMiniatura,
  urlImagen: _urlImagen,
  tipoArchivo: 'video',
  tamanoBytes: 20000000,
  creadoEn: DateTime.utc(2026, 1, 1),
);

MaterialEducativo _guia() => MaterialEducativo(
  id: 'guias-manual-de-control-de-sintomas',
  titulo: 'Manual de Control de Síntomas',
  categoria: 'Guías',
  tema: 'Cuidados Paliativos',
  cuerpo: 'Guía práctica.',
  urlArchivo: _urlPdf,
  tipoArchivo: 'pdf',
  tamanoBytes: 3000000,
  creadoEn: DateTime.utc(2026, 1, 2),
);

MaterialEducativo _checklist() => MaterialEducativo(
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
  int descargasRed = 0;

  @override
  Future<File?> archivoEnCache(String url) async =>
      descargados.contains(url) ? File(url) : null;

  @override
  Future<File> descargar(String url) async {
    if (!descargados.contains(url)) {
      if (fallar.contains(url)) throw Exception('descarga fallida');
      descargados.add(url);
      descargasRed++;
    }
    return File(url);
  }

  @override
  Future<bool> archivoDescargado(String url) async => descargados.contains(url);

  @override
  Future<void> eliminar(String url) async {
    descargados.remove(url);
  }
}

class _RepositorioSinRed extends RepositorioBiblioteca {
  _RepositorioSinRed()
    : super(
        BaseDatosSegura(
          base: FakeFirebaseFirestore(),
          uidPrueba: _uid,
          cifrado: ServicioCifrado(clavePrueba: _clavePrueba),
        ),
      );

  @override
  Stream<List<MaterialEducativo>> contenidoEducativoEnTiempoReal() {
    throw Exception('sin conexión');
  }
}

Future<BaseDatosSegura> _baseConContenido(
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
  return base;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ServicioCacheMetadata', () {
    test('guarda y recupera el catálogo con su marca de tiempo', () async {
      final servicio = ServicioCacheMetadata();
      expect(await servicio.obtenerCatalogoCache(), (
        const <MaterialEducativo>[],
        null,
      ));

      await servicio.guardarCatalogo([_video(), _guia()]);

      final (cacheados, marca) = await servicio.obtenerCatalogoCache();
      expect(cacheados, hasLength(2));
      expect(cacheados.first.id, 'videos-como-medir-la-fiebre');
      expect(marca, isNotNull);
      expect(
        servicio.esReciente(timestamp: marca),
        isTrue,
        reason: 'recién guardado debe considerarse vigente',
      );
    });

    test('esReciente considera viejo un catálogo de hace un día', () {
      final servicio = ServicioCacheMetadata();
      final ahora = DateTime.utc(2026, 1, 10, 12);
      final marca = ahora
          .subtract(const Duration(hours: 23))
          .millisecondsSinceEpoch;

      expect(
        servicio.esReciente(timestamp: marca, ahora: ahora),
        isTrue,
        reason: 'menos de 24 h sigue siendo reciente',
      );
      expect(
        servicio.esReciente(
          timestamp: ahora
              .subtract(const Duration(hours: 25))
              .millisecondsSinceEpoch,
          ahora: ahora,
        ),
        isFalse,
      );
      expect(servicio.esReciente(timestamp: null, ahora: ahora), isFalse);
    });
  });

  group('SincronizacionNotifier', () {
    test('descarga los adjuntos y reporta el progreso', () async {
      final cache = _CacheFalso();
      final container = ProviderContainer(
        overrides: [servicioCacheContenidoProvider.overrideWithValue(cache)],
      );
      addTearDown(container.dispose);

      final estadoInicial = container.read(sincronizacionBibliotecaProvider);
      expect(estadoInicial.activa, isFalse);

      await container
          .read(sincronizacionBibliotecaProvider.notifier)
          .sincronizar([_video(), _guia(), _checklist()]);

      final estado = container.read(sincronizacionBibliotecaProvider);
      expect(estado.total, 2);
      expect(estado.completadas, 2);
      expect(estado.progreso, 1.0);
      expect(estado.terminada, isTrue);
      expect(estado.activa, isFalse);
      expect(cache.descargados, contains(_urlVideo));
      expect(cache.descargados, contains(_urlPdf));
      expect(
        container.read(contenidosDescargadosProvider),
        containsAll([_urlVideo, _urlPdf]),
      );
    });
  });

  group('sincronizarAlIniciarSesion', () {
    test(
      'descarga archivo, miniatura e imagen, y guarda el catálogo',
      () async {
        final base = await _baseConContenido([
          _videoConImagenes(),
          _guia(),
          _checklist(),
        ]);
        final cache = _CacheFalso();
        final metadata = ServicioCacheMetadata();
        final container = ProviderContainer(
          overrides: [
            baseDatosSeguraProvider.overrideWith((_) => base),
            servicioCacheContenidoProvider.overrideWithValue(cache),
            servicioCacheMetadataProvider.overrideWithValue(metadata),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(sincronizacionBibliotecaProvider.notifier)
            .sincronizarAlIniciarSesion();

        final estado = container.read(sincronizacionBibliotecaProvider);
        expect(estado.terminada, isTrue);
        expect(estado.activa, isFalse);
        expect(estado.conErrores, isFalse);
        expect(estado.total, 4);
        expect(estado.completadas, 4);
        expect(
          cache.descargados,
          containsAll([_urlVideo, _urlPdf, _urlMiniatura, _urlImagen]),
        );

        final (cacheados, marca) = await metadata.obtenerCatalogoCache();
        expect(marca, isNotNull);
        expect(
          cacheados.map((c) => c.id),
          containsAll([
            'videos-como-medir-la-fiebre',
            'guias-manual-de-control-de-sintomas',
          ]),
        );
      },
    );

    test('no re-descarga lo que ya está en caché', () async {
      final base = await _baseConContenido([_videoConImagenes(), _guia()]);
      final cache = _CacheFalso();
      final container = ProviderContainer(
        overrides: [
          baseDatosSeguraProvider.overrideWith((_) => base),
          servicioCacheContenidoProvider.overrideWithValue(cache),
          servicioCacheMetadataProvider.overrideWithValue(
            ServicioCacheMetadata(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(sincronizacionBibliotecaProvider.notifier)
          .sincronizarAlIniciarSesion();
      final trasPrimera = cache.descargasRed;
      expect(trasPrimera, 4);

      await container
          .read(sincronizacionBibliotecaProvider.notifier)
          .sincronizarAlIniciarSesion();
      expect(cache.descargasRed, trasPrimera);
    });

    test('no aborta si una descarga falla y reporta las fallidas', () async {
      final base = await _baseConContenido([_videoConImagenes(), _guia()]);
      final cache = _CacheFalso()..fallar.add(_urlImagen);
      final container = ProviderContainer(
        overrides: [
          baseDatosSeguraProvider.overrideWith((_) => base),
          servicioCacheContenidoProvider.overrideWithValue(cache),
          servicioCacheMetadataProvider.overrideWithValue(
            ServicioCacheMetadata(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(sincronizacionBibliotecaProvider.notifier)
          .sincronizarAlIniciarSesion();

      final estado = container.read(sincronizacionBibliotecaProvider);
      expect(estado.terminada, isTrue);
      expect(estado.conErrores, isTrue);
      expect(estado.fallidas, 1);
      expect(estado.completadas, 3);
      expect(cache.descargados, contains(_urlVideo));
      expect(cache.descargados, contains(_urlMiniatura));
      expect(cache.descargados, contains(_urlPdf));
      expect(cache.descargados, isNot(contains(_urlImagen)));
    });

    test(
      'lo que falló se descarga en el siguiente inicio de sesión (CA-18.3)',
      () async {
        final base = await _baseConContenido([_videoConImagenes(), _guia()]);
        final cache = _CacheFalso()..fallar.add(_urlImagen);
        final metadata = ServicioCacheMetadata();
        Future<SincronizacionEstado> iniciarSesion() async {
          final container = ProviderContainer(
            overrides: [
              baseDatosSeguraProvider.overrideWith((_) => base),
              servicioCacheContenidoProvider.overrideWithValue(cache),
              servicioCacheMetadataProvider.overrideWithValue(metadata),
            ],
          );
          addTearDown(container.dispose);
          await container
              .read(sincronizacionBibliotecaProvider.notifier)
              .sincronizarAlIniciarSesion();
          return container.read(sincronizacionBibliotecaProvider);
        }

        final primera = await iniciarSesion();
        expect(primera.fallidas, 1);
        expect(cache.descargados, isNot(contains(_urlImagen)));

        cache.fallar.clear();
        final segunda = await iniciarSesion();
        expect(segunda.fallidas, 0);
        expect(segunda.conErrores, isFalse);
        expect(cache.descargados, contains(_urlImagen));
      },
    );

    test('sin contenido marca el sincronizado y no descarga', () async {
      final base = await _baseConContenido(const []);
      final cache = _CacheFalso();
      final container = ProviderContainer(
        overrides: [
          baseDatosSeguraProvider.overrideWith((_) => base),
          servicioCacheContenidoProvider.overrideWithValue(cache),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(sincronizacionBibliotecaProvider.notifier)
          .sincronizarAlIniciarSesion();

      final estado = container.read(sincronizacionBibliotecaProvider);
      expect(estado.terminada, isTrue);
      expect(estado.total, 0);
      expect(cache.descargados, isEmpty);
    });
  });

  group('contenidosEducativosProvider', () {
    test('sirve el catálogo de Firestore y lo guarda en caché', () async {
      final base = await _baseConContenido([_video(), _guia(), _checklist()]);
      final cache = _CacheFalso();
      final metadata = ServicioCacheMetadata();
      final container = ProviderContainer(
        overrides: [
          baseDatosSeguraProvider.overrideWith((_) => base),
          servicioCacheContenidoProvider.overrideWithValue(cache),
          servicioCacheMetadataProvider.overrideWithValue(metadata),
        ],
      );
      addTearDown(container.dispose);
      final subscripcion = container.listen(
        contenidosEducativosProvider,
        (_, _) {},
      );

      final contenidos = await container.read(
        contenidosEducativosProvider.future,
      );
      expect(
        contenidos.map((c) => c.id),
        containsAll([
          'videos-como-medir-la-fiebre',
          'guias-manual-de-control-de-sintomas',
          'checklist-preparacion-para-consulta-oncologica',
        ]),
      );

      final (cacheados, marca) = await metadata.obtenerCatalogoCache();
      expect(marca, isNotNull);
      expect(
        cacheados.map((c) => c.id),
        contains('videos-como-medir-la-fiebre'),
      );

      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(
        cache.descargados,
        containsAll([_urlVideo, _urlPdf]),
        reason: 'la sincronización descarga los adjuntos del catálogo',
      );
      subscripcion.close();
    });

    test('sirve el catálogo cacheado cuando Firestore falla', () async {
      final metadata = ServicioCacheMetadata();
      await metadata.guardarCatalogo([_video(), _guia()]);
      final cache = _CacheFalso();
      final container = ProviderContainer(
        overrides: [
          repositorioBibliotecaProvider.overrideWith(
            (_) => _RepositorioSinRed(),
          ),
          servicioCacheContenidoProvider.overrideWithValue(cache),
          servicioCacheMetadataProvider.overrideWithValue(metadata),
        ],
      );
      addTearDown(container.dispose);
      final subscripcion = container.listen(
        contenidosEducativosProvider,
        (_, _) {},
      );

      final contenidos = await container.read(
        contenidosEducativosProvider.future,
      );
      expect(
        contenidos.map((c) => c.id),
        containsAll([
          'videos-como-medir-la-fiebre',
          'guias-manual-de-control-de-sintomas',
        ]),
        reason: 'sin red se ofrece la copia local reciente',
      );
      subscripcion.close();
    });
  });
}
