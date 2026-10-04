import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/app/tema/transicion_fundido.dart';

class Tema {
  static ThemeData obtener() {
    final brillo = Paleta.esOscura ? Brightness.dark : Brightness.light;
    final esquema = ColorScheme.fromSeed(
      brightness: brillo,
      seedColor: Paleta.doradoPrincipal,
      primary: Paleta.doradoPrincipal,
      secondary: Paleta.doradoMedio,
      surface: Paleta.tarjeta,
      onSurface: Paleta.textoPrincipal,
      error: Paleta.error,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brillo,
      colorScheme: esquema,
      scaffoldBackgroundColor: Paleta.crema,
      dialogTheme: DialogThemeData(backgroundColor: Paleta.tarjeta),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Paleta.tarjeta,
        modalBackgroundColor: Paleta.tarjeta,
      ),
      dividerColor: Paleta.bordeTarjeta,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: TransicionFundido(),
          TargetPlatform.iOS: TransicionFundido(),
          TargetPlatform.macOS: TransicionFundido(),
          TargetPlatform.windows: TransicionFundido(),
          TargetPlatform.linux: TransicionFundido(),
          TargetPlatform.fuchsia: TransicionFundido(),
        },
      ),
      textTheme: GoogleFonts.nunitoTextTheme().apply(
        bodyColor: Paleta.textoPrincipal,
        displayColor: Paleta.textoPrincipal,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Paleta.doradoPrincipal,
        foregroundColor: Paleta.sobreDorado,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Paleta.sobreDorado,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Paleta.doradoPrincipal,
          foregroundColor: Paleta.sobreDorado,
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
