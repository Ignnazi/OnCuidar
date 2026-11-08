import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/app/cerrar_teclado_al_tocar_fuera.dart';

Future<void> _montar(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => CerrarTecladoAlTocarFuera(child: child!),
      home: Scaffold(
        body: ListView(
          children: const [
            TextField(key: Key('campo')),
            SizedBox(height: 1200, key: Key('vacio')),
          ],
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('campo')));
  await tester.pump();
  expect(tester.testTextInput.isVisible, isTrue);
}

void main() {
  testWidgets('tocar fuera del campo cierra el teclado', (tester) async {
    await _montar(tester);
    await tester.tapAt(const Offset(200, 400));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('desplazar la pantalla no cierra el teclado', (tester) async {
    await _montar(tester);
    await tester.dragFrom(const Offset(200, 400), const Offset(0, -150));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('tocar dentro del campo lo deja abierto', (tester) async {
    await _montar(tester);
    await tester.tap(find.byKey(const Key('campo')));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);
  });
}
