import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/tema/paleta.dart';
import '../../../modelos/material_educativo.dart';
import '../categorias.dart';
import 'imagen_cacheada.dart';

class TarjetaMaterial extends StatelessWidget {
  const TarjetaMaterial({
    super.key,
    required this.material,
    required this.esFavorito,
    required this.descargado,
    required this.alTocar,
    required this.alAlternarFavorito,
  });

  final MaterialEducativo material;
  final bool esFavorito;
  final bool descargado;
  final VoidCallback alTocar;
  final VoidCallback alAlternarFavorito;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Paleta.tarjeta,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Paleta.bordeTarjeta),
        boxShadow: [
          BoxShadow(
            color: Paleta.doradoOscuro.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            key: const Key('miniaturaTarjetaMaterial'),
            onTap: alTocar,
            behavior: HitTestBehavior.opaque,
            child: _miniatura(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _textos()),
                const SizedBox(width: 4),
                _iconoFavorito(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniatura() {
    final thumbnail = material.thumbnailUrl;
    return SizedBox(
      height: 108,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (thumbnail != null && thumbnail.isNotEmpty)
            ImagenCacheada(
              url: thumbnail,
              ajuste: BoxFit.cover,
              reemplazo: _reemplazoMiniatura(),
            )
          else
            _reemplazoMiniatura(),
          if (material.esVideo)
            Center(
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.7),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          Positioned(
            top: 8,
            left: 8,
            child: _insignia(),
          ),
          if (descargado && material.fileUrl != null)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Paleta.doradoOscuro,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _reemplazoMiniatura() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Paleta.doradoClaro, Paleta.doradoMedio],
        ),
      ),
      child: Center(
        child: Icon(
          _iconoCategoria(),
          size: 34,
          color: Paleta.doradoOscuro.withValues(alpha: 0.55),
        ),
      ),
    );
  }

  Widget _insignia() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Paleta.doradoPrincipal,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        etiquetaCategoria(material.category),
        style: GoogleFonts.nunito(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _textos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          material.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Paleta.textoPrincipal,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          material.topic.isNotEmpty ? material.topic : material.category,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.nunito(
            fontSize: 13,
            color: Paleta.textoSecundario,
          ),
        ),
      ],
    );
  }

  Widget _iconoFavorito() {
    return GestureDetector(
      onTap: alAlternarFavorito,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        child: Icon(
          esFavorito ? Icons.bookmark : Icons.bookmark_border,
          color: esFavorito ? Paleta.doradoPrincipal : Paleta.textoSecundario,
          size: 30,
        ),
      ),
    );
  }

  IconData _iconoCategoria() {
    switch (material.category.toLowerCase()) {
      case 'videos':
        return Icons.ondemand_video_rounded;
      case 'guías':
      case 'pdfs':
        return Icons.menu_book_rounded;
      case 'infografías':
        return Icons.image_rounded;
      case 'checklist':
        return Icons.checklist_rounded;
      default:
        return Icons.article_rounded;
    }
  }
}