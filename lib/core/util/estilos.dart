import 'package:flutter/material.dart';
import '../tema/paleta.dart';

const gradienteDorado = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Paleta.doradoMedio, Paleta.doradoOscuro],
);

InputDecoration entradaDorada({
  String? hintText,
  TextStyle? hintStyle,
  String? labelText,
  TextStyle? labelStyle,
  Widget? prefixIcon,
  String? counterText,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: hintStyle,
    labelText: labelText,
    labelStyle: labelStyle,
    prefixIcon: prefixIcon,
    counterText: counterText,
    filled: true,
    fillColor: Paleta.fondoEntrada,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Paleta.bordeTarjeta),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Paleta.bordeTarjeta),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Paleta.doradoPrincipal, width: 1.5),
    ),
  );
}
