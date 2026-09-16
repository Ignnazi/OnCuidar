import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/tema/paleta.dart';

class TituloSeccion extends StatelessWidget {
  const TituloSeccion(
    this.texto, {
    super.key,
    this.icono = Icons.info_outline,
    this.trailing,
  });

  final String texto;
  final IconData icono;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Paleta.doradoMedio, Paleta.doradoOscuro],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icono, size: 15, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Paleta.textoTerciario,
              letterSpacing: 0.3,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}