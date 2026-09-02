import 'package:flutter/material.dart';

class Paleta {
  static const doradoPrincipal = Color(0xFFD99A16);
  static const doradoMedio = Color(0xFFE8A820);
  static const doradoClaro = Color(0xFFFFF0C2);
  static const doradoOscuro = Color(0xFFC08808);
  static const crema = Color(0xFFFFFBF5);

  static const degradadoCabecera = LinearGradient(
    begin: Alignment(-0.6, -0.8),
    end: Alignment(1.0, 1.0),
    colors: [
      doradoOscuro,
      doradoMedio,
      Color(0xFFF5C842),
    ],
  );

  static const textoPrincipal = Color(0xFF2C1A00);
  static const textoSecundario = Color(0xFF9A8060);
  static const textoTerciario = Color(0xFF8A5A05);
  static const textoAyuda = Color(0xFFB8954A);
  static const tarjeta = Color(0xFFFFFFFF);
  static const fondoEntrada = Color(0xFFFFF8F0);
  static const bordeTarjeta = Color(0x33E8A820);
  static const exito = Color(0xFF10B981);
  static const error = Color(0xFFEF4444);
}