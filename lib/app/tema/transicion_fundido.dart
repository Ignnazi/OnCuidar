import 'package:flutter/material.dart';

class TransicionFundido extends PageTransitionsBuilder {
  const TransicionFundido();

  static const duracion = Duration(milliseconds: 240);

  @override
  Duration get transitionDuration => duracion;

  @override
  Duration get reverseTransitionDuration => duracion;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
      child: child,
    );
  }
}
