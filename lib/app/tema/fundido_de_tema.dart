import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class FundidoDeTema extends StatefulWidget {
  const FundidoDeTema({super.key, required this.oscuro, required this.child});

  final bool oscuro;
  final Widget child;

  static const duracion = Duration(milliseconds: 380);

  @override
  State<FundidoDeTema> createState() => _FundidoDeTemaState();
}

class _FundidoDeTemaState extends State<FundidoDeTema> {
  final _llave = GlobalKey();
  ui.Image? _anterior;
  double _ratio = 1;

  @override
  void didUpdateWidget(FundidoDeTema anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.oscuro != widget.oscuro) _capturar();
  }

  void _capturar() {
    final objeto = _llave.currentContext?.findRenderObject();
    if (objeto is! RenderRepaintBoundary) return;
    try {
      final ratio = MediaQuery.devicePixelRatioOf(context);
      final foto = objeto.toImageSync(pixelRatio: ratio);
      _anterior?.dispose();
      _anterior = foto;
      _ratio = ratio;
    } catch (_) {
      _anterior = null;
    }
  }

  void _soltar() {
    if (!mounted) return;
    setState(() {
      _anterior?.dispose();
      _anterior = null;
    });
  }

  @override
  void dispose() {
    _anterior?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foto = _anterior;
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(key: _llave, child: widget.child),
        if (foto != null)
          Positioned.fill(
            child: IgnorePointer(
              child: TweenAnimationBuilder<double>(
                key: ObjectKey(foto),
                tween: Tween<double>(begin: 1, end: 0),
                duration: FundidoDeTema.duracion,
                curve: Curves.easeOut,
                onEnd: _soltar,
                builder: (_, opacidad, _) => Opacity(
                  opacity: opacidad,
                  child: RawImage(
                    key: const Key('fotoModoAnterior'),
                    image: foto,
                    fit: BoxFit.fill,
                    scale: _ratio,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
