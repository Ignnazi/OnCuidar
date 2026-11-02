import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/compartido/widgets/boton_principal.dart';

Widget _envolver(Widget hijo) => MaterialApp(
  home: Scaffold(body: Center(child: hijo)),
);

void main() {
  testWidgets('el botón destacado es relleno y ejecuta la acción', (
    tester,
  ) async {
    var pulsaciones = 0;
    await tester.pumpWidget(
      _envolver(
        BotonPrincipal(etiqueta: 'Guardar', alPulsar: () => pulsaciones++),
      ),
    );

    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.text('Guardar'), findsOneWidget);

    await tester.tap(find.byType(ElevatedButton));
    expect(pulsaciones, 1);
  });

  testWidgets('sin destacar usa el botón con borde y ejecuta la acción', (
    tester,
  ) async {
    var pulsaciones = 0;
    await tester.pumpWidget(
      _envolver(
        BotonPrincipal(
          etiqueta: 'Cancelar',
          destacado: false,
          alPulsar: () => pulsaciones++,
        ),
      ),
    );

    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNothing);

    await tester.tap(find.byType(OutlinedButton));
    expect(pulsaciones, 1);
  });

  testWidgets('una etiqueta larga se reduce en lugar de desbordar', (
    tester,
  ) async {
    await tester.pumpWidget(
      _envolver(
        SizedBox(
          width: 120,
          child: BotonPrincipal(
            etiqueta: 'Una etiqueta muy larga para un botón angosto',
            alPulsar: () {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(FittedBox), findsOneWidget);
  });
}
