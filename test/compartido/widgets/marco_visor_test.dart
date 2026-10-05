import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/compartido/widgets/marco_visor.dart';

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
                  cuerpo: ColoredBox(color: Colors.teal),
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

  testWidgets('el botón gira a horizontal en pantalla completa', (
    tester,
  ) async {
    await abrir(tester);
    expect(find.byKey(const Key('girarVisor')), findsOneWidget);

    await tester.tap(find.byKey(const Key('girarVisor')));
    await tester.pump();

    expect(ultimaOrientacion(), [
      'DeviceOrientation.landscapeLeft',
      'DeviceOrientation.landscapeRight',
    ]);
    expect(llamadas.last.arguments, 'SystemUiMode.immersiveSticky');
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Guía'), findsOneWidget);
    expect(find.byKey(const Key('volver')), findsNothing);
    expect(find.byIcon(Icons.screen_lock_portrait_rounded), findsOneWidget);
    expect(find.byIcon(Icons.screen_rotation_rounded), findsNothing);
    final boton = tester.getRect(find.byKey(const Key('girarVisor')));
    expect(boton.left, lessThan(60));
  });

  testWidgets('el mismo botón vuelve a vertical', (tester) async {
    await abrir(tester);
    await tester.tap(find.byKey(const Key('girarVisor')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('girarVisor')));
    await tester.pump();

    expect(ultimaOrientacion(), [
      'DeviceOrientation.portraitUp',
      'DeviceOrientation.portraitDown',
    ]);
    expect(find.byIcon(Icons.screen_rotation_rounded), findsOneWidget);
  });

  testWidgets('atrás primero vuelve a vertical y después cierra', (
    tester,
  ) async {
    await abrir(tester);
    await tester.tap(find.byKey(const Key('girarVisor')));
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
    await tester.tap(find.byKey(const Key('girarVisor')));
    await tester.pump();

    Navigator.of(tester.element(find.byType(MarcoVisor))).pop();
    await tester.pumpAndSettle();

    expect(find.byType(MarcoVisor), findsNothing);
    expect(ultimaOrientacion()!.first, 'DeviceOrientation.portraitUp');
  });

  testWidgets(
    'título a la izquierda y botones en orden: girar, descargar, compartir',
    (tester) async {
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

      final girar = tester.getCenter(find.byKey(const Key('girarVisor'))).dx;
      final descargar = tester.getCenter(find.byKey(const Key('descargar'))).dx;
      final compartir = tester.getCenter(find.byKey(const Key('compartir'))).dx;
      expect(girar, lessThan(descargar));
      expect(descargar, lessThan(compartir));

      final titulo = tester.getRect(find.text('Historial clínico'));
      final ancho = tester.getSize(find.byType(AppBar)).width;
      expect(titulo.left, lessThan(ancho * 0.25));
    },
  );
}
