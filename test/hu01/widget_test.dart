import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/core/proveedores/proveedores.dart';
import 'package:oncuidar/main.dart';

void main() {
  testWidgets('inicia en splash y navega a bienvenida', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(MockFirebaseAuth()),
        ],
        child: const OncuidarApp(),
      ),
    );

    expect(find.text('Oncuidar'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2100));
    await tester.pump();

    expect(find.text('Te damos la bienvenida'), findsOneWidget);
  });
}