import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/presentacion/widgets/selector_multi_sintoma.dart';

Future<List<String>> _montar(WidgetTester tester) async {
  final alternados = <String>[];
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SelectorMultiSintoma(
          seleccionados: const {},
          onAlternar: alternados.add,
          onCerrar: () {},
        ),
      ),
    ),
  );
  return alternados;
}

void main() {
  testWidgets('el campo para agregar un síntoma está oculto al abrir', (
    tester,
  ) async {
    await _montar(tester);
    expect(find.byKey(const Key('botonAgregarSintoma')), findsOneWidget);
    expect(find.byKey(const Key('campoAgregarSintoma')), findsNothing);
    expect(find.text('Fatiga'), findsOneWidget);
  });

  testWidgets('el + abre el campo y agrega el síntoma escrito', (tester) async {
    final alternados = await _montar(tester);
    await tester.tap(find.byKey(const Key('botonAgregarSintoma')));
    await tester.pumpAndSettle();

    final campo = find.byKey(const Key('campoAgregarSintoma'));
    expect(campo, findsOneWidget);
    await tester.enterText(campo, 'Picazón');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(alternados, ['Picazón']);
    expect(find.byKey(const Key('campoAgregarSintoma')), findsNothing);
  });

  testWidgets('el + muestra el campo sin abrir el teclado solo', (
    tester,
  ) async {
    await _montar(tester);
    await tester.tap(find.byKey(const Key('botonAgregarSintoma')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('campoAgregarSintoma')), findsOneWidget);
    expect(tester.testTextInput.isVisible, isFalse);

    await tester.tap(find.byKey(const Key('campoAgregarSintoma')));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);
  });
}
