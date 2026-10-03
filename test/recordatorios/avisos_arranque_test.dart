import 'dart:io';

import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oncuidar/caracteristicas/onboarding/iniciar_sesion.dart';
import 'package:oncuidar/caracteristicas/onboarding/splash.dart';
import 'package:oncuidar/core/proveedores/proveedores.dart';
import 'package:oncuidar/core/router/destino_aviso.dart';
import 'package:oncuidar/core/servicios/servicio_base_datos.dart';
import 'package:oncuidar/core/servicios/servicio_cache_contenido.dart';
import 'package:oncuidar/core/servicios/servicio_cifrado.dart';
import 'package:oncuidar/core/servicios/servicio_notificaciones.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ayudas_recordatorios.dart';

class _CacheFalso implements ServicioCacheContenido {
  @override
  Future<File?> archivoEnCache(String url) async => null;

  @override
  Future<File> descargar(String url) async => File(url);

  @override
  Future<bool> archivoDescargado(String url) async => false;

  @override
  Future<void> eliminar(String url) async {}
}

MockFirebaseAuth _auth({bool conSesion = false}) => MockFirebaseAuth(
  signedIn: conSesion,
  mockUser: MockUser(uid: uidRecordatorios, email: 'ana@correo.cl'),
);

Future<ServicioBaseDatos> _baseConRecordatorio() async {
  final (base, _) = await baseRecordatorios();
  final idPaciente = await crearPacienteRecordatorios(base);
  await base.agregarRecordatorio(
    idPaciente,
    recordatorioDe(idPaciente, titulo: 'Tomar jarabe'),
  );
  return base;
}

List<Override> _overrides(
  MockFirebaseAuth auth,
  ServicioBaseDatos base,
  NotificacionesFalsas notif,
) => [
  firebaseAuthProvider.overrideWithValue(auth),
  servicioCifradoProvider.overrideWithValue(
    ServicioCifrado(clavePrueba: clavePruebaRecordatorios),
  ),
  servicioBaseDatosProvider.overrideWith((_) => base),
  servicioNotificacionesProvider.overrideWithValue(notif),
  servicioCacheContenidoProvider.overrideWithValue(_CacheFalso()),
];

Widget _appSplash(List<Override> overrides) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (c, s) => Splash(alFinalizar: () => c.go('/bienvenida')),
      ),
      GoRoute(
        path: '/bienvenida',
        builder: (c, s) => const Scaffold(body: Text('Bienvenida')),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (c, s) => const Scaffold(body: Text('Dashboard')),
      ),
      GoRoute(
        path: '/recordatorios',
        builder: (c, s) => const Scaffold(body: Text('Pantalla recordatorios')),
      ),
    ],
  );
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    EstadoArranque.reiniciar();
  });
  tearDown(EstadoArranque.reiniciar);

  group('Reagendado al entrar', () {
    testWidgets('el Splash con sesión reprograma los avisos sin editar nada', (
      tester,
    ) async {
      final base = await _baseConRecordatorio();
      final notif = NotificacionesFalsas();
      await tester.pumpWidget(
        _appSplash(_overrides(_auth(conSesion: true), base, notif)),
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 500));

      expect(notif.canceladasTodas, 1);
      expect(notif.programados.map((p) => p['cuerpo']), ['Tomar jarabe']);
    });

    testWidgets('el Splash sin sesión no toca los avisos', (tester) async {
      final base = await _baseConRecordatorio();
      final notif = NotificacionesFalsas();
      await tester.pumpWidget(
        _appSplash(_overrides(MockFirebaseAuth(), base, notif)),
      );
      await tester.pump(const Duration(seconds: 3));

      expect(notif.canceladasTodas, 0);
      expect(notif.programados, isEmpty);
    });

    testWidgets('iniciar sesión reprograma los avisos del cuidador', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final base = await _baseConRecordatorio();
      final notif = NotificacionesFalsas();
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (c, s) => const IniciarSesion()),
          GoRoute(
            path: '/dashboard',
            builder: (c, s) => const Scaffold(body: Text('Dashboard')),
          ),
          GoRoute(
            path: '/crear-cuenta',
            builder: (c, s) => const Scaffold(body: Text('Registro')),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides(_auth(), base, notif),
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'correo@ejemplo.com'),
        'ana@correo.cl',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Tu contraseña'),
        'secreto123',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(notif.programados.map((p) => p['cuerpo']), ['Tomar jarabe']);
    });
  });

  group('Tocar un aviso', () {
    test('con sesión validada abre la sección de recordatorios', () {
      EstadoArranque.completado = true;
      final rutas = <String>[];
      abrirDesdeNotificacion(
        ServicioNotificaciones.rutaAviso,
        rutas.add,
        haySesion: true,
      );
      expect(rutas, ['/recordatorios']);
      expect(EstadoArranque.destinoPendiente, isNull);
    });

    test('antes de validar la sesión deja el destino pendiente', () {
      final rutas = <String>[];
      abrirDesdeNotificacion('/recordatorios', rutas.add, haySesion: true);
      expect(rutas, isEmpty);
      expect(EstadoArranque.destinoPendiente, '/recordatorios');
    });

    test('sin sesión no navega y lo abre tras iniciar sesión', () {
      EstadoArranque.completado = true;
      final rutas = <String>[];
      abrirDesdeNotificacion('/recordatorios', rutas.add, haySesion: false);
      expect(rutas, isEmpty);
      expect(EstadoArranque.consumirDestino(), '/recordatorios');
    });

    test('un payload ausente o inseguro se ignora', () {
      EstadoArranque.completado = true;
      final rutas = <String>[];
      abrirDesdeNotificacion(null, rutas.add, haySesion: true);
      abrirDesdeNotificacion('//sitio-externo.cl', rutas.add, haySesion: true);
      abrirDesdeNotificacion('https://x.cl', rutas.add, haySesion: true);
      expect(rutas, isEmpty);
      expect(EstadoArranque.destinoPendiente, isNull);
    });

    test('el aviso que abrió la app queda como destino de arranque', () {
      registrarLanzamientoPorNotificacion('/recordatorios');
      expect(EstadoArranque.destinoPendiente, '/recordatorios');
      registrarLanzamientoPorNotificacion(null);
      expect(EstadoArranque.destinoPendiente, '/recordatorios');
    });

    testWidgets('con la app cerrada, el Splash con sesión abre recordatorios', (
      tester,
    ) async {
      final base = await _baseConRecordatorio();
      final notif = NotificacionesFalsas()
        ..payloadLanzamiento = ServicioNotificaciones.rutaAviso;
      registrarLanzamientoPorNotificacion(
        await notif.consumirPayloadLanzamiento(),
      );
      await tester.pumpWidget(
        _appSplash(_overrides(_auth(conSesion: true), base, notif)),
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Pantalla recordatorios'), findsOneWidget);
      expect(EstadoArranque.destinoPendiente, isNull);
    });

    testWidgets('con la app cerrada y sin sesión conserva el destino', (
      tester,
    ) async {
      final base = await _baseConRecordatorio();
      registrarLanzamientoPorNotificacion('/recordatorios');
      await tester.pumpWidget(
        _appSplash(
          _overrides(MockFirebaseAuth(), base, NotificacionesFalsas()),
        ),
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Bienvenida'), findsOneWidget);
      expect(EstadoArranque.destinoPendiente, '/recordatorios');
    });
  });
}
