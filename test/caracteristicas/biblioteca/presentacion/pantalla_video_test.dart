// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/app/proveedores_navegacion.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/pantalla_video.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class _VideoFalso extends VideoPlayerPlatform with MockPlatformInterfaceMixin {
  final llamadas = <String>[];
  final _eventos = <int, StreamController<VideoEvent>>{};
  Duration posicion = Duration.zero;
  var _siguiente = 0;

  int _crear() {
    final id = _siguiente++;
    // ignore: close_sinks
    final eventos = StreamController<VideoEvent>();
    _eventos[id] = eventos;
    eventos.add(
      VideoEvent(
        eventType: VideoEventType.initialized,
        duration: const Duration(minutes: 5),
        size: const Size(1920, 1080),
      ),
    );
    return id;
  }

  @override
  Future<void> init() async {}

  @override
  Future<int?> create(DataSource dataSource) async => _crear();

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async =>
      _crear();

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => _eventos[playerId]!.stream;

  @override
  Future<void> dispose(int playerId) async {
    await _eventos.remove(playerId)?.close();
  }

  @override
  Future<void> play(int playerId) async => llamadas.add('play');

  @override
  Future<void> pause(int playerId) async => llamadas.add('pause');

  @override
  Future<void> seekTo(int playerId, Duration position) async {
    posicion = position;
    llamadas.add('seek:${position.inSeconds}');
  }

  @override
  Future<Duration> getPosition(int playerId) async => posicion;

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async =>
      llamadas.add('velocidad:$speed');

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}

  @override
  Widget buildView(int playerId) => const SizedBox.expand();

  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const SizedBox.expand();
}

void main() {
  late _VideoFalso video;
  late List<MethodCall> sistema;
  late ProviderContainer contenedor;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    video = _VideoFalso();
    VideoPlayerPlatform.instance = video;
    sistema = [];
  });

  Future<void> abrir(WidgetTester tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (llamada) async {
        sistema.add(llamada);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    contenedor = ProviderContainer();
    addTearDown(contenedor.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: contenedor,
        child: MaterialApp(
          home: PantallaVideo(
            archivo: File('video-prueba.mp4'),
            titulo: 'Cómo medir la fiebre',
            idContenido: 'video-prueba',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> cerrar(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  }

  Object? ultima(String metodo) =>
      sistema.lastWhere((l) => l.method == metodo).arguments;

  testWidgets('se abre en vertical, con barra superior y sin inmersivo', (
    tester,
  ) async {
    await abrir(tester);

    expect(
      sistema.where((l) => l.method == 'SystemChrome.setEnabledSystemUIMode'),
      isEmpty,
    );
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Cómo medir la fiebre'), findsOneWidget);
    expect(find.byIcon(Icons.fullscreen), findsOneWidget);
    expect(video.llamadas, contains('play'));

    await cerrar(tester);
  });

  testWidgets(
    'pantalla completa: inmersivo, apaisado y sin barras; al salir se restaura',
    (tester) async {
      await abrir(tester);

      await tester.tap(find.byKey(const Key('alternarPantallaCompleta')));
      await tester.pump();
      expect(
        ultima('SystemChrome.setEnabledSystemUIMode'),
        'SystemUiMode.immersiveSticky',
      );
      expect(ultima('SystemChrome.setPreferredOrientations'), [
        'DeviceOrientation.landscapeLeft',
        'DeviceOrientation.landscapeRight',
      ]);
      expect(find.byType(AppBar), findsNothing);
      expect(find.byIcon(Icons.fullscreen_exit), findsOneWidget);
      expect(contenedor.read(pantallaCompletaProvider), isTrue);

      await tester.tap(find.byKey(const Key('alternarPantallaCompleta')));
      await tester.pump();
      expect(
        ultima('SystemChrome.setEnabledSystemUIMode'),
        'SystemUiMode.edgeToEdge',
      );
      expect(ultima('SystemChrome.setPreferredOrientations'), [
        'DeviceOrientation.portraitUp',
        'DeviceOrientation.portraitDown',
      ]);
      expect(find.byType(AppBar), findsOneWidget);
      expect(contenedor.read(pantallaCompletaProvider), isFalse);

      await cerrar(tester);
    },
  );

  testWidgets('salir de la pantalla en pantalla completa restaura todo', (
    tester,
  ) async {
    await abrir(tester);
    await tester.tap(find.byKey(const Key('alternarPantallaCompleta')));
    await tester.pump();
    expect(contenedor.read(pantallaCompletaProvider), isTrue);

    await cerrar(tester);

    expect(
      ultima('SystemChrome.setEnabledSystemUIMode'),
      'SystemUiMode.edgeToEdge',
    );
    expect(ultima('SystemChrome.setPreferredOrientations'), [
      'DeviceOrientation.portraitUp',
      'DeviceOrientation.portraitDown',
    ]);
    expect(contenedor.read(pantallaCompletaProvider), isFalse);
  });

  testWidgets('elegir velocidad la aplica y marca la actual', (tester) async {
    await abrir(tester);
    expect(find.text('1×'), findsOneWidget);

    await tester.tap(find.byKey(const Key('velocidadVideo')));
    await tester.pumpAndSettle();
    for (final etiqueta in ['0.5×', '0.75×', 'Normal (1×)', '1.25×', '1.5×']) {
      expect(find.text(etiqueta), findsOneWidget);
    }
    expect(
      find.descendant(
        of: find.byKey(const Key('opcionVelocidad_1.0')),
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('opcionVelocidad_1.5')));
    await tester.pumpAndSettle();
    expect(video.llamadas.last, 'velocidad:1.5');
    expect(find.text('1.5×'), findsOneWidget);

    await tester.tap(find.byKey(const Key('velocidadVideo')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('opcionVelocidad_1.5')),
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('opcionVelocidad_0.5')));
    await tester.pumpAndSettle();
    expect(video.llamadas.last, 'velocidad:0.5');

    await cerrar(tester);
  });

  test('etiquetaVelocidad abrevia las velocidades', () {
    expect(velocidadesReproduccion.map(etiquetaVelocidad).toList(), [
      '0.5×',
      '0.75×',
      '1×',
      '1.25×',
      '1.5×',
      '2×',
    ]);
  });

  testWidgets('muestra los controles y la barra de progreso arrastrable', (
    tester,
  ) async {
    await abrir(tester);

    expect(find.byIcon(Icons.replay_10_rounded), findsOneWidget);
    expect(find.byIcon(Icons.forward_10_rounded), findsOneWidget);
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    final barra = tester.widget<VideoProgressIndicator>(
      find.byType(VideoProgressIndicator),
    );
    expect(barra.allowScrubbing, isTrue);

    await cerrar(tester);
  });

  testWidgets('pausar, retroceder y avanzar 10 segundos', (tester) async {
    await abrir(tester);
    video.posicion = const Duration(seconds: 30);
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump();
    expect(video.llamadas.last, 'pause');
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.forward_10_rounded));
    await tester.pump();
    expect(video.llamadas, contains('seek:40'));

    await tester.tap(find.byIcon(Icons.replay_10_rounded));
    await tester.pump();
    expect(video.llamadas.last, 'seek:30');

    await cerrar(tester);
  });
}
