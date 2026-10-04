import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oncuidar/caracteristicas/perfil/datos/repositorio_cuidador.dart';
import 'package:oncuidar/caracteristicas/perfil/presentacion/pantalla_perfil.dart';
import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
import 'package:oncuidar/nucleo/proveedores.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../ayudas/recordatorios.dart';

const _clavePrueba = 'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';
const _uid = 'uid-test';

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
    'direccion': 'Av. Siempre Viva 742',
  });
  return base;
}

Widget _pantallaPerfil(
  MockFirebaseAuth auth,
  BaseDatosSegura base,
  ServicioCifrado cifrado, {
  NotificacionesFalsas? avisos,
}) {
  final notificaciones = avisos ?? NotificacionesFalsas();
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (c, s) => const Perfil()),
      GoRoute(
        path: '/bienvenida',
        builder: (c, s) =>
            const Scaffold(body: Center(child: Text('Bienvenida'))),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      firebaseAuthProvider.overrideWithValue(auth),
      servicioCifradoProvider.overrideWithValue(cifrado),
      baseDatosSeguraProvider.overrideWith((ref) => base),
      servicioNotificacionesProvider.overrideWithValue(notificaciones),
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
  testWidgets('editar mis datos abre SOLO datos personales y guarda', (
    tester,
  ) async {
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
    expect(
      find.text('Ana Torres Nueva'),
      findsOneWidget,
      reason: 'la tarjeta refresca el nombre guardado',
    );
    expect(
      find.text('Calle Nueva 123'),
      findsOneWidget,
      reason: 'la dirección guardada aparece en la tarjeta',
    );
  });

  testWidgets(
    'tarjeta Autenticacion (estilo Centro de Salud): un solo menu para '
    'editar correo principal o respaldo, sin "ambos"',
    (tester) async {
      await _pantallaAlta(tester);
      final auth = _authConSesion();
      final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
      final base = await _baseConCuidador(cifrado);
      await tester.pumpWidget(_pantallaPerfil(auth, base, cifrado));
      await tester.pumpAndSettle();
      await _abrirMiPerfil(tester);

      expect(find.text('Correo principal'), findsOneWidget);
      expect(find.text('Correo de respaldo'), findsOneWidget);
      expect(find.text('No configurado'), findsOneWidget);
      expect(find.byKey(const Key('menuAutenticacion')), findsOneWidget);

      await tester.tap(find.byKey(const Key('menuAutenticacion')));
      await tester.pumpAndSettle();
      expect(find.text('Editar correo principal'), findsOneWidget);
      expect(find.text('Editar correo de respaldo'), findsOneWidget);
      expect(find.text('Editar ambos correos'), findsNothing);

      await tester.tap(find.text('Editar correo principal'));
      await tester.pumpAndSettle();
      expect(find.text('Editar correo principal'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'ana@correo.cl'), findsOneWidget);
      expect(
        find.widgetWithText(TextField, 'Correo de respaldo'),
        findsNothing,
      );
      expect(
        find.widgetWithText(TextField, 'Contraseña actual'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('menuAutenticacion')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar correo de respaldo'));
      await tester.pumpAndSettle();
      expect(find.text('Configurar correo de respaldo'), findsOneWidget);
      expect(
        find.widgetWithText(TextField, 'Correo de respaldo *'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextField, 'Correo principal (cuenta de acceso)'),
        findsNothing,
      );

      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();
      expect(find.text('Ingresa el correo de respaldo'), findsOneWidget);
    },
  );

  group('Correo pendiente de confirmar (CA-04.3)', () {
    testWidgets('un cambio del correo principal muestra el aviso', (
      tester,
    ) async {
      await _pantallaAlta(tester);
      final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
      final base = await _baseConCuidador(cifrado);
      await base.docUsuario.set({
        'pendiente_correo': 'nuevo@correo.cl',
        'pendiente_correo_tipo': 'principal',
      }, SetOptions(merge: true));
      await tester.pumpWidget(_pantallaPerfil(_authConSesion(), base, cifrado));
      await tester.pumpAndSettle();
      await _abrirMiPerfil(tester);

      expect(
        find.text('Pendiente de confirmar: nuevo@correo.cl'),
        findsOneWidget,
      );
    });

    testWidgets('un respaldo aún no registrado muestra el aviso', (
      tester,
    ) async {
      await _pantallaAlta(tester);
      final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
      final base = await _baseConCuidador(cifrado);
      await base.docUsuario.set({
        'correo_respaldo_cifrado': await cifrado.cifrar(
          _uid,
          'respaldo@correo.cl',
        ),
        'respaldo_pendiente_servidor': true,
      }, SetOptions(merge: true));
      await tester.pumpWidget(_pantallaPerfil(_authConSesion(), base, cifrado));
      await tester.pumpAndSettle();
      await _abrirMiPerfil(tester);

      expect(
        find.text('Pendiente de confirmar: respaldo@correo.cl'),
        findsOneWidget,
      );
    });

    testWidgets('sin cambios pendientes no aparece el aviso', (tester) async {
      await _pantallaAlta(tester);
      final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
      final base = await _baseConCuidador(cifrado);
      await tester.pumpWidget(_pantallaPerfil(_authConSesion(), base, cifrado));
      await tester.pumpAndSettle();
      await _abrirMiPerfil(tester);

      expect(find.textContaining('Pendiente de confirmar'), findsNothing);
    });
  });

  testWidgets('cerrar sesión cancela los avisos programados (CA-16.4)', (
    tester,
  ) async {
    await _pantallaAlta(tester);
    SharedPreferences.setMockInitialValues({});
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    final base = await _baseConCuidador(cifrado);
    final avisos = NotificacionesFalsas();
    await tester.pumpWidget(
      _pantallaPerfil(_authConSesion(), base, cifrado, avisos: avisos),
    );
    await tester.pumpAndSettle();
    await _abrirMiPerfil(tester);

    await tester.tap(find.byKey(const Key('botonCerrarSesion')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar sesión').last);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(avisos.canceladasTodas, 1);
    expect(find.text('Bienvenida'), findsOneWidget);
  });
}
