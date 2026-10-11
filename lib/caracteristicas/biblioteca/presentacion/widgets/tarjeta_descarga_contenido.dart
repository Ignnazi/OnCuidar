import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/estado_descarga_contenido.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/proveedores_biblioteca.dart';

class TextosDescargaContenido {
  const TextosDescargaContenido._();

  static String descargando(int porcentaje) =>
      'Descargando contenido educativo… $porcentaje %';
  static const noDesconectar = 'No cierres la app ni te desconectes.';
  static const pausada =
      'Descarga en pausa: sin conexión. Seguirá cuando vuelvas a conectarte.';
  static const conErrores = 'Algunos archivos se descargarán más tarde.';
  static const lista = '¡Listo! Contenido guardado en tu teléfono.';
}

class AvisoDescargaContenido extends ConsumerWidget {
  const AvisoDescargaContenido({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(sincronizacionBibliotecaProvider);
    return TarjetaDescargaContenido(
      fase: estado.fase,
      porcentaje: estado.porcentaje,
    );
  }
}

class TarjetaDescargaContenido extends StatelessWidget {
  const TarjetaDescargaContenido({
    super.key,
    required this.fase,
    required this.porcentaje,
  });

  final FaseDescarga fase;
  final int porcentaje;

  bool get _visible => fase != FaseDescarga.ninguna;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      alignment: Alignment.bottomCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (hijo, animacion) =>
            FadeTransition(opacity: animacion, child: hijo),
        child: _visible
            ? _Contenido(
                key: const Key('tarjeta_descarga_contenido'),
                fase: fase,
                porcentaje: porcentaje,
              )
            : const SizedBox.shrink(key: Key('sin_tarjeta_descarga')),
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({super.key, required this.fase, required this.porcentaje});

  final FaseDescarga fase;
  final int porcentaje;

  bool get _conBarra =>
      fase == FaseDescarga.descargando || fase == FaseDescarga.pausada;

  String get _titulo => switch (fase) {
    FaseDescarga.lista => TextosDescargaContenido.lista,
    FaseDescarga.conErrores => TextosDescargaContenido.conErrores,
    _ => TextosDescargaContenido.descargando(porcentaje),
  };

  String? get _detalle => switch (fase) {
    FaseDescarga.descargando => TextosDescargaContenido.noDesconectar,
    FaseDescarga.pausada => TextosDescargaContenido.pausada,
    _ => null,
  };

  IconData get _icono => switch (fase) {
    FaseDescarga.lista => Icons.check_circle_rounded,
    FaseDescarga.pausada => Icons.pause_circle_outline_rounded,
    FaseDescarga.conErrores => Icons.info_outline_rounded,
    _ => Icons.cloud_download_outlined,
  };

  Color get _colorIcono => fase == FaseDescarga.lista
      ? Paleta.verdeExito
      : (fase == FaseDescarga.descargando
            ? Paleta.doradoOscuro
            : Paleta.textoSecundario);

  String get _etiqueta {
    final detalle = _detalle;
    final base =
        fase == FaseDescarga.descargando || fase == FaseDescarga.pausada
        ? 'Descargando contenido educativo, ${porcentajeAnunciable(porcentaje)} por ciento'
        : _titulo;
    return detalle == null ? base : '$base. $detalle';
  }

  @override
  Widget build(BuildContext context) {
    final detalle = _detalle;
    return Semantics(
      liveRegion: true,
      container: true,
      label: _etiqueta,
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Paleta.tarjeta,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Paleta.bordeTarjeta),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(_icono, size: 22, color: _colorIcono),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _titulo,
                      style: GoogleFonts.nunito(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        color: Paleta.textoPrincipal,
                      ),
                    ),
                    if (_conBarra) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: porcentaje / 100,
                          minHeight: 4,
                          backgroundColor: Paleta.bordeTarjeta,
                          color: Paleta.doradoMedio,
                        ),
                      ),
                    ],
                    if (detalle != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        detalle,
                        style: GoogleFonts.nunito(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          color: Paleta.textoSecundario,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
