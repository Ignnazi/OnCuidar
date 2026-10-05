
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:oncuidar/caracteristicas/autenticacion/presentacion/pantalla_iniciar_sesion.dart';
import 'package:oncuidar/caracteristicas/perfil/datos/repositorio_cuidador.dart';
import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
import 'package:oncuidar/nucleo/proveedores.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _clavePrueba = 'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';
const _uid = 'uid-test';

ServicioCifrado _cifradoListo() => ServicioCifrado(clavePrueba: _clavePrueba);

MockFirebaseAuth _authConSesion() => MockFirebaseAuth(
  mockUser: MockUser(uid: _uid, email: 'ana@correo.cl'),
);

Future<BaseDatosSegura> _baseConCuidador(ServicioCifrado cifrado) async {
  await cifrado.fijarClave(_uid, _clavePrueba);
  final base = BaseDatosSegura(
    base: FakeFirebaseFirestore(),
    uidPrueba: _uid,
    cifrado: cifrado,
  );
  await RepositorioCuidador(base).crearCuidador({
    'nombre': 'Ana Torres',
    'correo': 'ana@correo.cl',
    'telefono': '+56 9 1111 1111',
    'relacion': 'Madre',
  });
  return base;
}

Future<void> _pantallaAlta(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _ingresarCredenciales(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  await tester.enterText(
    find.widgetWithText(TextField, 'correo@ejemplo.com'),
    email,
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'Tu contraseña'),
    password,
  );
}

Widget _pantallaLogin(
  MockFirebaseAuth auth,
  BaseDatosSegura base,
  ServicioCifrado cifrado,
) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (c, s) => const IniciarSesion()),
      GoRoute(
        path: '/dashboard',
        builder: (c, s) =>
            const Scaffold(body: Center(child: Text('Dashboard'))),
      ),
      GoRoute(
        path: '/crear-cuenta',
        builder: (c, s) =>
            const Scaffold(body: Center(child: Text('Registro'))),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      firebaseAuthProvider.overrideWithValue(auth),
      servicioCifradoProvider.overrideWithValue(cifrado),
      baseDatosSeguraProvider.overrideWith((ref) => base),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('iniciar sesion valido desbloquea clave y navega al dashboard', (
    tester,
  ) async {
    await _pantallaAlta(tester);
    final auth = _authConSesion();
    final cifrado = _cifradoListo();
    final base = await _baseConCuidador(cifrado);
    await tester.pumpWidget(_pantallaLogin(auth, base, cifrado));
    await tester.pumpAndSettle();

    await _ingresarCredenciales(
      tester,
      email: 'ana@correo.cl',
      password: 'secreto123',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(auth.currentUser, isNotNull);
    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets('contrasena incorrecta muestra el error y no navega', (
    tester,
  ) async {
    await _pantallaAlta(tester);
    final auth = MockFirebaseAuth();
    final cifrado = _cifradoListo();
    final base = await _baseConCuidador(cifrado);
    whenCalling(
          Invocation.method(#signInWithEmailAndPassword, null, {
            #email: 'ana@correo.cl',
            #password: 'malaclave',
          }),
        )
        .on(auth)
        .thenThrow(
          FirebaseAuthException(
            code: 'wrong-password',
            message: 'The password is invalid',
          ),
        );
    await tester.pumpWidget(_pantallaLogin(auth, base, cifrado));
    await tester.pumpAndSettle();

    await _ingresarCredenciales(
      tester,
      email: 'ana@correo.cl',
      password: 'malaclave',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('La contraseña es incorrecta.'), findsOneWidget);
    expect(find.text('Dashboard'), findsNothing);
  });

  testWidgets('credencial invalida muestra correo o contrasena incorrectos', (
    tester,
  ) async {
    await _pantallaAlta(tester);
    final auth = MockFirebaseAuth();
    final cifrado = _cifradoListo();
    final base = await _baseConCuidador(cifrado);
    whenCalling(
          Invocation.method(#signInWithEmailAndPassword, null, {
            #email: 'ana@correo.cl',
            #password: 'malaclave',
          }),
        )
        .on(auth)
        .thenThrow(
          FirebaseAuthException(
            code: 'invalid-credential',
            message: 'The supplied auth credential is incorrect',
          ),
        );
    await tester.pumpWidget(_pantallaLogin(auth, base, cifrado));
    await tester.pumpAndSettle();

    await _ingresarCredenciales(
      tester,
      email: 'ana@correo.cl',
      password: 'malaclave',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
    expect(find.text('Dashboard'), findsNothing);
  });

  testWidgets('recuperar contrasena envia correo de restablecimiento', (
    tester,
  ) async {
    await _pantallaAlta(tester);
    final auth = _authConSesion();
    final cifrado = _cifradoListo();
    final base = await _baseConCuidador(cifrado);
    await tester.pumpWidget(_pantallaLogin(auth, base, cifrado));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'correo@ejemplo.com'),
      'ana@correo.cl',
    );
    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await tester.pumpAndSettle();

    expect(
      find.text('Te enviamos un correo para restablecer tu contraseña.'),
      findsOneWidget,
    );
  });



}
