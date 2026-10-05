import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oncuidar/compartido/widgets/barra_visor.dart';

class MarcoVisor extends StatefulWidget {
  const MarcoVisor({
    super.key,
    required this.titulo,
    required this.cuerpo,
    this.claveVolver,
    this.acciones = const [],
    this.fondo = const Color(0xFF0B0B0D),
  });

  final String titulo;
  final Widget cuerpo;
  final Key? claveVolver;
  final List<Widget> acciones;
  final Color fondo;

  @override
  State<MarcoVisor> createState() => _MarcoVisorState();
}

class _MarcoVisorState extends State<MarcoVisor> {
  bool _horizontal = false;

  @override
  void dispose() {
    if (_horizontal) _restaurarSistema();
    super.dispose();
  }

  static void _restaurarSistema() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void _alternarGiro() {
    final horizontal = !_horizontal;
    if (horizontal) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      _restaurarSistema();
    }
    setState(() => _horizontal = horizontal);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_horizontal,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _horizontal) _alternarGiro();
      },
      child: Scaffold(
        backgroundColor: widget.fondo,
        appBar: _horizontal
            ? barraVisor(
                titulo: widget.titulo,
                claveVolver: const Key('girarVisor'),
                iconoVolver: Icons.screen_lock_portrait_rounded,
                ayudaVolver: 'Volver a vertical',
                alVolver: _alternarGiro,
                acciones: widget.acciones,
              )
            : barraVisor(
                titulo: widget.titulo,
                claveVolver: widget.claveVolver,
                alVolver: () => Navigator.of(context).maybePop(),
                acciones: [
                  IconButton(
                    key: const Key('girarVisor'),
                    tooltip: 'Girar a pantalla completa',
                    icon: const Icon(Icons.screen_rotation_rounded),
                    onPressed: _alternarGiro,
                  ),
                  ...widget.acciones,
                ],
              ),
        body: widget.cuerpo,
      ),
    );
  }
}
