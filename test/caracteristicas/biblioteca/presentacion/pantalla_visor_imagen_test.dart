import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/app/proveedores_navegacion.dart';
import 'package:oncuidar/caracteristicas/biblioteca/datos/proveedores_biblioteca.dart';
import 'package:oncuidar/caracteristicas/biblioteca/datos/servicio_cache_contenido.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/pantalla_visor_imagen.dart';
import 'package:oncuidar/compartido/widgets/visor_con_zoom.dart';
import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
import 'package:oncuidar/nucleo/proveedores.dart';

const _clavePrueba = 'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';
const _uid = 'uid-visor';
const _id = 'infografias-guia-de-seguimiento';

class _CacheFalso implements ServicioCacheContenido {
  @override
  Future<File?> archivoEnCache(String url) async => null;

  @override
  Future<File> descargar(String url) async => throw Exception('sin red');

  @override
  Future<bool> archivoDescargado(String url) async => false;

  @override
  Future<void> eliminar(String url) async {}
}

void main() {
  late FakeFirebaseFirestore firestore;
  late ProviderContainer contenedor;

  Future<void> abrir(WidgetTester tester) async {
    firestore = FakeFirebaseFirestore();
    final base = BaseDatosSegura(
      base: firestore,
      uidPrueba: _uid,
      cifrado: ServicioCifrado(clavePrueba: _clavePrueba),
    );
    contenedor = ProviderContainer(
      overrides: [
        baseDatosSeguraProvider.overrideWith((_) => base),
        servicioCacheContenidoProvider.overrideWithValue(_CacheFalso()),
      ],
    );
    addTearDown(contenedor.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: contenedor,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => abrirVisorImagen(
                  context,
                  url: 'https://localhost/guia.png',
                  titulo: 'Guía de seguimiento',
                  idMaterial: _id,
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('se abre a pantalla completa sobre fondo oscuro', (tester) async {
    await abrir(tester);

    final scaffold = tester.widget<Scaffold>(
      find.descendant(
        of: find.byType(PantallaVisorImagen),
        matching: find.byType(Scaffold),
      ),
    );
    expect(scaffold.backgroundColor!.computeLuminance(), lessThan(0.01));
    expect(find.text('Guía de seguimiento'), findsOneWidget);
    final visor = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    expect(visor.minScale, 1);
    expect(visor.maxScale, 8);
  });

  testWidgets('es la misma pantalla que las guías: zoom con botones y giro', (
    tester,
  ) async {
    await abrir(tester);

    expect(find.byType(VisorConZoom), findsOneWidget);
    expect(find.byKey(const Key('zoomMas')), findsOneWidget);
    expect(find.byKey(const Key('girarVisor')), findsOneWidget);
  });

  testWidgets('volver cierra el visor', (tester) async {
    await abrir(tester);

    await tester.tap(find.byKey(const Key('cerrarVisorImagen')));
    await tester.pumpAndSettle();

    expect(find.byType(PantallaVisorImagen), findsNothing);
  });

  testWidgets(
    'abre encima de toda la app, sin ocultar la barra inferior después',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final contenedorLocal = ProviderContainer(
        overrides: [
          servicioCacheContenidoProvider.overrideWithValue(_CacheFalso()),
        ],
      );
      addTearDown(contenedorLocal.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: contenedorLocal,
          child: MaterialApp(
            home: Scaffold(
              bottomNavigationBar: const SizedBox(
                height: 60,
                child: Text('barra inferior'),
              ),
              body: Navigator(
                onGenerateRoute: (_) => MaterialPageRoute<void>(
                  builder: (interno) => Center(
                    child: TextButton(
                      onPressed: () => abrirVisorImagen(
                        interno,
                        url: 'https://localhost/guia.png',
                        titulo: 'Guía',
                      ),
                      child: const Text('abrir'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final alAbrir = tester.getSize(find.byKey(const Key('areaVisorImagen')));
      await tester.pumpAndSettle();
      final final_ = tester.getSize(find.byKey(const Key('areaVisorImagen')));

      expect(final_, alAbrir);
      expect(find.text('barra inferior'), findsNothing);
      expect(contenedorLocal.read(pantallaCompletaProvider), isFalse);

      await tester.tap(find.byKey(const Key('cerrarVisorImagen')));
      await tester.pumpAndSettle();
      expect(find.text('barra inferior'), findsOneWidget);
    },
  );
}
