import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/tema/paleta.dart';

class EstadoVacio extends StatelessWidget {
  const EstadoVacio(
    this.icono,
    this.titulo, {
    super.key,
    this.subtitulo,
  });

  final IconData icono;
  final String titulo;
  final String? subtitulo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Icon(icono, size: 56, color: Paleta.doradoMedio),
          const SizedBox(height: 14),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Paleta.textoPrincipal,
            ),
          ),
          if (subtitulo != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitulo!,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: Paleta.textoSecundario,
              ),
            ),
          ],
        ],
      ),
    );
  }
}