import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oncuidar/caracteristicas/chat/chat.dart';
import 'package:oncuidar/compartidos/widgets/encabezado_gradiente.dart';
import 'package:oncuidar/core/proveedores/proveedores.dart';
import 'package:oncuidar/core/servicios/servicio_base_datos.dart';
import 'package:oncuidar/core/servicios/servicio_cifrado.dart';
import 'package:oncuidar/modelos/conversacion.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _clavePrueba = 'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';
const _uid = 'uid1';

List<MensajeConversacion> _mensajes() => const [
  MensajeConversacion(texto: 'Mi bebé tiene fiebre', delUsuario: true),
  MensajeConversacion(texto: 'Respuesta', delUsuario: false),
];

Future<(ServicioBaseDatos, FakeFirebaseFirestore)> _base() async {
  final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
  await cifrado.fijarClave(_uid, _clavePrueba);
  final firestore = FakeFirebaseFirestore();
  final base = ServicioBaseDatos(
    base: firestore,
    uidPrueba: _uid,
    cifrado: cifrado,
  );
  return (base, firestore);
}

Widget _pantalla(ServicioBaseDatos base) {
  final router = GoRouter(
    initialLocation: '/chat',
    routes: [
      GoRoute(path: '/chat', builder: (c, s) => const ChatScreen()),
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

Future<void> _abrirHoja(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('botonConversacionesChat')));
  await tester.pumpAndSettle();
}

void main() {
  group('ServicioBaseDatos — Conversaciones', () {
    test('crearConversacion cifra título y mensajes', () async {
      final (base, firestore) = await _base();
      final id = await base.crearConversacion(
        titulo: 'Duda sobre fiebre',
        mensajes: _mensajes(),
      );
      final datos =
          (await firestore
                  .collection('users')
                  .doc(_uid)
                  .collection('conversations')
                  .doc(id)
                  .get())
              .data()!;
      expect(datos.containsKey('titulo'), isFalse);
      expect(datos.containsKey('mensajes'), isFalse);
      expect(datos['titulo_cifrado'], isA<String>());
      expect(datos['titulo_cifrado'], isNot('Duda sobre fiebre'));
      expect(datos['mensajes_cifrado'], isA<String>());
      expect(datos['version_encriptacion'], 3);
    });

    test(
      'el stream devuelve descifrado y ordenado por última actividad',
      () async {
        final (base, _) = await _base();
        await base.crearConversacion(
          titulo: 'Duda sobre fiebre',
          mensajes: _mensajes(),
        );
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await base.crearConversacion(
          titulo: 'Duda sobre catéter',
          mensajes: _mensajes(),
        );
        final conversaciones = await base.conversacionesEnTiempoReal().first;
        expect(conversaciones, hasLength(2));
        expect(conversaciones.first.titulo, 'Duda sobre catéter');
        expect(
          conversaciones.first.mensajes.first.texto,
          'Mi bebé tiene fiebre',
        );
        expect(conversaciones.first.mensajes.first.delUsuario, isTrue);
        expect(conversaciones.last.titulo, 'Duda sobre fiebre');
      },
    );

    test('renombrarConversacion actualiza el título descifrado', () async {
      final (base, _) = await _base();
      final id = await base.crearConversacion(
        titulo: 'Duda sobre fiebre',
        mensajes: _mensajes(),
      );
      await base.renombrarConversacion(id, 'Duda resuelta');
      final conversaciones = await base.conversacionesEnTiempoReal().first;
      expect(conversaciones, hasLength(1));
      expect(conversaciones.single.titulo, 'Duda resuelta');
    });

    test('eliminarConversacion borra el doc', () async {
      final (base, firestore) = await _base();
      final id = await base.crearConversacion(
        titulo: 'Duda sobre fiebre',
        mensajes: _mensajes(),
      );
      await base.eliminarConversacion(id);
      final snap = await firestore
          .collection('users')
          .doc(_uid)
          .collection('conversations')
          .snapshots()
          .first
          .timeout(const Duration(seconds: 5));
      expect(snap.docs.where((d) => d.id == id), isEmpty);
    });
  });

  group('Widget — Hoja de conversaciones', () {
    testWidgets('el botón de carpeta abre la hoja sin salir del chat', (
      tester,
    ) async {
      final (base, _) = await _base();
      await _montar(tester, base);

      await _abrirHoja(tester);

      expect(find.byKey(const Key('hojaConversaciones')), findsOneWidget);
      expect(find.byKey(const Key('campoMensajeChat')), findsOneWidget);
    });

    testWidgets('sin conversaciones la hoja muestra el estado vacío', (
      tester,
    ) async {
      final (base, _) = await _base();
      await _montar(tester, base);

      await _abrirHoja(tester);

      expect(find.text('Aún no tienes conversaciones.'), findsOneWidget);
      expect(
        find.text('Tus intercambios con el asistente quedarán guardados aquí.'),
        findsOneWidget,
      );
    });

    testWidgets('la hoja lista las conversaciones con su detalle', (
      tester,
    ) async {
      final (base, _) = await _base();
      await base.crearConversacion(
        titulo: 'Duda sobre fiebre',
        mensajes: _mensajes(),
      );
      await _montar(tester, base);

      await _abrirHoja(tester);

      expect(find.text('Duda sobre fiebre'), findsOneWidget);
      expect(find.textContaining('2 mensajes'), findsOneWidget);
    });

    testWidgets('tocar una conversación la carga en el chat', (tester) async {
      final (base, _) = await _base();
      final id = await base.crearConversacion(
        titulo: 'Duda sobre fiebre',
        mensajes: _mensajes(),
      );
      await _montar(tester, base);

      await _abrirHoja(tester);
      await tester.tap(find.byKey(Key('conversacion_$id')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('hojaConversaciones')), findsNothing);
      expect(find.text('Mi bebé tiene fiebre'), findsOneWidget);
      expect(find.text('Respuesta'), findsOneWidget);
      expect(find.text('Duda sobre fiebre'), findsOneWidget);
    });

    testWidgets('renombrar una conversación actualiza el doc', (tester) async {
      final (base, _) = await _base();
      final id = await base.crearConversacion(
        titulo: 'Duda sobre fiebre',
        mensajes: _mensajes(),
      );
      await _montar(tester, base);

      await _abrirHoja(tester);
      await tester.tap(find.byKey(Key('menuConversacion_$id')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Renombrar'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('dialogoRenombrarConversacion')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('campoRenombrarConversacion')),
        'Duda resuelta',
      );
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('Duda resuelta'), findsOneWidget);
      expect(find.text('Duda sobre fiebre'), findsNothing);

      final conversaciones = await base.conversacionesEnTiempoReal().first;
      expect(conversaciones.single.titulo, 'Duda resuelta');
    });

    testWidgets(
      'renombrar la conversación activa actualiza el subtítulo del chat',
      (tester) async {
        final (base, _) = await _base();
        final id = await base.crearConversacion(
          titulo: 'Duda sobre fiebre',
          mensajes: _mensajes(),
        );
        await _montar(tester, base);

        await _abrirHoja(tester);
        await tester.tap(find.byKey(Key('conversacion_$id')));
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byType(EncabezadoGradiente),
            matching: find.text('Duda sobre fiebre'),
          ),
          findsOneWidget,
        );

        await _abrirHoja(tester);
        await tester.tap(find.byKey(Key('menuConversacion_$id')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Renombrar'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('campoRenombrarConversacion')),
          'Duda resuelta',
        );
        await tester.tap(find.text('Guardar'));
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byType(EncabezadoGradiente),
            matching: find.text('Duda resuelta'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(EncabezadoGradiente),
            matching: find.text('Duda sobre fiebre'),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'renombrar la activa y enviar un mensaje no revierte el título',
      (tester) async {
        final (base, _) = await _base();
        final id = await base.crearConversacion(
          titulo: 'Duda sobre fiebre',
          mensajes: _mensajes(),
        );
        await _montar(tester, base);

        await _abrirHoja(tester);
        await tester.tap(find.byKey(Key('conversacion_$id')));
        await tester.pumpAndSettle();

        await _abrirHoja(tester);
        await tester.tap(find.byKey(Key('menuConversacion_$id')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Renombrar'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('campoRenombrarConversacion')),
          'Duda resuelta',
        );
        await tester.tap(find.text('Guardar'));
        await tester.pumpAndSettle();

        await tester.tapAt(const Offset(400, 50));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('campoMensajeChat')),
          'temperatura de 38',
        );
        await tester.testTextInput.receiveAction(TextInputAction.send);
        await tester.pump(const Duration(milliseconds: 1000));
        await tester.pumpAndSettle();

        expect(find.text('temperatura de 38'), findsOneWidget);
        final conversaciones = await base.conversacionesEnTiempoReal().first;
        expect(conversaciones, hasLength(1));
        expect(conversaciones.single.titulo, 'Duda resuelta');
        expect(
          conversaciones.single.mensajes.any(
            (m) => m.texto == 'temperatura de 38',
          ),
          isTrue,
        );
      },
    );

    testWidgets('eliminar una conversación quita la tarjeta y el doc', (
      tester,
    ) async {
      final (base, _) = await _base();
      final id = await base.crearConversacion(
        titulo: 'Duda sobre fiebre',
        mensajes: _mensajes(),
      );
      await _montar(tester, base);

      await _abrirHoja(tester);
      await tester.tap(find.byKey(Key('menuConversacion_$id')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('dialogoEliminarConversacion')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('confirmarEliminarConversacion')));
      await tester.pumpAndSettle();

      expect(find.text('Duda sobre fiebre'), findsNothing);

      final conversaciones = await base.conversacionesEnTiempoReal().first;
      expect(conversaciones, isEmpty);
    });

    testWidgets('nueva conversación reinicia el chat a la bienvenida', (
      tester,
    ) async {
      final (base, _) = await _base();
      final id = await base.crearConversacion(
        titulo: 'Duda sobre fiebre',
        mensajes: _mensajes(),
      );
      await _montar(tester, base);

      await _abrirHoja(tester);
      await tester.tap(find.byKey(Key('conversacion_$id')));
      await tester.pumpAndSettle();
      expect(find.text('Mi bebé tiene fiebre'), findsOneWidget);

      await _abrirHoja(tester);
      await tester.tap(find.byKey(const Key('agregarConversacionHoja')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('dialogoNombreConversacion')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('confirmarNombreConversacion')));
      await tester.pumpAndSettle();

      expect(find.text('Mi bebé tiene fiebre'), findsNothing);
      expect(find.text('Respuesta'), findsNothing);
      expect(find.textContaining('Hola, soy tu asistente'), findsOneWidget);
      expect(find.text('Chat de orientación'), findsOneWidget);
    });

    testWidgets(
      'crear con nombre lo muestra en el subtítulo y persiste ese título',
      (tester) async {
        final (base, _) = await _base();
        await _montar(tester, base);

        await _abrirHoja(tester);
        await tester.tap(find.byKey(const Key('agregarConversacionHoja')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('campoNombreConversacion')),
          'Dudas de la semana',
        );
        await tester.tap(find.byKey(const Key('confirmarNombreConversacion')));
        await tester.pumpAndSettle();

        expect(find.textContaining('Hola, soy tu asistente'), findsOneWidget);
        expect(find.text('Dudas de la semana'), findsOneWidget);

        await tester.tap(find.byKey(const Key('sugerencia_fiebre')));
        await tester.pump(const Duration(milliseconds: 1000));
        await tester.pumpAndSettle();

        final conversaciones = await base.conversacionesEnTiempoReal().first;
        expect(conversaciones, hasLength(1));
        expect(conversaciones.single.titulo, 'Dudas de la semana');
      },
    );
  });
}
