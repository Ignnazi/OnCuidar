import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/tema/paleta.dart';
import '../../modelos/registro_clinico.dart';

class ChipSintoma extends StatelessWidget {
  const ChipSintoma({
    super.key,
    required this.sintoma,
    this.onTap,
    this.onQuitar,
  });

  final EntradaSintoma sintoma;
  final VoidCallback? onTap;
  final VoidCallback? onQuitar;

  @override
  Widget build(BuildContext context) {
    final color = EntradaSintoma.colorPara(sintoma.intensity);
    final etiqueta = EntradaSintoma.etiquetaPara(sintoma.intensity);
    return Container(
      padding: const EdgeInsets.only(left: 4, right: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.only(left: 6, top: 4, bottom: 4),
              child: Text(
                '${sintoma.name} · $etiqueta (${sintoma.intensity}/10)',
                style: GoogleFonts.nunito(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ),
          if (onQuitar != null)
            InkWell(
              onTap: onQuitar,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  size: 15,
                  color: Paleta.textoSecundario,
                ),
              ),
            ),
        ],
      ),
    );
  }
}