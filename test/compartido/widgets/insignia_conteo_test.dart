import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/compartido/widgets/insignia_conteo.dart';

Widget _envolver(Widget hijo) => MaterialApp(
  home: Scaffold(body: Center(child: hijo)),
);

void main() {
  tearDown(() => Paleta.usar(coloresClaros));

  testWidgets('muestra el total y pasa de 99 a «99+»', (tester) async {
    await tester.pumpWidget(_envolver(const InsigniaConteo(total: 7)));
    expect(find.text('7'), findsOneWidget);

    await tester.pumpWidget(_envolver(const InsigniaConteo(total: 150)));
    expect(find.text('99+'), findsOneWidget);
  });

  for (final (nombre, colores) in [
    ('claro', coloresClaros),
    ('oscuro', coloresOscuros),
  ]) {
    testWidgets('el aro claro separa la insignia del degradado en modo $nombre', (
      tester,
    ) async {
      Paleta.usar(colores);
      await tester.pumpWidget(_envolver(const InsigniaConteo(total: 3)));

      final decoracion =
          tester.widget<Container>(find.byType(Container)).decoration!
              as BoxDecoration;
      expect(decoracion.color, InsigniaConteo.colorFondo());
      expect((decoracion.border! as Border).top.color, Paleta.aroInsignia);
      // El aro es claro en ambos modos.
      expect(Paleta.aroInsignia.computeLuminance(), greaterThan(0.7));
      final numero = tester.widget<Text>(find.text('3'));
      expect(numero.style!.color, const Color(0xFFFFFFFF));
      expect(numero.style!.shadows, isNotEmpty);
    });
  }
}
