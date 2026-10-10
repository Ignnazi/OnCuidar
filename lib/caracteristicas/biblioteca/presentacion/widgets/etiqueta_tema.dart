import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/color_tema.dart';

AcentoTema acentoDelTema(String tema) =>
    Paleta.acentoTema(indiceColorTema(tema));

class PuntoTema extends StatelessWidget {
  const PuntoTema({super.key, required this.tema, this.tamano = 10});

  final String tema;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        color: acentoDelTema(tema).acento,
        shape: BoxShape.circle,
      ),
    );
  }
}

class EtiquetaTema extends StatelessWidget {
  const EtiquetaTema({super.key, required this.tema, this.tamanoTexto = 12});

  final String tema;
  final double tamanoTexto;

  @override
  Widget build(BuildContext context) {
    final color = acentoDelTema(tema);
    return Container(
      key: const Key('etiquetaTema'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.fondo,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.acento.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PuntoTema(tema: tema, tamano: 7),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              tema,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: tamanoTexto,
                fontWeight: FontWeight.w700,
                color: color.texto,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
