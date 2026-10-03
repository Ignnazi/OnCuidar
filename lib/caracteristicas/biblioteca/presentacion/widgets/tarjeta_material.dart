import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/categorias.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/material_educativo.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/pantalla_visor_imagen.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/widgets/imagen_cacheada.dart';

/// Color e ícono de cada tipo de material.
({Color color, IconData icono}) estiloTipoMaterial(String categoria) {
  switch (categoria.toLowerCase()) {
    case 'videos':
      return (color: Paleta.categoriaVideo, icono: Icons.smart_display_rounded);
    case 'infografías':
      return (
        color: Paleta.categoriaInfografia,
        icono: Icons.insert_chart_outlined_rounded,
      );
    default:
      // Guías y PDFs son lo mismo para el cuidador.
      return (color: Paleta.categoriaGuia, icono: Icons.menu_book_rounded);
  }
}

class IconoTipoMaterial extends StatelessWidget {
  const IconoTipoMaterial({super.key, required this.categoria});

  final String categoria;

  @override
  Widget build(BuildContext context) {
    final estilo = estiloTipoMaterial(categoria);
    return Semantics(
      label: etiquetaCategoria(categoria),
      excludeSemantics: true,
      child: Container(
        key: const Key('iconoTipoMaterial'),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: estilo.color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(estilo.icono, size: 21, color: estilo.color),
      ),
    );
  }
}

class TarjetaMaterial extends StatelessWidget {
  const TarjetaMaterial({
    super.key,
    required this.material,
    required this.esFavorito,
    required this.alTocar,
    required this.alAlternarFavorito,
  });

  final MaterialEducativo material;
  final bool esFavorito;
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
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            child: Row(
              children: [
                IconoTipoMaterial(categoria: material.categoria),
                const SizedBox(width: 10),
                Expanded(child: _textos()),
                _iconoFavorito(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? get _urlImagen {
    final miniatura = material.urlMiniatura;
    if (miniatura != null && miniatura.isNotEmpty) return miniatura;
    final imagen = material.urlImagen;
    if (imagen != null && imagen.isNotEmpty) return imagen;
    return null;
  }

  Widget _miniatura() {
    final url = _urlImagen;
    Widget imagen = url != null
        ? ImagenCacheada(
            url: url,
            ajuste: BoxFit.cover,
            reemplazo: _reemplazoMiniatura(),
          )
        : _reemplazoMiniatura();
    if (url != null && !material.esVideo) {
      imagen = Hero(tag: etiquetaHeroImagen(material.id), child: imagen);
    }
    return SizedBox(
      height: 108,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          imagen,
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
        ],
      ),
    );
  }

  Widget _reemplazoMiniatura() {
    final estilo = estiloTipoMaterial(material.categoria);
    return DecoratedBox(
      key: const Key('reemplazoMiniatura'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            estilo.color.withValues(alpha: 0.10),
            estilo.color.withValues(alpha: 0.24),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          estilo.icono,
          size: 34,
          color: estilo.color.withValues(alpha: 0.55),
        ),
      ),
    );
  }

  Widget _textos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          material.titulo,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Paleta.textoPrincipal,
            height: 1.2,
          ),
        ),
        if (material.tema.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            material.tema,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: Paleta.textoSecundario,
            ),
          ),
        ],
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
}
