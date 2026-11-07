import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/material_educativo.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/proveedores_biblioteca.dart';
import 'package:oncuidar/caracteristicas/preguntas_frecuentes/presentacion/pantalla_preguntas_frecuentes.dart';

const _preguntaFiebre =
    '¿En qué momento una fiebre se convierte en una emergencia?';
const _preguntaCateter = '¿Qué cuidados se deben tener con el catéter central?';
const _preguntaAlimentacion =
    '¿Qué alimentos no se recomiendan en niños con cáncer?';

Widget _pantalla({List<MaterialEducativo> catalogo = const []}) {
  final router = GoRouter(
    initialLocation: '/faq',
    routes: [
      GoRoute(path: '/faq', builder: (c, s) => const FaqScreen()),
      GoRoute(
        path: '/biblioteca',
        builder: (c, s) => Scaffold(
          body: Center(
            child: Text('Biblioteca abre ${s.uri.queryParameters['abrir']}'),
          ),
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
  tester.view.physicalSize = const Size(1200, 4000);
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
    expect(
      find.byKey(const Key('chipCategoriaFaq_Fiebre y urgencias')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('chipCategoriaFaq_Catéter')), findsOneWidget);
    expect(
      find.byKey(const Key('chipCategoriaFaq_Alimentación')),
      findsOneWidget,
    );
    expect(find.textContaining('Siempre la fiebre es urgente'), findsNothing);
  });

  testWidgets(
    'tocar una pregunta expande su respuesta y al tocar de nuevo la cierra',
    (tester) async {
      await _montar(tester);

      await tester.tap(find.byKey(const Key('faq_fiebre')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Siempre la fiebre es urgente'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('faq_fiebre')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Siempre la fiebre es urgente'), findsNothing);
    },
  );

  testWidgets('solo una pregunta queda abierta a la vez', (tester) async {
    await _montar(tester);

    await tester.tap(find.byKey(const Key('faq_fiebre')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('faq_cateter-cuidados')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Siempre la fiebre es urgente'), findsNothing);
    expect(
      find.textContaining('Muchas quimioterapias irritan las venas'),
      findsOneWidget,
    );
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

    await tester.tap(
      find.byKey(const Key('chipCategoriaFaq_Fiebre y urgencias')),
    );
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
      id: 'guia-del-cateter-venoso-central-pediatrico',
      titulo: 'Guía del catéter venoso central pediátrico',
      categoria: 'Infografías',
      tema: 'Catéter',
      cuerpo: 'Cuidados del catéter.',
      creadoEn: DateTime.utc(2026, 1, 1),
    );

    testWidgets('si el material existe, la respuesta enlaza a él', (
      tester,
    ) async {
      await _montar(tester, catalogo: [video]);
      await tester.tap(find.byKey(const Key('faq_cateter-cuidados')));
      await tester.pumpAndSettle();

      final enlace = find.byKey(const Key('verMaterial_cateter-cuidados'));
      expect(enlace, findsOneWidget);
      await tester.tap(enlace);
      await tester.pumpAndSettle();
      expect(
        find.text('Biblioteca abre guia-del-cateter-venoso-central-pediatrico'),
        findsOneWidget,
      );
    });

    testWidgets('si el material no está en el catálogo, no hay enlace', (
      tester,
    ) async {
      await _montar(tester);
      await tester.tap(find.byKey(const Key('faq_cateter-cuidados')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Muchas quimioterapias irritan las venas'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('verMaterial_cateter-cuidados')),
        findsNothing,
      );
    });
  });
}
