import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/proveedores_navegacion.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/biblioteca/datos/proveedores_biblioteca.dart';
import 'package:oncuidar/caracteristicas/biblioteca/datos/servicio_cache_contenido.dart';
import 'package:oncuidar/compartido/widgets/aviso_sin_conexion.dart';
import 'package:oncuidar/compartido/widgets/barra_visor.dart';
import 'package:oncuidar/nucleo/proveedores.dart';
import 'package:video_player/video_player.dart';

String formatearDuracion(Duration d) {
  final minutos = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final segundos = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (d.inHours > 0) {
    return '${d.inHours}:$minutos:$segundos';
  }
  return '$minutos:$segundos';
}

Future<Duration?> posicionParaRetomar(
  String idContenido,
  Duration duracion,
) async {
  final guardado = await leerAvanceVideo(idContenido);
  if (guardado <= 0) return null;
  if (guardado >= duracion.inMilliseconds - 2000) return null;
  return Duration(milliseconds: guardado);
}

const velocidadesReproduccion = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

String etiquetaVelocidad(double velocidad) {
  final texto = velocidad == velocidad.roundToDouble()
      ? velocidad.toStringAsFixed(0)
      : velocidad.toString();
  return '$texto×';
}

const _mensajeErrorVideo = 'No se pudo reproducir el video.';

class PantallaVideo extends ConsumerStatefulWidget {
  const PantallaVideo({
    super.key,
    required this.archivo,
    required this.titulo,
    required this.idContenido,
    this.urlArchivo,
  });

  final File archivo;

  final String? urlArchivo;
  final String titulo;

  final String idContenido;

  @override
  ConsumerState<PantallaVideo> createState() => _PantallaVideoState();
}

class _PantallaVideoState extends ConsumerState<PantallaVideo> {
  VideoPlayerController? _controlador;
  Timer? _timerControles;
  late final PantallaCompletaNotifier _notificadorPantallaCompleta;
  bool _inicializado = false;
  bool _mostrarControles = true;
  bool _pantallaCompleta = false;
  bool _hayError = false;
  bool _reintentoHecho = false;
  String _mensajeError = _mensajeErrorVideo;
  late File _archivo = widget.archivo;

  @override
  void initState() {
    super.initState();
    _notificadorPantallaCompleta = ref.read(pantallaCompletaProvider.notifier);
    _inicializar();
  }

  void _soltarControlador() {
    final anterior = _controlador;
    _controlador = null;
    if (anterior == null) return;
    anterior.removeListener(_alCambiarProgreso);
    unawaited(anterior.dispose());
  }

  Future<void> _inicializar({bool redescargar = false}) async {
    VideoPlayerController? controlador;
    try {
      if (redescargar) {
        _soltarControlador();
        if (mounted) {
          setState(() {
            _hayError = false;
            _inicializado = false;
          });
        }
        _archivo = await ref
            .read(servicioCacheContenidoProvider)
            .redescargar(widget.urlArchivo!);
        if (!mounted) return;
      }
      controlador = VideoPlayerController.file(_archivo);
      _controlador = controlador;
      await controlador.initialize();
      if (!mounted || _controlador != controlador) {
        unawaited(controlador.dispose());
        return;
      }
      controlador.addListener(_alCambiarProgreso);
      setState(() => _inicializado = true);
      await _restaurarPosicion(controlador);
      await controlador.play();
      _reiniciarTimerControles();
    } catch (_) {
      if (_controlador != controlador) return;
      await _manejarFallo();
    }
  }

  Future<void> _manejarFallo() async {
    if (!mounted || _hayError) return;
    if (!_reintentoHecho && widget.urlArchivo != null) {
      _reintentoHecho = true;
      await _inicializar(redescargar: true);
      return;
    }
    var mensaje = _mensajeErrorVideo;
    try {
      if (widget.urlArchivo != null &&
          ref.read(estadoConexionProvider).value == false) {
        mensaje = TextosSinConexion.video;
      }
    } catch (_) {}
    _soltarControlador();
    setState(() {
      _hayError = true;
      _inicializado = false;
      _mensajeError = mensaje;
    });
  }

