import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/widgets/tarjeta_material.dart';

class EncabezadoSeccion extends StatelessWidget {
  const EncabezadoSeccion({
    super.key,
    required this.titulo,
    required this.cantidad,
  });

  final String titulo;
  final int cantidad;

  @override
  Widget build(BuildContext context) {
    final estilo = titulo == 'Otros'
        ? (color: Paleta.textoSecundario, icono: Icons.article_rounded)
        : estiloTipoMaterial(titulo);
    return Padding(
      key: Key('seccion_$titulo'),
      padding: const EdgeInsets.fromLTRB(2, 10, 2, 8),
      child: Row(
        children: [
          Icon(estilo.icono, size: 18, color: estilo.color),
          const SizedBox(width: 8),
          Text(
            titulo,
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Paleta.textoPrincipal,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
            decoration: BoxDecoration(
              color: estilo.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$cantidad',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: estilo.color,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: Paleta.bordeTarjeta)),
        ],
      ),
    );
  }
}
