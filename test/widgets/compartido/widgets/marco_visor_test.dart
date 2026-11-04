import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/compartido/widgets/marco_visor.dart';

class _CuerpoGirable extends StatelessWidget {
  const _CuerpoGirable();

  @override
  Widget build(BuildContext context) {
    final giro = ControlGiroVisor.maybeOf(context)!;
    return ColoredBox(
      color: Colors.teal,
      child: Center(
        child: TextButton(
          key: const Key('girarCuerpo'),
          onPressed: giro.alternarGiro,
          child: Text(giro.horizontal ? 'horizontal' : 'vertical'),
        ),
      ),
    );
  }
}

void main() {
  late List<MethodCall> llamadas;

  setUp(() {
    llamadas = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (llamada) async {
          llamadas.add(llamada);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  List<String>? ultimaOrientacion() {
    final llamada = llamadas.lastWhere(
      (l) => l.method == 'SystemChrome.setPreferredOrientations',
      orElse: () => const MethodCall(''),
    );
    return (llamada.arguments as List?)?.cast<String>();
  }

  Future<void> abrir(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const MarcoVisor(
                  titulo: 'Guía',
                  claveVolver: Key('volver'),
                  cuerpo: _CuerpoGirable(),
                ),
              ),
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('los controles del cuerpo giran a horizontal', (tester) async {
    await abrir(tester);
    expect(find.byKey(const Key('girarCuerpo')), findsOneWidget);
    expect(find.byKey(const Key('salirHorizontal')), findsNothing);

    await tester.tap(find.byKey(const Key('girarCuerpo')));
    await tester.pump();

    expect(ultimaOrientacion(), [
      'DeviceOrientation.landscapeLeft',
      'DeviceOrientation.landscapeRight',
    ]);
    expect(llamadas.last.arguments, 'SystemUiMode.immersiveSticky');
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Guía'), findsOneWidget);
    expect(find.byKey(const Key('volver')), findsNothing);
    expect(find.text('horizontal'), findsOneWidget);
    final boton = tester.getRect(find.byKey(const Key('salirHorizontal')));
    expect(boton.left, lessThan(60));
  });

  testWidgets('el mismo control vuelve a vertical', (tester) async {
    await abrir(tester);
    await tester.tap(find.byKey(const Key('girarCuerpo')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('girarCuerpo')));
    await tester.pump();

    expect(ultimaOrientacion(), [
      'DeviceOrientation.portraitUp',
      'DeviceOrientation.portraitDown',
    ]);
    expect(find.text('vertical'), findsOneWidget);
    expect(find.byKey(const Key('volver')), findsOneWidget);
  });

  testWidgets('atrás primero vuelve a vertical y después cierra', (
    tester,
  ) async {
    await abrir(tester);
    await tester.tap(find.byKey(const Key('girarCuerpo')));
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(MarcoVisor), findsOneWidget);
    expect(ultimaOrientacion()!.first, 'DeviceOrientation.portraitUp');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(MarcoVisor), findsNothing);
  });

  testWidgets('cerrar el visor girado deja la app en vertical', (tester) async {
    await abrir(tester);
    await tester.tap(find.byKey(const Key('girarCuerpo')));
    await tester.pump();

    Navigator.of(tester.element(find.byType(MarcoVisor))).pop();
    await tester.pumpAndSettle();

    expect(find.byType(MarcoVisor), findsNothing);
    expect(ultimaOrientacion()!.first, 'DeviceOrientation.portraitUp');
  });

  testWidgets('la barra superior ya no lleva el botón de girar', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MarcoVisor(titulo: 'Guía', cuerpo: SizedBox()),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.screen_rotation_rounded),
      ),
      findsNothing,
    );
  });

  testWidgets('título a la izquierda y acciones en orden', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MarcoVisor(
          titulo: 'Historial clínico',
          cuerpo: const SizedBox(),
          acciones: [
            IconButton(
              key: const Key('descargar'),
              icon: const Icon(Icons.download_rounded),
              onPressed: () {},
            ),
            IconButton(
              key: const Key('compartir'),
              icon: const Icon(Icons.share_rounded),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );

    final descargar = tester.getCenter(find.byKey(const Key('descargar'))).dx;
    final compartir = tester.getCenter(find.byKey(const Key('compartir'))).dx;
    expect(descargar, lessThan(compartir));

    final titulo = tester.getRect(find.text('Historial clínico'));
    final ancho = tester.getSize(find.byType(AppBar)).width;
    expect(titulo.left, lessThan(ancho * 0.25));
  });

  testWidgets(
    'la barra de todos los visores lleva el degradado dorado visible',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MarcoVisor(titulo: 'Guía', cuerpo: SizedBox()),
        ),
      );

      final degradado = find.descendant(
        of: find.byType(AppBar),
        matching: find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).gradient != null,
        ),
      );
      expect(degradado, findsOneWidget);
      expect(tester.getSize(degradado).height, greaterThan(40));
    },
  );
}
