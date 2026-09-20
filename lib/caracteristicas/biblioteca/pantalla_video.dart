import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../../core/tema/paleta.dart';

String formatearDuracion(Duration d) {
  final minutos = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final segundos = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (d.inHours > 0) {
    return '${d.inHours}:$minutos:$segundos';
  }
  return '$minutos:$segundos';
}

class PantallaVideo extends StatefulWidget {
  const PantallaVideo({super.key, required this.archivo, required this.titulo});

  final File archivo;
  final String titulo;

  @override
  State<PantallaVideo> createState() => _PantallaVideoState();
}

class _PantallaVideoState extends State<PantallaVideo> {
  VideoPlayerController? _controlador;
  Timer? _timerControles;
  bool _inicializado = false;
  bool _mostrarControles = true;
  bool _hayError = false;
  String _mensajeError = '';

  @override
  void initState() {
    super.initState();
    _entrarApaisado();
    _inicializar();
  }

  Future<void> _inicializar() async {
    try {
      final controlador = VideoPlayerController.file(widget.archivo);
      _controlador = controlador;
      await controlador.initialize();
      if (!mounted || _controlador != controlador) {
        controlador.dispose();
        return;
      }
      controlador.addListener(_alCambiarProgreso);
      setState(() => _inicializado = true);
      await controlador.play();
      _reiniciarTimerControles();
    } catch (e) {
      if (mounted) {
        setState(() {
          _hayError = true;
          _mensajeError = e.toString();
        });
      }
    }
  }

  void _entrarApaisado() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _restaurarOrientacion() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    _timerControles?.cancel();
    final controlador = _controlador;
    if (controlador != null) {
      controlador.removeListener(_alCambiarProgreso);
      if (controlador.value.isPlaying) controlador.pause();
      controlador.dispose();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restaurarOrientacion();
    });
    super.dispose();
  }

  void _alCambiarProgreso() {
    if (mounted) setState(() {});
  }

  void _alternarReproduccion() {
    final controlador = _controlador;
    if (controlador == null || !_inicializado) return;
    if (controlador.value.isPlaying) {
      controlador.pause();
    } else {
      controlador.play();
    }
    _reiniciarTimerControles();
    setState(() {});
  }

  void _retroceder() {
    final controlador = _controlador;
    if (controlador == null || !_inicializado) return;
    final nuevaPosicion = controlador.value.position -
        const Duration(seconds: 10);
    controlador.seekTo(
      nuevaPosicion < Duration.zero ? Duration.zero : nuevaPosicion,
    );
    _reiniciarTimerControles();
  }

  void _avanzar() {
    final controlador = _controlador;
    if (controlador == null || !_inicializado) return;
    controlador.seekTo(
      controlador.value.position + const Duration(seconds: 10),
    );
    _reiniciarTimerControles();
  }

  void _alternarControles() {
    setState(() => _mostrarControles = !_mostrarControles);
    if (_mostrarControles) _reiniciarTimerControles();
  }

  void _reiniciarTimerControles() {
    _timerControles?.cancel();
    _timerControles = Timer(const Duration(seconds: 4), () {
      final controlador = _controlador;
      if (mounted && controlador != null && controlador.value.isPlaying) {
        setState(() => _mostrarControles = false);
      }
    });
  }

  void _cerrar() {
    _restaurarOrientacion();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cerrar();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: _alternarControles,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_hayError)
                _vistaError()
              else if (_inicializado && _controlador != null)
                Center(
                  child: AspectRatio(
                    aspectRatio: _controlador!.value.aspectRatio,
                    child: VideoPlayer(_controlador!),
                  ),
                )
              else
                const Center(
                  child: CircularProgressIndicator(
                    color: Paleta.doradoMedio,
                  ),
                ),
              if (_mostrarControles && _inicializado && !_hayError)
                _superposicionControles(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vistaError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'No se pudo reproducir el video',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _mensajeError,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(fontSize: 12, color: Colors.white54),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: _cerrar,
              style: TextButton.styleFrom(foregroundColor: Paleta.doradoMedio),
              child: Text(
                'Volver',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _superposicionControles() {
    final controlador = _controlador;
    if (controlador == null) return const SizedBox.shrink();
    final posicion = controlador.value.position;
    final duracion = controlador.value.duration;
    final reproduciendo = controlador.value.isPlaying;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.6),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.7),
          ],
          stops: const [0, 0.25, 0.75, 1],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              right: 12,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: _cerrar,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _botonSalto(
                icono: Icons.replay_10_rounded,
                alTocar: _retroceder,
              ),
              const SizedBox(width: 32),
              GestureDetector(
                onTap: _alternarReproduccion,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.95),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    reproduciendo
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
              ),
              const SizedBox(width: 32),
              _botonSalto(
                icono: Icons.forward_10_rounded,
                alTocar: _avanzar,
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 20,
              right: 20,
            ),
            child: Column(
              children: [
                VideoProgressIndicator(
                  controlador,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: Paleta.doradoPrincipal,
                    bufferedColor: Colors.white54,
                    backgroundColor: Colors.white24,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatearDuracion(posicion),
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      formatearDuracion(duracion),
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _botonSalto({
    required IconData icono,
    required VoidCallback alTocar,
  }) {
    return GestureDetector(
      onTap: alTocar,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.95),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icono, color: Colors.white, size: 32),
      ),
    );
  }
}