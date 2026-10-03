import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/app/enrutador/destino_aviso.dart';
import 'package:oncuidar/caracteristicas/autenticacion/presentacion/pantalla_carga.dart';
import 'package:oncuidar/nucleo/proveedores.dart';

void main() {
  setUp(EstadoArranque.reiniciar);
  tearDown(EstadoArranque.reiniciar);

  testWidgets(
    'sin sesión el Splash guarda el destino y sigue a la bienvenida',
    (tester) async {
      var finalizo = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firebaseAuthProvider.overrideWithValue(MockFirebaseAuth()),
          ],
          child: MaterialApp(
            home: Splash(
              destino: '/recordatorios',
              alFinalizar: () => finalizo = true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 3));

      expect(finalizo, isTrue);
      expect(EstadoArranque.completado, isTrue);
      expect(EstadoArranque.destinoPendiente, '/recordatorios');
      expect(EstadoArranque.consumirDestino(), '/recordatorios');
    },
  );

  testWidgets('sin sesión un destino inseguro no se guarda', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [firebaseAuthProvider.overrideWithValue(MockFirebaseAuth())],
        child: MaterialApp(
          home: Splash(destino: '//sitio-externo.cl', alFinalizar: () {}),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 3));

    expect(EstadoArranque.destinoPendiente, isNull);
  });
}
