import 'dart:math' as math;

import 'package:flutter/material.dart';

class HojaConAreaSegura extends StatelessWidget {
  const HojaConAreaSegura({
    super.key,
    required this.child,
    this.separacionSuperior = 16,
  });

  final Widget child;
  final double separacionSuperior;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final teclado = media.viewInsets.bottom;
    final altoDisponible = math.max(
      0.0,
      media.size.height - media.viewPadding.top - separacionSuperior - teclado,
    );

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: teclado),
      child: SafeArea(
        top: true,
        bottom: false,
        minimum: EdgeInsets.only(top: separacionSuperior),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: altoDisponible),
          child: child,
        ),
      ),
    );
  }
}
