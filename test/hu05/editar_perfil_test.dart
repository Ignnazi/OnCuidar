import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oncuidar/caracteristicas/perfil/perfil.dart';
import 'package:oncuidar/core/proveedores/proveedores.dart';
import 'package:oncuidar/core/servicios/servicio_base_datos.dart';
import 'package:oncuidar/core/servicios/servicio_cifrado.dart';

const _clavePrueba = 'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';
const _uid = 'uid-test';

MockFirebaseAuth _authConSesion() => MockFirebaseAuth(
      mockUser: MockUser(uid: _uid, email: 'ana@correo.cl'),
    );

Future<ServicioBaseDatos> _baseConCuidador(ServicioCifrado cifrado) async {
  await cifrado.fijarClave(_uid, _clavePrueba);
  final base = ServicioBaseDatos(
    base: FakeFirebaseFirestore(),
    uidPrueba: _uid,
    cifrado: cifrado,
  );
  await base.crearCuidador({
    'displayName': 'Ana Torres',
    'email': 'ana@correo.cl',
    'phone': '+56 9 1111 1111',
    'relationship': 'Madre',
    'address': 'Av. Siempre Viva 742',
  });
  return base;
}

Widget _pantallaPerfil(
  MockFirebaseAuth auth,
  ServicioBaseDatos base,
  ServicioCifrado cifrado,
) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (c, s) => const Perfil()),
      GoRoute(
        path: '/bienvenida',
        builder: (c, s) => const Scaffold(
          body: Center(child: Text('Bienvenida')),
        ),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      firebaseAuthProvider.overrideWithValue(auth),
      servicioCifradoProvider.overrideWithValue(cifrado),
      servicioBaseDatosProvider.overrideWith((ref) => base),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _abrirMiPerfil(WidgetTester tester) async {
  await tester.tap(find.text('Mi perfil'));
  await tester.pumpAndSettle();
}

Future<void> _pantallaAlta(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('editar mis datos abre SOLO datos personales y guarda',
      (tester) async {
    await _pantallaAlta(tester);
    final auth = _authConSesion();
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    final base = await _baseConCuidador(cifrado);
    await tester.pumpWidget(_pantallaPerfil(auth, base, cifrado));
    await tester.pumpAndSettle();
    await _abrirMiPerfil(tester);

    await tester.tap(find.byKey(const Key('menuDatosPersonales')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar mis datos'));
    await tester.pumpAndSettle();

    // Solo datos personales: nada de correos ni contraseña en este diálogo.
    expect(find.widgetWithText(TextField, 'Nombre completo *'), findsOneWidget);
    expect(
      find.widgetWithText(TextField, 'Parentesco (madre, padre, tía…) *'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextField, 'Teléfono *'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Dirección *'), findsOneWidget);
    expect(
      find.widgetWithText(TextField, 'Correo principal (cuenta de acceso)'),
      findsNothing,
    );
    expect(find.widgetWithText(TextField, 'Correo de respaldo'), findsNothing);
    expect(find.widgetWithText(TextField, 'Contraseña actual'), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextField, 'Nombre completo *'),
      'Ana Torres Nueva',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Parentesco (madre, padre, tía…) *'),
      'Madre',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Teléfono *'),
      '+56 9 2222 2222',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Dirección *'),
      'Calle Nueva 123',
    );
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(find.text('Datos actualizados'), findsOneWidget);
    expect(find.text('Ana Torres Nueva'), findsOneWidget,
        reason: 'la tarjeta refresca el nombre guardado');
    expect(find.text('Calle Nueva 123'), findsOneWidget,
        reason: 'la dirección guardada aparece en la tarjeta');
  });

  testWidgets(
      'tarjeta Autenticacion (estilo Centro de Salud): un solo menu para '
      'editar correo principal o respaldo, sin "ambos"', (tester) async {
    await _pantallaAlta(tester);
    final auth = _authConSesion();
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    final base = await _baseConCuidador(cifrado);
    await tester.pumpWidget(_pantallaPerfil(auth, base, cifrado));
    await tester.pumpAndSettle();
    await _abrirMiPerfil(tester);

    // Una sola tarjeta "Autenticación" con ambas filas de correo.
    expect(find.text('Autenticación'), findsOneWidget);
    expect(find.text('Correo principal'), findsOneWidget);
    expect(find.text('Correo de respaldo'), findsOneWidget);
    expect(find.text('No configurado'), findsOneWidget);
    // Un solo botón de 3 puntos para la tarjeta de correos.
    expect(find.byKey(const Key('menuAutenticacion')), findsOneWidget);

    // Menú: editar principal y editar respaldo; NUNCA "ambos".
    await tester.tap(find.byKey(const Key('menuAutenticacion')));
    await tester.pumpAndSettle();
    expect(find.text('Editar correo principal'), findsOneWidget);
    expect(find.text('Editar correo de respaldo'), findsOneWidget);
    expect(find.text('Editar ambos correos'), findsNothing);

    // Editar principal abre su diálogo con SOLO el campo principal.
    await tester.tap(find.text('Editar correo principal'));
    await tester.pumpAndSettle();
    expect(find.text('Editar correo principal'), findsOneWidget);
    expect(
      find.widgetWithText(TextField, 'Correo principal (cuenta de acceso)'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(TextField, 'Correo de respaldo'),
      findsNothing,
    );
    // CONTRASEÑA solo aparece cuando hay un cambio real de correo.
    expect(find.widgetWithText(TextField, 'Contraseña actual'), findsNothing);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    // Editar respaldo (vacío) lo configura desde el mismo menú.
    await tester.tap(find.byKey(const Key('menuAutenticacion')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar correo de respaldo'));
    await tester.pumpAndSettle();
    expect(find.text('Configurar correo de respaldo'), findsOneWidget);
    expect(
      find.widgetWithText(TextField, 'Correo de respaldo'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(TextField, 'Correo principal (cuenta de acceso)'),
      findsNothing,
    );
  });
}