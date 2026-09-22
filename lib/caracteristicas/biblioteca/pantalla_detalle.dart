import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import '../../compartidos/widgets/encabezado_gradiente.dart';
import '../../core/proveedores/proveedores.dart';
import '../../core/tema/paleta.dart';
import '../../modelos/material_educativo.dart';
import 'categorias.dart';
import 'checklist_interactivo.dart';
import 'parseo_contenido.dart';
import 'widgets/imagen_cacheada.dart';

class PantallaDetalleMaterial extends ConsumerStatefulWidget {
  const PantallaDetalleMaterial({super.key, required this.id});

  final String id;

  @override
  ConsumerState<PantallaDetalleMaterial> createState() =>
      _PantallaDetalleMaterialState();
}

class _PantallaDetalleMaterialState
    extends ConsumerState<PantallaDetalleMaterial> {
  MaterialEducativo? _material;
  bool _descargando = false;

  void _resolverMaterial(MaterialEducativo? material) {
    if (_material?.id != material?.id) {
      _material = material;
    }
  }

  Future<void> _abrirArchivo() async {
    final material = _material;
    if (material == null || material.fileUrl == null) return;
    setState(() => _descargando = true);
    try {
      final cache = ref.read(servicioCacheContenidoProvider);
      final archivo = await cache.descargar(material.fileUrl!);
      ref
          .read(contenidosDescargadosProvider.notifier)
          .marcarDescargado(material.fileUrl!);
      if (!mounted) return;
      final resultado = await OpenFilex.open(archivo.path);
      if (resultado.type != ResultType.done && mounted) {
        _mostrarAviso(
          resultado.message.isNotEmpty
              ? resultado.message
              : 'No hay una aplicación para abrir este tipo de archivo.',
        );
      }
    } catch (e) {
      if (mounted) _mostrarAviso('Error al abrir el archivo: $e');
    } finally {
      if (mounted) setState(() => _descargando = false);
    }
  }

  void _mostrarAviso(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, style: GoogleFonts.nunito(fontSize: 14)),
        backgroundColor: Paleta.error,
      ),
    );
  }

  Future<void> _alternarFavorito(String materialId) async {
    final base = ref.read(servicioBaseDatosProvider);
    final ids = ref.read(idsFavoritosProvider).value ?? const <String>[];
    final eraFavorito = ids.contains(materialId);
    try {
      await base.alternarFavorito(materialId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              eraFavorito ? 'Quitado de favoritos' : 'Añadido a favoritos',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Paleta.doradoPrincipal,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        _mostrarAviso('No se pudo actualizar el favorito. Revisa tu conexión.');
      }
    }
  }

  void _mostrarImagen(final String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => DialogoImagenAmpliable(url: url),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contenidosAsync = ref.watch(contenidosEducativosProvider);
    final contenidos = contenidosAsync.value ?? const <MaterialEducativo>[];
    MaterialEducativo? material;
    for (final contenido in contenidos) {
      if (contenido.id == widget.id) {
        material = contenido;
        break;
      }
    }
    if (material == null) {
      final detalleAsync = ref.watch(contenidoDetalleProvider(widget.id));
      material = detalleAsync.value;
    }
    if (material != null) _resolverMaterial(material);
    final materialActual = material ?? _material;

    final favoritosAsync = ref.watch(idsFavoritosProvider);
    final esFavorito = favoritosAsync.value?.contains(widget.id) ?? false;

    return Scaffold(
      backgroundColor: Paleta.crema,
      body: Column(
        children: [
          EncabezadoGradiente(
            titulo: 'Material educativo',
            subtitulo: materialActual?.topic,
            reservaDerecha: 48,
            accionDerecha: GestureDetector(
              onTap: () => unawaited(_alternarFavorito(widget.id)),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  esFavorito ? Icons.bookmark : Icons.bookmark_border,
                  color: esFavorito ? Paleta.doradoClaro : Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          Expanded(child: _cuerpo(materialActual)),
        ],
      ),
    );
  }

  Widget _cuerpo(MaterialEducativo? material) {
    if (material == null) {
      return const Center(
        child: Text(
          'Material no encontrado.',
          style: TextStyle(color: Paleta.textoSecundario),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (material.imageUrl != null && material.imageUrl!.isNotEmpty) ...[
            GestureDetector(
              onTap: () => _mostrarImagen(material.imageUrl!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _imagenCuerpo(material.imageUrl!),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            material.title,
            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Paleta.textoPrincipal,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Paleta.doradoPrincipal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  etiquetaCategoria(material.category),
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Paleta.doradoOscuro,
                  ),
                ),
              ),
              if (material.topic.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    material.topic,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: Paleta.textoSecundario,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (material.body.isNotEmpty) ...[
            if (material.esChecklist)
              ChecklistInteractivo(
                titulo: material.title,
                items: parsearItemsChecklist(material.body),
                textoIntro: textoInformativoChecklist(material.body),
              )
            else ...[
              const SizedBox(height: 16),
              ..._secciones(material.body),
            ],
          ],
          if (material.fileUrl != null) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _descargando ? null : _abrirArchivo,
                icon: _descargando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.open_in_new, size: 18),
                label: Text(
                  _descargando ? 'Descargando...' : 'Abrir archivo adjunto',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _imagenCuerpo(String url) {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: ImagenCacheada(
        url: url,
        ajuste: BoxFit.cover,
        reemplazo: _reemplazoImagen(),
      ),
    );
  }

  Widget _reemplazoImagen() {
    return Container(
      color: Paleta.fondoEntrada,
      child: const Icon(
        Icons.image_not_supported_outlined,
        size: 48,
        color: Paleta.textoSecundario,
      ),
    );
  }

  List<Widget> _secciones(String body) {
    final bloques = parsearCuerpo(body);
    return [
      for (final bloque in bloques)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: bloque.esTitulo
              ? Text(
                  bloque.texto,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Paleta.doradoOscuro,
                  ),
                )
              : Text(
                  bloque.texto,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    height: 1.6,
                    color: Paleta.textoPrincipal,
                  ),
                ),
        ),
    ];
  }
}

class DialogoImagenAmpliable extends StatelessWidget {
  const DialogoImagenAmpliable({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black87,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          InteractiveViewer(
            maxScale: 5,
            child: AspectRatio(
              aspectRatio: 1,
              child: ImagenCacheada(
                url: url,
                ajuste: BoxFit.contain,
                reemplazo: const _ImagenIndisponible(),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagenIndisponible extends StatelessWidget {
  const _ImagenIndisponible();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.broken_image_outlined, color: Colors.white70, size: 40),
    );
  }
}
