import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/app/tema/fundido_de_tema.dart';

Widget _app({required bool oscuro}) => MaterialApp(
  home: FundidoDeTema(
    oscuro: oscuro,
    child: ColoredBox(
      color: oscuro ? Colors.black : Colors.white,
      child: const Center(child: Text('contenido')),
    ),
  ),
);

void main() {
  testWidgets('al cambiar de modo deja la foto anterior y la desvanece', (
    tester,
  ) async {
    await tester.pumpWidget(_app(oscuro: false));
    expect(find.byKey(const Key('fotoModoAnterior')), findsNothing);

    await tester.pumpWidget(_app(oscuro: true));
    await tester.pump();
    expect(find.byKey(const Key('fotoModoAnterior')), findsOneWidget);

    await tester.pump(FundidoDeTema.duracion ~/ 2);
    final enMedio = tester.widget<Opacity>(
      find.ancestor(
        of: find.byKey(const Key('fotoModoAnterior')),
        matching: find.byType(Opacity),
      ),
    );
    expect(enMedio.opacity, inExclusiveRange(0, 1));

    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fotoModoAnterior')), findsNothing);
    expect(find.text('contenido'), findsOneWidget);
  });

  testWidgets('sin cambio de modo no se crea ninguna foto', (tester) async {
    await tester.pumpWidget(_app(oscuro: false));
    await tester.pumpWidget(_app(oscuro: false));
    await tester.pump();

    expect(find.byKey(const Key('fotoModoAnterior')), findsNothing);
  });

  testWidgets('la foto no bloquea los toques sobre la pantalla', (
    tester,
  ) async {
    var toques = 0;
    Widget app(bool oscuro) => MaterialApp(
      home: FundidoDeTema(
        oscuro: oscuro,
        child: Center(
          child: TextButton(
            onPressed: () => toques++,
            child: const Text('tocar'),
          ),
        ),
      ),
    );
    await tester.pumpWidget(app(false));
    await tester.pumpWidget(app(true));
    await tester.pump();

    await tester.tap(find.text('tocar'));
    expect(toques, 1);
    await tester.pumpAndSettle();
  });
}
