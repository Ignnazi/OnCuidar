import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/tema/paleta.dart';

/// Título de sección dorado con icono (Centro de salud, contactos, correos).
class TituloSeccion extends StatelessWidget {
  const TituloSeccion(this.icono, this.texto, {super.key});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 17, color: Paleta.doradoOscuro),
        const SizedBox(width: 8),
        Text(
          texto,
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Paleta.textoTerciario,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
