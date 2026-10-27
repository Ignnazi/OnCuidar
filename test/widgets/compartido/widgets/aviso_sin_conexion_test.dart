import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/compartido/widgets/aviso_sin_conexion.dart';
import 'package:oncuidar/nucleo/proveedores.dart';

Widget _app({required bool enLinea}) {
  return ProviderScope(
    overrides: [
      estadoConexionProvider.overrideWith((_) => Stream.value(enLinea)),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: NotaSinConexion(texto: TextosSinConexion.iniciarSesion),
      ),
    ),
  );
}

void main() {
  testWidgets('la nota aparece sin conexión', (tester) async {
    await tester.pumpWidget(_app(enLinea: false));
    await tester.pump();
    await tester.pump();

    expect(find.text(TextosSinConexion.iniciarSesion), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
  });

  testWidgets('la nota no aparece con conexión', (tester) async {
    await tester.pumpWidget(_app(enLinea: true));
    await tester.pump();
    await tester.pump();

    expect(find.text(TextosSinConexion.iniciarSesion), findsNothing);
  });
}
