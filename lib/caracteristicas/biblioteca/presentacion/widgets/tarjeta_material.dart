import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/categorias.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/material_educativo.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/pantalla_visor_imagen.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/widgets/etiqueta_tema.dart';
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
      container: true,
      label: etiquetaCategoria(categoria),
      excludeSemantics: true,
      child: Container(
        key: const Key('iconoTipoMaterial'),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: estilo.color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(estilo.icono, size: 17, color: estilo.color),
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
    final radio = BorderRadius.circular(16);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Paleta.tarjeta,
        borderRadius: radio,
        border: Border.all(color: Paleta.bordeTarjeta),
        boxShadow: [
          BoxShadow(
            color: Paleta.doradoOscuro.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('abrirTarjetaMaterial'),
          onTap: alTocar,
          borderRadius: radio,
          excludeFromSemantics: true,
          child: material.esVideo ? _tarjetaVideo() : _tarjetaConPortada(),
        ),
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

  Widget _tarjetaVideo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 2.2,
          child: Stack(
            key: const Key('miniaturaTarjetaMaterial'),
            fit: StackFit.expand,
            children: [
              _imagen(BoxFit.cover, Alignment.center),
              Center(child: _botonReproducir()),
            ],
          ),
        ),
        _franjaTitulo(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 6, 4),
          child: Row(
            children: [..._tipoYTema(expandir: true), _iconoFavorito()],
          ),
        ),
      ],
    );
  }

  Widget _tarjetaConPortada() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _franjaTitulo(),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _portada(),
              const SizedBox(width: 14),
              Expanded(
                child: SizedBox(
                  height: 108,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: _tipoYTema()),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: _iconoFavorito(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _franjaTitulo() {
    return Container(
      color: Paleta.doradoBannerOscuro.withValues(alpha: 0.55),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Text(
        material.titulo,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.nunito(
          fontSize: 15.5,
          fontWeight: FontWeight.w800,
          color: Paleta.textoTerciario,
          height: 1.25,
        ),
      ),
    );
  }

  List<Widget> _tipoYTema({bool expandir = false}) {
    return [
      IconoTipoMaterial(categoria: material.categoria),
      if (material.tema.isNotEmpty) ...[
        const SizedBox(width: 8),
        if (expandir)
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: EtiquetaTema(tema: material.tema),
            ),
          )
        else
          Flexible(child: EtiquetaTema(tema: material.tema)),
      ],
    ];
  }

  Widget _portada() {
    final estilo = estiloTipoMaterial(material.categoria);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        key: const Key('miniaturaTarjetaMaterial'),
        width: 82,
        height: 108,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: estilo.color.withValues(alpha: 0.08)),
            _imagen(BoxFit.cover, Alignment.topCenter),
          ],
        ),
      ),
    );
  }

  Widget _imagen(BoxFit ajuste, Alignment alineacion) {
    final url = _urlImagen;
    if (url == null) return _reemplazoMiniatura();
    final imagen = ImagenCacheada(
      url: url,
      ajuste: ajuste,
      alineacion: alineacion,
      reemplazo: _reemplazoMiniatura(),
    );
    if (material.esVideo) return imagen;
    return Hero(tag: etiquetaHeroImagen(material.id), child: imagen);
  }

  Widget _botonReproducir() {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: Paleta.doradoPrincipal,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.85),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(
        Icons.play_arrow_rounded,
        color: Colors.white,
        size: 36,
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

  Widget _iconoFavorito() {
    return IconButton(
      key: const Key('alternarFavoritoMaterial'),
      tooltip: esFavorito ? 'Quitar de favoritos' : 'Guardar en favoritos',
      onPressed: alAlternarFavorito,
      icon: Icon(
        esFavorito ? Icons.bookmark : Icons.bookmark_border,
        color: esFavorito ? Paleta.doradoPrincipal : Paleta.textoSecundario,
        size: 32,
      ),
    );
  }
}
