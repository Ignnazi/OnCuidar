// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

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
    await tester.pumpWidget(
      MaterialApp(
        home: PantallaVideo(
          archivo: File('video-prueba.mp4'),
          titulo: 'Cómo medir la fiebre',
          idContenido: 'video-prueba',
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

  testWidgets('se abre en horizontal y a pantalla inmersiva', (tester) async {
    await abrir(tester);

    final orientacion = sistema.firstWhere(
      (l) => l.method == 'SystemChrome.setPreferredOrientations',
    );
    expect(orientacion.arguments, [
      'DeviceOrientation.landscapeLeft',
      'DeviceOrientation.landscapeRight',
    ]);
    final modo = sistema.firstWhere(
      (l) => l.method == 'SystemChrome.setEnabledSystemUIMode',
    );
    expect(modo.arguments, 'SystemUiMode.immersiveSticky');
    expect(video.llamadas, contains('play'));

    await cerrar(tester);
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
