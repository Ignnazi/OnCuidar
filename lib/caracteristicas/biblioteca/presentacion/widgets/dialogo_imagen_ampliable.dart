import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/widgets/imagen_cacheada.dart';

class DialogoImagenAmpliable extends StatelessWidget {
  const DialogoImagenAmpliable({super.key, required this.url, this.titulo});

  final String url;
  final String? titulo;

  @override
  Widget build(BuildContext context) {
    final titulo = this.titulo;
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
          if (titulo != null)
            Positioned(
              top: 8,
              left: 8,
              right: 48,
              child: Text(
                titulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
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
