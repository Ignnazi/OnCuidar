import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oncuidar/caracteristicas/chat/chat.dart';
import 'package:oncuidar/caracteristicas/faq/datos_faq.dart';
import 'package:oncuidar/core/proveedores/proveedores.dart';
import 'package:oncuidar/core/servicios/servicio_base_datos.dart';
import 'package:oncuidar/core/servicios/servicio_cifrado.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _clavePrueba = 'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';
const _uid = 'uid-1';
const _preguntaFiebre =
    '¿Qué temperatura se considera fiebre y cuándo debo llamar al médico?';

Future<ServicioBaseDatos> _base() async {
  final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
  await cifrado.fijarClave(_uid, _clavePrueba);
  return ServicioBaseDatos(
    base: FakeFirebaseFirestore(),
    uidPrueba: _uid,
    cifrado: cifrado,
  );
}

Widget _pantalla(ServicioBaseDatos base) {
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
    overrides: [servicioBaseDatosProvider.overrideWith((_) => base)],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _montar(WidgetTester tester, ServicioBaseDatos base) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_pantalla(base));
  await tester.pumpAndSettle();
}

void main() {
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

      final convs = await base.conversacionesEnTiempoReal().first;
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
