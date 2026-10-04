import 'package:flutter/material.dart';

class FundidoRamas extends StatelessWidget {
  const FundidoRamas({
    super.key,
    required this.indiceActivo,
    required this.ramas,
  });

  final int indiceActivo;
  final List<Widget> ramas;

  static const duracion = Duration(milliseconds: 240);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (final (i, rama) in ramas.indexed)
          TweenAnimationBuilder<double>(
            tween: Tween<double>(end: i == indiceActivo ? 1 : 0),
            duration: duracion,
            curve: Curves.easeOutCubic,
            builder: (_, opacidad, hijo) => Offstage(
              offstage: opacidad == 0,
              child: IgnorePointer(
                ignoring: i != indiceActivo,
                child: TickerMode(
                  enabled: i == indiceActivo,
                  child: Opacity(opacity: opacidad, child: hijo),
                ),
              ),
            ),
            child: rama,
          ),
      ],
    );
  }
}
