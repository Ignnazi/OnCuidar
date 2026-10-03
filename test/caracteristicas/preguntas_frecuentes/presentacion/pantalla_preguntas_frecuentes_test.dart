import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/material_educativo.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/proveedores_biblioteca.dart';
import 'package:oncuidar/caracteristicas/preguntas_frecuentes/presentacion/pantalla_preguntas_frecuentes.dart';

const _preguntaFiebre =
    '¿Qué temperatura se considera fiebre y cuándo debo llamar al médico?';
const _preguntaCateter =
    '¿Cómo debo cuidar el catéter y qué hago si se moja o se sale?';
const _preguntaAlimentacion =
    '¿Qué alimentos debo evitar y qué agua es segura?';

Widget _pantalla({List<MaterialEducativo> catalogo = const []}) {
  final router = GoRouter(
    initialLocation: '/faq',
    routes: [
      GoRoute(path: '/faq', builder: (c, s) => const FaqScreen()),
      GoRoute(
        path: '/biblioteca/:id',
        builder: (c, s) => Scaffold(
          body: Center(child: Text('Material ${s.pathParameters['id']}')),
        ),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (c, s) =>
            const Scaffold(body: Center(child: Text('Dashboard stub'))),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      contenidosEducativosProvider.overrideWith(
        (ref) => Stream.value(catalogo),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _montar(
  WidgetTester tester, {
  List<MaterialEducativo> catalogo = const [],
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_pantalla(catalogo: catalogo));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lista las preguntas frecuentes inicialmente cerradas', (
    tester,
  ) async {
    await _montar(tester);

    expect(find.text(_preguntaFiebre), findsOneWidget);
    expect(find.text(_preguntaCateter), findsOneWidget);
    expect(find.text(_preguntaAlimentacion), findsOneWidget);
    expect(find.byKey(const Key('chipCategoriaFaq_Todas')), findsOneWidget);
    expect(find.byKey(const Key('chipCategoriaFaq_Fiebre')), findsOneWidget);
    expect(find.byKey(const Key('chipCategoriaFaq_Catéter')), findsOneWidget);
    expect(
      find.byKey(const Key('chipCategoriaFaq_Alimentación')),
      findsOneWidget,
    );
    expect(find.textContaining('Se considera fiebre'), findsNothing);
  });

  testWidgets(
    'tocar una pregunta expande su respuesta y al tocar de nuevo la cierra',
    (tester) async {
      await _montar(tester);

      await tester.tap(find.byKey(const Key('faq_fiebre')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Se considera fiebre'), findsOneWidget);

      await tester.tap(find.byKey(const Key('faq_fiebre')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Se considera fiebre'), findsNothing);
    },
  );

  testWidgets('solo una pregunta queda abierta a la vez', (tester) async {
    await _montar(tester);

    await tester.tap(find.byKey(const Key('faq_fiebre')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('faq_cateter')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Se considera fiebre'), findsNothing);
    expect(find.textContaining('Mantén el apósito seco'), findsOneWidget);
  });

  testWidgets('la búsqueda en vivo filtra, sin distinguir tildes', (
    tester,
  ) async {
    await _montar(tester);

    await tester.tap(find.byKey(const Key('alternarBusquedaFaq')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'cateter');
    await tester.pumpAndSettle();

    expect(find.text(_preguntaCateter), findsOneWidget);
    expect(find.text(_preguntaFiebre), findsNothing);
    expect(find.text(_preguntaAlimentacion), findsNothing);
  });

  testWidgets('el chip de categoría filtra las preguntas', (tester) async {
    await _montar(tester);

    await tester.tap(find.byKey(const Key('chipCategoriaFaq_Alimentación')));
    await tester.pumpAndSettle();

    expect(find.text(_preguntaAlimentacion), findsOneWidget);
    expect(find.text(_preguntaFiebre), findsNothing);
    expect(find.text(_preguntaCateter), findsNothing);
  });

  testWidgets('devolverse a "Todas" restaura el listado completo', (
    tester,
  ) async {
    await _montar(tester);

    await tester.tap(find.byKey(const Key('chipCategoriaFaq_Fiebre')));
    await tester.pumpAndSettle();
    expect(find.text(_preguntaAlimentacion), findsNothing);

    await tester.tap(find.byKey(const Key('chipCategoriaFaq_Todas')));
    await tester.pumpAndSettle();

    expect(find.text(_preguntaFiebre), findsOneWidget);
    expect(find.text(_preguntaAlimentacion), findsOneWidget);
    expect(find.text(_preguntaCateter), findsOneWidget);
  });

  testWidgets('sin resultados de búsqueda muestra estado vacío', (
    tester,
  ) async {
    await _montar(tester);

    await tester.tap(find.byKey(const Key('alternarBusquedaFaq')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();

    expect(
      find.text('No se encontraron preguntas que coincidan con tu búsqueda.'),
      findsOneWidget,
    );
  });

  group('Enlace al material relacionado (CA-14.3)', () {
    final video = MaterialEducativo(
      id: 'videos-como-medir-la-fiebre',
      titulo: 'Cómo medir la fiebre',
      categoria: 'Videos',
      tema: 'Fiebre',
      cuerpo: 'Video paso a paso.',
      creadoEn: DateTime.utc(2026, 1, 1),
    );

    testWidgets('si el material existe, la respuesta enlaza a él', (
      tester,
    ) async {
      await _montar(tester, catalogo: [video]);
      await tester.tap(find.byKey(const Key('faq_fiebre')));
      await tester.pumpAndSettle();

      final enlace = find.byKey(const Key('verMaterial_fiebre'));
      expect(enlace, findsOneWidget);
      await tester.tap(enlace);
      await tester.pumpAndSettle();
      expect(find.text('Material videos-como-medir-la-fiebre'), findsOneWidget);
    });

    testWidgets('si el material no está en el catálogo, no hay enlace', (
      tester,
    ) async {
      await _montar(tester);
      await tester.tap(find.byKey(const Key('faq_fiebre')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Se considera fiebre'), findsOneWidget);
      expect(find.byKey(const Key('verMaterial_fiebre')), findsNothing);
    });
  });
}
