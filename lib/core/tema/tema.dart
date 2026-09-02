import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'paleta.dart';

class Tema {
  static ThemeData obtener() {
    final esquema = ColorScheme.fromSeed(
      seedColor: Paleta.doradoPrincipal,
      primary: Paleta.doradoPrincipal,
      secondary: Paleta.doradoMedio,
      surface: Paleta.tarjeta,
      onSurface: Paleta.textoPrincipal,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: Paleta.crema,
      textTheme: GoogleFonts.nunitoTextTheme().apply(
        bodyColor: Paleta.textoPrincipal,
        displayColor: Paleta.textoPrincipal,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Paleta.doradoPrincipal,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Paleta.doradoPrincipal,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Paleta.fondoEntrada,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}