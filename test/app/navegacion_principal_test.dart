import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oncuidar/app/navegacion_principal.dart';
import 'package:oncuidar/nucleo/proveedores.dart';

Widget _pantalla(String nombre) =>
    Scaffold(body: Center(child: Text('Pantalla $nombre')));

List<RouteBase> _rutasComunes() => [
  GoRoute(path: '/chat', builder: (c, s) => _pantalla('de chat')),
  GoRoute(
    path: '/registro-clinico',
    builder: (c, s) => _pantalla('de registro'),
  ),
  GoRoute(path: '/biblioteca', builder: (c, s) => _pantalla('de biblioteca')),
];

Widget _app() {
  final router = GoRouter(
    initialLocation: '/dashboard',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => NavegacionPrincipal(
          shell: shell,
          ubicacion: state.uri.path,
          child: shell,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (c, s) => _pantalla('de inicio'),
              ),
              ..._rutasComunes(),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/perfil',
                builder: (c, s) => _pantalla('de perfil'),
              ),
              ..._rutasComunes(),
            ],
          ),
        ],
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      estadoConexionProvider.overrideWith((ref) => Stream.value(true)),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('la barra muestra los cinco destinos', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    for (final destino in ['Inicio', 'Chat', 'Registro', 'Aprende', 'Perfil']) {
      expect(find.text(destino), findsOneWidget);
    }
  });

  testWidgets('cada destino lleva a su sección', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.text('Pantalla de inicio'), findsOneWidget);

    final recorrido = {
      'Chat': 'Pantalla de chat',
      'Registro': 'Pantalla de registro',
      'Aprende': 'Pantalla de biblioteca',
      'Perfil': 'Pantalla de perfil',
      'Inicio': 'Pantalla de inicio',
    };
    for (final MapEntry(key: destino, value: pantalla) in recorrido.entries) {
      await tester.tap(find.text(destino));
      await tester.pumpAndSettle();
      expect(find.text(pantalla), findsOneWidget, reason: 'al tocar $destino');
    }
  });

  testWidgets('desde Perfil también se llega al chat', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();

    expect(find.text('Pantalla de chat'), findsOneWidget);
  });
}
