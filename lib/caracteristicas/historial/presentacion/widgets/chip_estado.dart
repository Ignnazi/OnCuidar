import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';

class ChipEstado extends StatelessWidget {
  const ChipEstado({
    super.key,
    required this.etiqueta,
    required this.activo,
    required this.onTap,
  });

  final String etiqueta;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: activo ? const Color(0xFFE8A820) : Paleta.doradoClaro,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          etiqueta,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: activo ? Paleta.sobreDorado : Paleta.textoTerciario,
          ),
        ),
      ),
    );
  }
}
