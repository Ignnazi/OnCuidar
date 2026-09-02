import 'package:flutter/material.dart';

class Marca extends StatelessWidget {
  const Marca({super.key, this.tamano = 160});

  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo2.png',
      width: tamano,
      height: tamano,
    );
  }
}

class LogoCircular extends StatelessWidget {
  const LogoCircular({
    super.key,
    this.tamano = 220,
    this.fondo = Colors.white,
  });

  final double tamano;
  final Color fondo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        color: fondo,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: EdgeInsets.all(tamano * 0.12),
      child: Image.asset(
        'assets/images/logo2.png',
        fit: BoxFit.contain,
      ),
    );
  }
}