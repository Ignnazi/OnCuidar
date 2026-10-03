import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oncuidar/caracteristicas/chat/datos/repositorio_conversaciones.dart';
import 'package:oncuidar/caracteristicas/chat/dominio/conversacion.dart';
import 'package:oncuidar/caracteristicas/chat/dominio/respuestas_chat.dart';
import 'package:oncuidar/caracteristicas/chat/presentacion/pantalla_chat.dart';
import 'package:oncuidar/caracteristicas/chat/presentacion/proveedor_chat_activo.dart';
import 'package:oncuidar/caracteristicas/preguntas_frecuentes/dominio/catalogo_preguntas.dart';
import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
import 'package:oncuidar/nucleo/proveedores.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _clavePrueba = 'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';
const _uid = 'uid-1';
const _preguntaFiebre =
    '¿Qué temperatura se considera fiebre y cuándo debo llamar al médico?';

Future<BaseDatosSegura> _base() async {
  final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
  await cifrado.fijarClave(_uid, _clavePrueba);
  return BaseDatosSegura(
    base: FakeFirebaseFirestore(),
    uidPrueba: _uid,
    cifrado: cifrado,
  );
}

Widget _pantalla(BaseDatosSegura base) {
  final router = GoRouter(
    initialLocation: '/chat',
    routes: [
      GoRoute(path: '/chat', builder: (c, s) => const ChatScreen()),
      GoRoute(
        path: '/faq',
        builder: (c, s) =>
            const Scaffold(body: Center(child: Text('FAQ stub'))),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (c, s) =>
            const Scaffold(body: Center(child: Text('Dashboard stub'))),
      ),
    ],
  );
  return ProviderScope(
    overrides: [baseDatosSeguraProvider.overrideWith((_) => base)],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _montar(WidgetTester tester, BaseDatosSegura base) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_pantalla(base));
  await tester.pumpAndSettle();
}

(ProviderContainer, StreamController<User?>) _contenedorConSesion() {
  final usuarioA = MockUser(uid: 'uid-a', email: 'a@correo.cl');
  final flujo = StreamController<User?>();
  final contenedor = ProviderContainer(
    overrides: [
      firebaseAuthProvider.overrideWithValue(
        MockFirebaseAuth(signedIn: true, mockUser: usuarioA),
      ),
      estadoAutenticacionProvider.overrideWith((_) => flujo.stream),
    ],
  );
  contenedor.listen(estadoAutenticacionProvider, (_, _) {});
  addTearDown(contenedor.dispose);
  addTearDown(() => unawaited(flujo.close()));
  return (contenedor, flujo);
}

