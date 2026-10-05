import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/compartido/widgets/controles_zoom.dart';

void main() {
  group('zoomAlrededor', () {
    test('acerca sin mover el punto que se mira', () {
      const centro = Offset(180, 300);
      final antes = MatrixUtils.transformPoint(Matrix4.identity(), centro);
      final matriz = zoomAlrededor(
        Matrix4.identity(),
        2,
        centro,
        minima: 0.5,
        maxima: 10,
      );

      expect(matriz.getMaxScaleOnAxis(), closeTo(2, 1e-9));
      final despues = MatrixUtils.transformPoint(matriz, centro);
      expect(despues.dx, closeTo(antes.dx, 1e-6));
      expect(despues.dy, closeTo(antes.dy, 1e-6));
    });

    test('se puede acercar y alejar varias veces y volver', () {
      var m = Matrix4.identity();
      const centro = Offset(100, 100);
      for (var i = 0; i < 4; i++) {
        m = zoomAlrededor(m, 1.5, centro, minima: 0.1, maxima: 50);
      }
      for (var i = 0; i < 4; i++) {
        m = zoomAlrededor(m, 1 / 1.5, centro, minima: 0.1, maxima: 50);
      }
      expect(m.getMaxScaleOnAxis(), closeTo(1, 1e-9));
    });

    test('se puede alejar por debajo de 1 las veces que se quiera', () {
      var m = escalaUniforme(0.6);
      expect(escalaDe(m), closeTo(0.6, 1e-9));
      for (final esperado in [0.4, 0.2667, 0.1778]) {
        m = zoomAlrededor(m, 2 / 3, Offset.zero, minima: 0.1, maxima: 8);
        expect(escalaDe(m), closeTo(esperado, 1e-3));
      }
      m = zoomAlrededor(m, 1.5, Offset.zero, minima: 0.1, maxima: 8);
      expect(escalaDe(m), closeTo(0.2667, 1e-3));
    });

    test('respeta el mínimo y el máximo', () {
      var m = Matrix4.identity();
      for (var i = 0; i < 30; i++) {
        m = zoomAlrededor(m, 2, Offset.zero, minima: 1, maxima: 8);
      }
      expect(m.getMaxScaleOnAxis(), 8);
      for (var i = 0; i < 30; i++) {
        m = zoomAlrededor(m, 0.5, Offset.zero, minima: 1, maxima: 8);
      }
      expect(m.getMaxScaleOnAxis(), 1);
    });
  });

  testWidgets('los tres botones avisan', (tester) async {
    final avisos = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ControlesZoom(
            alAcercar: () => avisos.add('más'),
            alAlejar: () => avisos.add('menos'),
            alAjustar: () => avisos.add('ajustar'),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('zoomMas')));
    await tester.tap(find.byKey(const Key('zoomMenos')));
    await tester.tap(find.byKey(const Key('zoomAjustar')));

    expect(avisos, ['más', 'menos', 'ajustar']);
  });
}
