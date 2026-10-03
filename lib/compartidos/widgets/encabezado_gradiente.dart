import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/tema/paleta.dart';

class EncabezadoGradiente extends StatelessWidget {
  const EncabezadoGradiente({
    super.key,
    required this.titulo,
    this.alto = 100,
    this.tamanoTitulo,
    this.mostrarRetroceso = false,
    this.alRetroceder,
    this.subtitulo,
    this.accionDerecha,
    this.logo,
    this.iconoRetroceso = Icons.home_rounded,
    this.reservaDerecha = 0,
    this.tituloCentrado = false,
    this.alTocarLogo,
  });

  final String titulo;
  final String? subtitulo;
  final double alto;

  static const _profundidadOla = 12.0;

  final double? tamanoTitulo;
  final bool mostrarRetroceso;
  final VoidCallback? alRetroceder;

  final Widget? accionDerecha;
  final ImageProvider? logo;
  final IconData iconoRetroceso;
  final double reservaDerecha;
  final bool tituloCentrado;
  final VoidCallback? alTocarLogo;

  @override
  Widget build(BuildContext context) {
    final alturaBarraEstado = MediaQuery.of(context).padding.top;
    final lateral = mostrarRetroceso ? 48.0 : 20.0;

    final derecha = reservaDerecha > 0
        ? (reservaDerecha > lateral ? reservaDerecha : lateral)
        : lateral;

    return SizedBox(
      height: alturaBarraEstado + alto,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: ClipPath(
                clipper: _ClipperOla(profundidad: _profundidadOla),
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: Paleta.degradadoCabecera),
                ),
              ),
            ),
          ),
          Align(
            alignment: tituloCentrado
                ? Alignment.center
                : const Alignment(-1, -0.35),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                lateral,
                alturaBarraEstado + 4,
                derecha,
                4,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: logo != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (alTocarLogo != null)
                            GestureDetector(
                              onTap: alTocarLogo,
                              behavior: HitTestBehavior.opaque,
                              child: _logoRedondo(),
                            )
                          else
                            IgnorePointer(child: _logoRedondo()),
                          const SizedBox(width: 10),
                          IgnorePointer(child: _contenidoTitulo()),
                        ],
                      )
                    : IgnorePointer(child: _contenidoTitulo()),
              ),
            ),
          ),
          if (mostrarRetroceso)
            Positioned(
              top: alturaBarraEstado + 4,
              left: 4,
              child: Tooltip(
                message: 'Volver al inicio',
                child: GestureDetector(
                  onTap: alRetroceder ?? () => Navigator.of(context).pop(),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconoRetroceso, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
          if (accionDerecha != null)
            Positioned(
              top: alturaBarraEstado + 26,
              right: 12,
              child: accionDerecha!,
            ),
        ],
      ),
    );
  }

  Widget _logoRedondo() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Paleta.doradoClaro, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Paleta.doradoOscuro.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Image(image: logo!, width: 28, height: 28, fit: BoxFit.contain),
    );
  }

  Widget _contenidoTitulo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          textAlign: tituloCentrado ? TextAlign.center : TextAlign.left,
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontSize: tamanoTitulo ?? 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            height: 1.15,
            shadows: const [
              Shadow(
                color: Colors.black26,
                offset: Offset(0, 1),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        if (subtitulo != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitulo!,
              textAlign: tituloCentrado ? TextAlign.center : TextAlign.left,
              style: GoogleFonts.nunito(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
      ],
    );
  }
}

class _ClipperOla extends CustomClipper<Path> {
  const _ClipperOla({required this.profundidad});
  final double profundidad;

  @override
  Path getClip(Size size) {
    final bordeOla = size.height - profundidad;
    final ola = Path()
      ..moveTo(0, bordeOla)
      ..cubicTo(
        size.width * 0.33,
        size.height,
        size.width * 0.66,
        size.height,
        size.width,
        bordeOla,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    return Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      ola,
    );
  }

  @override
  bool shouldReclip(covariant _ClipperOla oldClipper) =>
      oldClipper.profundidad != profundidad;
}
