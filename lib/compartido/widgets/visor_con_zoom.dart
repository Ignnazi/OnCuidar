import 'dart:async';

import 'package:flutter/material.dart';
import 'package:oncuidar/compartido/widgets/controles_zoom.dart';

/// Escala a la que acerca el doble toque.
const _escalaDobleToque = 2.0;

const _esperaNitidez = Duration(milliseconds: 120);

typedef ConstructorZoom = Widget Function(Size zona, double factor);

class VisorConZoom extends StatefulWidget {
  const VisorConZoom({
    super.key,
    required this.constructor,
    this.escalaInicial = _uno,
    this.escalaAjuste = _uno,
    this.zoomMinimo = _uno,
    this.zoomMaximo = 8,
    this.alineacion = Alignment.center,
    this.sobreOscuro = true,
    this.claveVisor,
    this.alMover,
    this.pie,
  });

  final ConstructorZoom constructor;

  /// Escala con la que se abre.
  final double Function(Size zona) escalaInicial;

  final double Function(Size zona) escalaAjuste;

  final double Function(Size zona) zoomMinimo;
  final double zoomMaximo;

  final Alignment alineacion;
  final bool sobreOscuro;
  final Key? claveVisor;

  final void Function(Matrix4 matriz, Size zona, double factor)? alMover;

  final Widget? pie;

  static double _uno(Size _) => 1;

  @override
  State<VisorConZoom> createState() => EstadoVisorConZoom();
}

class EstadoVisorConZoom extends State<VisorConZoom>
    with SingleTickerProviderStateMixin {
  TransformationController? _transformacion;
  late final AnimationController _animacion;
  Animation<Matrix4>? _animacionMatriz;
  Size _zona = Size.zero;
  Offset _puntoDobleToque = Offset.zero;

  double _factor = 1;
  Timer? _temporizador;
  bool _asentando = false;

  @override
  void initState() {
    super.initState();
    _animacion =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 250),
        )..addListener(() {
          final matriz = _animacionMatriz;
          if (matriz != null) _transformacion?.value = matriz.value;
        });
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    _animacion.dispose();
    _transformacion?.removeListener(_alCambiar);
    _transformacion?.dispose();
    super.dispose();
  }

  @visibleForTesting
  double get escalaTotal => _factor * escalaDe(_transformacion!.value);

  double get _minimo => widget.zoomMinimo(_zona);

  void _alCambiar() {
    final t = _transformacion;
    if (t == null) return;
    widget.alMover?.call(t.value, _zona, _factor);
    if (_asentando) return;
    _temporizador?.cancel();
    _temporizador = Timer(_esperaNitidez, _asentar);
  }

  void _asentar() {
    final t = _transformacion;
    if (!mounted || t == null || _animacion.isAnimating) return;
    final estirado = escalaDe(t.value);
    if ((estirado - 1).abs() < 0.001) return;
    final traslado = t.value.getTranslation();
    _asentando = true;
    setState(() {
      _factor *= estirado;
      t.value = Matrix4.translationValues(traslado.x, traslado.y, 0);
    });
    _asentando = false;
    widget.alMover?.call(t.value, _zona, _factor);
  }

  void _irAEscala(double escala) {
    _temporizador?.cancel();
    _animacion.stop();
    _asentando = true;
    setState(() {
      _factor = escala;
      _transformacion?.value = Matrix4.identity();
    });
    _asentando = false;
    final t = _transformacion;
    if (t != null) widget.alMover?.call(t.value, _zona, _factor);
  }

  Matrix4 _zoomHacia(double factor, Offset centro) => zoomAlrededor(
    _transformacion!.value,
    factor,
    centro,
    minima: _minimo / _factor,
    maxima: widget.zoomMaximo / _factor,
  );

  void _acercar(double factor) {
    _animacion.stop();
    _transformacion!.value = _zoomHacia(
      factor,
      Offset(_zona.width / 2, _zona.height / 2),
    );
    _asentar();
  }

  void _animarA(Matrix4 destino) {
    _animacionMatriz = Matrix4Tween(
      begin: _transformacion!.value,
      end: destino,
    ).animate(CurvedAnimation(parent: _animacion, curve: Curves.easeOut));
    _animacion.forward(from: 0).whenComplete(_asentar);
  }

  void _alDobleToque() {
    final escala = escalaTotal;
    if (escala < _escalaDobleToque * 0.7) {
      _animarA(_zoomHacia(_escalaDobleToque / escala, _puntoDobleToque));
    } else {
      _irAEscala(widget.escalaInicial(_zona));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        final zonaAnterior = _zona;
        _zona = restricciones.biggest;
        if (_transformacion == null) {
          _factor = widget.escalaInicial(_zona);
          _transformacion = TransformationController()..addListener(_alCambiar);
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => mounted
                ? widget.alMover?.call(_transformacion!.value, _zona, _factor)
                : null,
          );
        } else if (zonaAnterior.width != _zona.width &&
            zonaAnterior != Size.zero) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => mounted ? _irAEscala(widget.escalaInicial(_zona)) : null,
          );
        }
        final minimo = _minimo;
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onDoubleTapDown: (d) => _puntoDobleToque = d.localPosition,
                onDoubleTap: _alDobleToque,
                child: InteractiveViewer(
                  key: widget.claveVisor,
                  transformationController: _transformacion,
                  constrained: false,
                  minScale: minimo / _factor,
                  maxScale: widget.zoomMaximo / _factor,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: _zona.width * _factor / minimo,
                      minHeight: _zona.height * _factor / minimo,
                    ),
                    child: Align(
                      alignment: widget.alineacion,
                      widthFactor: 1,
                      heightFactor: 1,
                      child: widget.constructor(_zona, _factor),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              child: ControlesZoom(
                sobreOscuro: widget.sobreOscuro,
                alAcercar: () => _acercar(1.5),
                alAlejar: () => _acercar(1 / 1.5),
                alAjustar: () => _irAEscala(widget.escalaAjuste(_zona)),
              ),
            ),
            if (widget.pie != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.of(context).padding.bottom + 16,
                child: Center(child: widget.pie),
              ),
          ],
        );
      },
    );
  }
}
