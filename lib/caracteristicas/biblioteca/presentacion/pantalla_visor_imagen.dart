import 'package:flutter/material.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/widgets/imagen_cacheada.dart';
import 'package:oncuidar/compartido/widgets/marco_visor.dart';
import 'package:oncuidar/compartido/widgets/visor_con_zoom.dart';

String etiquetaHeroImagen(String idMaterial) => 'imagen-material-$idMaterial';

Future<void> abrirVisorImagen(
  BuildContext context, {
  required String url,
  required String titulo,
  String? idMaterial,
}) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, _, _) =>
          PantallaVisorImagen(url: url, titulo: titulo, idMaterial: idMaterial),
      transitionsBuilder: (_, animacion, _, hijo) =>
          FadeTransition(opacity: animacion, child: hijo),
    ),
  );
}

class PantallaVisorImagen extends StatelessWidget {
  const PantallaVisorImagen({
    super.key,
    required this.url,
    required this.titulo,
    this.idMaterial,
  });

  final String url;
  final String titulo;

  /// Material al que pertenece.
  final String? idMaterial;

  @override
  Widget build(BuildContext context) {
    return MarcoVisor(
      fondo: const Color(0xFF0B0B0D),
      titulo: titulo,
      claveVolver: const Key('cerrarVisorImagen'),
      cuerpo: VisorConZoom(
        claveVisor: const Key('zoomVisorImagen'),
        constructor: (zona, factor) => SizedBox(
          key: const Key('areaVisorImagen'),
          width: zona.width * factor,
          height: zona.height * factor,
          child: ImagenCacheada(
            url: url,
            ajuste: BoxFit.contain,
            reemplazo: const _ImagenIndisponible(),
          ),
        ),
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
