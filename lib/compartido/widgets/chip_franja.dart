import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';

class ChipFranja extends StatelessWidget {
  const ChipFranja(this.icono, this.texto, {super.key});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: Paleta.alfa(claro: 0.18, oscuro: 0.35),
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14.5, color: Paleta.sobreDorado),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: Paleta.sobreDorado,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
