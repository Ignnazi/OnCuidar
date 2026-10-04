import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';

class TituloSeccionRegistro extends StatelessWidget {
  const TituloSeccionRegistro(
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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Paleta.doradoMedio, Paleta.doradoRelleno],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icono, size: 15, color: Paleta.sobreDorado),
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
