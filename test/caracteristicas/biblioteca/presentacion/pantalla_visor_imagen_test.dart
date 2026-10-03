import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/app/proveedores_navegacion.dart';
import 'package:oncuidar/caracteristicas/biblioteca/datos/proveedores_biblioteca.dart';
import 'package:oncuidar/caracteristicas/biblioteca/datos/servicio_cache_contenido.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/pantalla_visor_imagen.dart';
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

  double escala(WidgetTester tester) => tester
      .widget<InteractiveViewer>(find.byType(InteractiveViewer))
      .transformationController!
      .value
      .getMaxScaleOnAxis();

  double opacidadBarra(WidgetTester tester) => tester
      .widget<AnimatedOpacity>(find.byKey(const Key('barraVisorImagen')))
      .opacity;

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
    expect(contenedor.read(pantallaCompletaProvider), isTrue);
    final visor = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    expect(visor.minScale, 1);
    expect(visor.maxScale, 5);
  });

  testWidgets('un toque oculta y muestra la barra superior', (tester) async {
    await abrir(tester);
    expect(opacidadBarra(tester), 1);

    await tester.tap(find.byKey(const Key('areaVisorImagen')));
    await tester.pump(kDoubleTapTimeout + const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    expect(opacidadBarra(tester), 0);

    await tester.tap(find.byKey(const Key('areaVisorImagen')));
    await tester.pump(kDoubleTapTimeout + const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    expect(opacidadBarra(tester), 1);
  });

  testWidgets('el doble toque acerca y vuelve al tamaño original', (
    tester,
  ) async {
    await abrir(tester);
    final centro = tester.getCenter(find.byKey(const Key('areaVisorImagen')));

    Future<void> dobleToque() async {
      await tester.tapAt(centro);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(centro);
      await tester.pumpAndSettle();
    }

    expect(escala(tester), 1);
    await dobleToque();
    expect(escala(tester), closeTo(escalaDobleToque, 0.01));
    await dobleToque();
    expect(escala(tester), closeTo(1, 0.01));
  });

  testWidgets('volver cierra el visor y devuelve la barra inferior', (
    tester,
  ) async {
    await abrir(tester);

    await tester.tap(find.byKey(const Key('cerrarVisorImagen')));
    await tester.pumpAndSettle();

    expect(find.byType(PantallaVisorImagen), findsNothing);
    expect(contenedor.read(pantallaCompletaProvider), isFalse);
  });
}
