import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/tema/paleta.dart';

class FilaDato extends StatelessWidget {
  const FilaDato({
    super.key,
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Paleta.doradoPrincipal, Paleta.doradoOscuro],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icono, size: 17, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                etiqueta,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Paleta.textoTerciario,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                valor,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Paleta.textoPrincipal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