Future<void> _cambiarUsuario(StreamController<User?> flujo, User? u) async {
  flujo.add(u);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  group('Chat activo al cambiar de usuario', () {
    test('al cambiar de A a B el chat en memoria queda vacío', () async {
      SharedPreferences.setMockInitialValues({});
      final (contenedor, flujo) = _contenedorConSesion();
      final notifier = contenedor.read(chatActivoProvider.notifier);
      await _cambiarUsuario(flujo, MockUser(uid: 'uid-a'));

      notifier.nueva();
      notifier.agregarMensaje(
        const MensajeConversacion(texto: 'Dato privado de A', delUsuario: true),
      );
      notifier.fijarId('conv-a');
      expect(contenedor.read(chatActivoProvider).mensajes, hasLength(2));

      await _cambiarUsuario(flujo, MockUser(uid: 'uid-b'));

      final estado = contenedor.read(chatActivoProvider);
      expect(estado.mensajes, isEmpty);
      expect(estado.conversacionId, isNull);
    });

    test('el id guardado de A no se restaura para B', () async {
      SharedPreferences.setMockInitialValues({
        claveConversacionActiva: 'conv-antigua',
      });
      final (contenedor, flujo) = _contenedorConSesion();
      final notifier = contenedor.read(chatActivoProvider.notifier);
      await _cambiarUsuario(flujo, MockUser(uid: 'uid-a'));

      notifier.fijarId('conv-a');
      await Future<void>.delayed(Duration.zero);
      expect(await notifier.idGuardado(), 'conv-a');

      await _cambiarUsuario(flujo, MockUser(uid: 'uid-b'));

      final notifierB = contenedor.read(chatActivoProvider.notifier);
      expect(await notifierB.idGuardado(), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(claveConversacionActiva), isNull);
    });

    test('cerrar sesión también vacía el chat en memoria', () async {
      SharedPreferences.setMockInitialValues({});
      final (contenedor, flujo) = _contenedorConSesion();
      final notifier = contenedor.read(chatActivoProvider.notifier);
      notifier.nueva();

      await _cambiarUsuario(flujo, null);

      expect(contenedor.read(chatActivoProvider).mensajes, isEmpty);
    });
  });

  testWidgets('muestra bienvenida, título fijo y sugerencias frecuentes', (
    tester,
  ) async {
    await _montar(tester, await _base());

    expect(find.text('Chat de orientación'), findsOneWidget);
    expect(find.text('Resuelve tus dudas'), findsOneWidget);
    expect(find.textContaining('Hola, soy tu asistente'), findsOneWidget);
    expect(find.byKey(const Key('sugerencia_fiebre')), findsOneWidget);
    expect(find.byKey(const Key('sugerencia_cateter')), findsOneWidget);
    expect(find.byKey(const Key('sugerencia_alimentacion')), findsOneWidget);
  });

  testWidgets(
    'tocar una sugerencia muestra indicador y responde el asistente',
    (tester) async {
      await _montar(tester, await _base());

      await tester.tap(find.byKey(const Key('sugerencia_fiebre')));
      await tester.pump();

      expect(find.text(_preguntaFiebre), findsOneWidget);
      expect(find.byKey(const Key('indicadorEscribiendo')), findsOneWidget);
      expect(find.byKey(const Key('sugerencia_fiebre')), findsNothing);

      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('indicadorEscribiendo')), findsNothing);
      expect(find.textContaining('Se considera fiebre'), findsOneWidget);
      expect(find.byKey(const Key('seguimiento_cateter')), findsOneWidget);
      expect(find.byKey(const Key('seguimiento_alimentacion')), findsOneWidget);
    },
  );

  testWidgets('el texto libre con palabras clave resuelve la pregunta', (
    tester,
  ) async {
    await _montar(tester, await _base());

    await tester.enterText(
      find.byKey(const Key('campoMensajeChat')),
      'temperatura de 38',
    );
    await tester.tap(find.byKey(const Key('enviarMensaje')));
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();

    expect(find.text('temperatura de 38'), findsOneWidget);
    expect(find.textContaining('Se considera fiebre'), findsOneWidget);
  });

  testWidgets('la búsqueda filtra los mensajes de la conversación', (
    tester,
  ) async {
    await _montar(tester, await _base());

    await tester.tap(find.byKey(const Key('sugerencia_fiebre')));
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('alternarBusquedaChat')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('campoBusquedaChat')),
      'fiebre',
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Hola, soy tu asistente'), findsNothing);
    expect(find.text(_preguntaFiebre), findsOneWidget);
    expect(find.textContaining('Se considera fiebre'), findsOneWidget);
    expect(find.byKey(const Key('sugerencia_cateter')), findsNothing);
  });

  testWidgets('sin resultados de búsqueda muestra estado vacío', (
    tester,
  ) async {
    await _montar(tester, await _base());

    await tester.tap(find.byKey(const Key('alternarBusquedaChat')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('campoBusquedaChat')), 'zzz');
    await tester.pumpAndSettle();

    expect(find.text('Sin resultados para tu búsqueda.'), findsOneWidget);
  });

  testWidgets('el enlace a preguntas frecuentes abre el FAQ', (tester) async {
    await _montar(tester, await _base());

    await tester.tap(find.byKey(const Key('verPreguntasFrecuentes')));
    await tester.pumpAndSettle();

    expect(find.text('FAQ stub'), findsOneWidget);
  });

  testWidgets('el botón de conversaciones abre la hoja sin salir del chat', (
    tester,
  ) async {
    await _montar(tester, await _base());

    await tester.tap(find.byKey(const Key('botonConversacionesChat')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('hojaConversaciones')), findsOneWidget);
    expect(find.byKey(const Key('campoMensajeChat')), findsOneWidget);
    expect(find.text('Aún no tienes conversaciones.'), findsOneWidget);
  });

  testWidgets(
    'una conversación nueva se titula con la primera pregunta recortada',
    (tester) async {
      final base = await _base();
      await _montar(tester, base);

      await tester.tap(find.byKey(const Key('sugerencia_fiebre')));
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pumpAndSettle();

      final convs = await RepositorioConversaciones(
        base,
      ).conversacionesEnTiempoReal().first;
      expect(convs, hasLength(1));
      expect(
        convs.single.titulo,
        tituloAutomaticoConversacion(preguntasFrecuentes.first.pregunta),
      );
      expect(convs.single.titulo, startsWith('¿Qué temperatura'));
      expect(convs.single.mensajes.length, greaterThanOrEqualTo(2));
    },
  );
}
