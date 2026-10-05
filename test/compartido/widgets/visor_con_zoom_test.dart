import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/compartido/widgets/visor_con_zoom.dart';

void main() {
  double total(WidgetTester tester) =>
      tester.state<EstadoVisorConZoom>(find.byType(VisorConZoom)).escalaTotal;

  Future<void> abrir(WidgetTester tester, {double inicial = 1}) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VisorConZoom(
            claveVisor: const Key('visor'),
            zoomMinimo: (_) => 0.5,
            zoomMaximo: 6,
            escalaInicial: (_) => inicial,
            escalaAjuste: (_) => 1,
            constructor: (_, factor) =>
                Container(width: 400, height: 1600, color: Colors.teal),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pellizco(
    WidgetTester tester, {
    required double desde,
    required double hasta,
  }) async {
    const centro = Offset(200, 400);
    final a = await tester.startGesture(centro - Offset(desde, 0));
    final b = await tester.startGesture(centro + Offset(desde, 0));
    await tester.pump();
    const pasos = 10;
    for (var i = 1; i <= pasos; i++) {
      final d = desde + (hasta - desde) * i / pasos;
      await a.moveTo(centro - Offset(d, 0));
      await b.moveTo(centro + Offset(d, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await a.up();
    await b.up();
    await tester.pumpAndSettle();
  }

  testWidgets('separar los dedos acerca', (tester) async {
    await abrir(tester);
    await pellizco(tester, desde: 40, hasta: 120);
    expect(total(tester), greaterThan(1.5));
  });

  testWidgets('juntar los dedos aleja', (tester) async {
    await abrir(tester, inicial: 2);
    await pellizco(tester, desde: 120, hasta: 40);
    expect(total(tester), lessThan(1.5));
    expect(total(tester), greaterThanOrEqualTo(0.5));
  });

  testWidgets('el pellizco no pasa del máximo', (tester) async {
    await abrir(tester);
    for (var i = 0; i < 4; i++) {
      await pellizco(tester, desde: 20, hasta: 150);
    }
    expect(total(tester), lessThanOrEqualTo(6.0001));
  });

  testWidgets('doble toque acerca y otro doble toque vuelve', (tester) async {
    await abrir(tester);
    final zona = find.byKey(const Key('visor'));

    await tester.tap(zona);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(zona);
    await tester.pumpAndSettle();
    expect(total(tester), closeTo(2, 0.05));

    await tester.tap(zona);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(zona);
    await tester.pumpAndSettle();
    expect(total(tester), closeTo(1, 0.05));
  });

  testWidgets('los botones acercan, alejan y ajustan', (tester) async {
    await abrir(tester);

    await tester.tap(find.byKey(const Key('zoomMas')));
    await tester.tap(find.byKey(const Key('zoomMas')));
    expect(total(tester), closeTo(2.25, 0.01));

    await tester.tap(find.byKey(const Key('zoomMenos')));
    expect(total(tester), closeTo(1.5, 0.01));

    await tester.tap(find.byKey(const Key('zoomAjustar')));
    expect(total(tester), closeTo(1, 0.01));
  });

  testWidgets(
    'con contenido más bajo que la pantalla no salta al tocar y se puede alejar',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisorConZoom(
              claveVisor: const Key('visor'),
              constructor: (zona, factor) => Container(
                width: zona.width * factor,
                height: 250 * factor,
                color: Colors.teal,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byKey(const Key('visor')), const Offset(0, 30));
      await tester.pumpAndSettle();
      expect(total(tester), closeTo(1, 0.01));

      Future<void> pellizco(double desde, double hasta) async {
        const centro = Offset(200, 400);
        final a = await tester.startGesture(centro - Offset(desde, 0));
        final b = await tester.startGesture(centro + Offset(desde, 0));
        for (var i = 1; i <= 10; i++) {
          final d = desde + (hasta - desde) * i / 10;
          await a.moveTo(centro - Offset(d, 0));
          await b.moveTo(centro + Offset(d, 0));
          await tester.pump(const Duration(milliseconds: 16));
        }
        await a.up();
        await b.up();
        await tester.pumpAndSettle();
      }

      await pellizco(40, 120);
      expect(total(tester), greaterThan(1.5));
      await pellizco(120, 20);
      expect(total(tester), closeTo(1, 0.05));
    },
  );
}