  /// Reintento manual desde el estado de error.
  void _reintentarManual() {
    setState(() {
      _hayError = false;
      _inicializado = false;
    });
    unawaited(_inicializar(redescargar: widget.urlArchivo != null));
  }

  Future<void> _restaurarPosicion(VideoPlayerController controlador) async {
    try {
      final retomar = await posicionParaRetomar(
        widget.idContenido,
        controlador.value.duration,
      );
      if (retomar != null) await controlador.seekTo(retomar);
    } catch (_) {
      // Si falla, se sigue igual.
    }
  }

  Future<void> _guardarPosicion() async {
    final controlador = _controlador;
    if (controlador == null || !_inicializado) return;
    try {
      await guardarAvanceVideo(widget.idContenido, controlador.value.position);
    } catch (_) {}
  }

  void _entrarPantallaCompleta() {
    final controlador = _controlador;
    final horizontal =
        controlador == null || controlador.value.aspectRatio >= 1;
    SystemChrome.setPreferredOrientations(
      horizontal
          ? [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
          : [DeviceOrientation.portraitUp],
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _restaurarSistema() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void _alternarPantallaCompleta() {
    final completa = !_pantallaCompleta;
    if (completa) {
      _entrarPantallaCompleta();
    } else {
      _restaurarSistema();
    }
    _notificadorPantallaCompleta.fijar(completa);
    setState(() => _pantallaCompleta = completa);
    _reiniciarTimerControles();
  }

  @override
  void dispose() {
    _timerControles?.cancel();
    _guardarPosicion();
    final controlador = _controlador;
    if (controlador != null) {
      controlador.removeListener(_alCambiarProgreso);
      if (controlador.value.isPlaying) controlador.pause();
      controlador.dispose();
    }
    _restaurarSistema();
    final notificador = _notificadorPantallaCompleta;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        notificador.fijar(false);
      } catch (_) {}
    });
    super.dispose();
  }

  void _alCambiarProgreso() {
    if (!mounted) return;
    if (_controlador?.value.hasError ?? false) {
      unawaited(_manejarFallo());
      return;
    }
    setState(() {});
  }

  void _alternarReproduccion() {
    final controlador = _controlador;
    if (controlador == null || !_inicializado) return;
    if (controlador.value.isPlaying) {
      controlador.pause();
      _guardarPosicion();
    } else {
      controlador.play();
    }
    _reiniciarTimerControles();
    setState(() {});
  }

  void _reiniciar() {
    final controlador = _controlador;
    if (controlador == null || !_inicializado) return;
    controlador.seekTo(Duration.zero);
    controlador.play();
    _reiniciarTimerControles();
    setState(() {});
  }

