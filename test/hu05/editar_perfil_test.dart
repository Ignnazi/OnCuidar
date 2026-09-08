import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oncuidar/caracteristicas/perfil/editar_perfil.dart';
import 'package:oncuidar/core/proveedores/proveedores.dart';
import 'package:oncuidar/core/servicios/servicio_base_datos.dart';
import 'package:oncuidar/core/servicios/servicio_cifrado.dart';

const _clavePrueba = 'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';
const _uid = 'uid-test';

MockFirebaseAuth _authConSesion() => MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: _uid, email: 'ana@correo.cl'),
    );

Future<ServicioBaseDatos> _baseConCuidador(
  ServicioCifrado cifrado, {
  FakeFirebaseFirestore? fake,
}) async {
  await cifrado.fijarClave(_uid, _clavePrueba);
  final base = ServicioBaseDatos(
    base: fake ?? FakeFirebaseFirestore(),
    uidPrueba: _uid,
    cifrado: cifrado,
  );
  await base.crearCuidador({
    'displayName': 'Ana Torres',
    'email': 'ana@correo.cl',
    'phone': '+56 9 1111 1111',
    'relationship': 'Madre',
  });
  return base;
}

void main() {
  testWidgets('editar perfil carga datos y guarda cambios', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = _authConSesion();
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    final fake = FakeFirebaseFirestore();
    final base = await _baseConCuidador(cifrado, fake: fake);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (c, s) => const EditarPerfil()),
        GoRoute(
          path: '/perfil',
          builder: (c, s) => const Scaffold(
            body: Center(child: Text('Perfil')),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
          servicioCifradoProvider.overrideWithValue(cifrado),
          servicioBaseDatosProvider.overrideWith((ref) => base),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // Los campos se precargan con los datos del cuidador.
    expect(
      find.widgetWithText(TextField, 'Ana Torres'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(TextField, '+56 9 1111 1111'),
      findsOneWidget,
    );
    // La relación se precarga como dropdown con el valor guardado.
    expect(find.widgetWithText(DropdownButtonFormField<String>, 'Madre'),
        findsOneWidget);

    // Cambiar relación por el dropdown.
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tutor').last);
    await tester.pumpAndSettle();

    // Editar nombre y guardar.
    await tester.enterText(
      find.widgetWithText(TextField, 'Ana Torres'),
      'Ana María Torres',
    );
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Guardar cambios'));
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar cambios'));
    await tester.pumpAndSettle();

    // El Firestore fake debe contener el nombre actualizado (descifrable).
    final doc = await fake.collection('users').doc(_uid).get();
    final datos = doc.data()!;
    expect(datos['nombre_cifrado'], isNotNull);
    final datosActualizados = await base.obtenerCuidador();
    expect(datosActualizados['nombre'], 'Ana María Torres');
    expect(datosActualizados['relacion'], 'Tutor');
  });

  testWidgets('editar perfil muestra correo verificado', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(
        uid: _uid,
        email: 'ana@correo.cl',
        isEmailVerified: true,
      ),
    );
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    final base = await _baseConCuidador(cifrado);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (c, s) => const EditarPerfil()),
        GoRoute(
          path: '/perfil',
          builder: (c, s) => const Scaffold(
            body: Center(child: Text('Perfil')),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
          servicioCifradoProvider.overrideWithValue(cifrado),
          servicioBaseDatosProvider.overrideWith((ref) => base),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verificado'), findsOneWidget);
  });

  testWidgets('editar perfil muestra verificacion pendiente', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(
        uid: _uid,
        email: 'ana@correo.cl',
        isEmailVerified: false,
      ),
    );
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    final base = await _baseConCuidador(cifrado);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (c, s) => const EditarPerfil()),
        GoRoute(
          path: '/perfil',
          builder: (c, s) => const Scaffold(
            body: Center(child: Text('Perfil')),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
          servicioCifradoProvider.overrideWithValue(cifrado),
          servicioBaseDatosProvider.overrideWith((ref) => base),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verificación pendiente'), findsOneWidget);
    expect(find.text('Reenviar'), findsOneWidget);
  });
}