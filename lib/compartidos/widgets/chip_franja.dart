import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Chip compacto para franjas doradas: icono + texto sobre fondo blanco
/// translúcido (RUT, Edad, Parentesco).
class ChipFranja extends StatelessWidget {
  const ChipFranja(this.icono, this.texto, {super.key});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            texto,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