  void _retroceder() {
    final controlador = _controlador;
    if (controlador == null || !_inicializado) return;
    final nuevaPosicion =
        controlador.value.position - const Duration(seconds: 10);
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

  Future<void> _elegirVelocidad() async {
    final controlador = _controlador;
    if (controlador == null || !_inicializado) return;
    _timerControles?.cancel();
    final elegida = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _HojaVelocidad(actual: controlador.value.playbackSpeed),
    );
    if (elegida != null && mounted) {
      await controlador.setPlaybackSpeed(elegida);
      if (mounted) setState(() {});
    }
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
    _restaurarSistema();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_pantallaCompleta) {
          _alternarPantallaCompleta();
        } else {
          _cerrar();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: _pantallaCompleta ? null : _barraSuperior(),
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
                Center(
                  child: CircularProgressIndicator(color: Paleta.doradoMedio),
                ),
              if (_mostrarControles && _inicializado && !_hayError)
                _superposicionControles(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _barraSuperior() {
    return barraVisor(
      titulo: widget.titulo,
      alVolver: _cerrar,
      acciones: [
        IconButton(
          key: const Key('alternarPantallaCompleta'),
          tooltip: 'Girar a pantalla completa',
          icon: const Icon(Icons.screen_rotation_rounded),
          onPressed: _alternarPantallaCompleta,
        ),
      ],
    );
  }

  Widget _vistaError() {
    final estiloBoton = GoogleFonts.nunito(
      fontSize: 14,
      fontWeight: FontWeight.w700,
    );
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Semantics(
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.videocam_off_outlined,
                color: Paleta.doradoMedio,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _mensajeError,
                key: const Key('mensajeErrorVideo'),
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton(
                    key: const Key('reintentarVideo'),
                    onPressed: _reintentarManual,
                    style: FilledButton.styleFrom(
                      backgroundColor: Paleta.doradoPrincipal,
                      foregroundColor: Paleta.sobreDorado,
                      textStyle: estiloBoton,
                    ),
                    child: const Text('Reintentar'),
                  ),
                  TextButton(
                    key: const Key('volverDeVideo'),
                    onPressed: _cerrar,
                    style: TextButton.styleFrom(
                      foregroundColor: Paleta.doradoMedio,
                      textStyle: estiloBoton,
                    ),
                    child: const Text('Volver'),
                  ),
                ],
              ),
            ],
          ),
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
            Colors.black.withValues(alpha: _pantallaCompleta ? 0.6 : 0),
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
          if (_pantallaCompleta)
            _filaTituloPantallaCompleta()
          else
            const SizedBox.shrink(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _botonSalto(icono: Icons.replay_10_rounded, alTocar: _retroceder),
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
              _botonSalto(icono: Icons.forward_10_rounded, alTocar: _avanzar),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 12,
              left: 20,
              right: 12,
            ),
            child: Column(
              children: [
                VideoProgressIndicator(
                  controlador,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                    playedColor: Paleta.doradoPrincipal,
                    bufferedColor: Colors.white54,
                    backgroundColor: Colors.white24,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                Row(
                  children: [
                    Text(
                      '${formatearDuracion(posicion)} / '
                      '${formatearDuracion(duracion)}',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      key: const Key('reiniciarVideo'),
                      tooltip: 'Reiniciar',
                      onPressed: _reiniciar,
                      icon: const Icon(
                        Icons.restart_alt_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    _chipVelocidad(controlador.value.playbackSpeed),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filaTituloPantallaCompleta() {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 12,
        right: 12,
      ),
      child: Row(
        children: [
          IconButton(
            key: const Key('alternarPantallaCompleta'),
            tooltip: 'Volver a vertical',
            icon: const Icon(
              Icons.screen_lock_portrait_rounded,
              color: Colors.white,
            ),
            onPressed: _alternarPantallaCompleta,
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
    );
  }

  Widget _chipVelocidad(double velocidad) {
    return Tooltip(
      message: 'Velocidad de reproducción',
      child: InkWell(
        key: const Key('velocidadVideo'),
        onTap: _elegirVelocidad,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
          ),
          child: Text(
            etiquetaVelocidad(velocidad),
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _botonSalto({required IconData icono, required VoidCallback alTocar}) {
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

class _HojaVelocidad extends StatelessWidget {
  const _HojaVelocidad({required this.actual});

  final double actual;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Velocidad de reproducción',
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            for (final velocidad in velocidadesReproduccion)
              ListTile(
                key: Key('opcionVelocidad_$velocidad'),
                dense: true,
                onTap: () => Navigator.of(context).pop(velocidad),
                leading: SizedBox(
                  width: 24,
                  child: velocidad == actual
                      ? Icon(Icons.check_rounded, color: Paleta.doradoMedio)
                      : null,
                ),
                title: Text(
                  velocidad == 1.0
                      ? 'Normal (1×)'
                      : etiquetaVelocidad(velocidad),
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: velocidad == actual
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
