import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/tema/paleta.dart';

class EncabezadoGradiente extends StatelessWidget {
  const EncabezadoGradiente({
    super.key,
    required this.titulo,
    this.alto = 120,
    this.alturaOla = 12,
    this.tamanoTitulo,
    this.mostrarRetroceso = false,
    this.alRetroceder,
    this.subtitulo,
  });

  final String titulo;
  final String? subtitulo;
  final double alto;
  final double alturaOla;
  final double? tamanoTitulo;
  final bool mostrarRetroceso;
  final VoidCallback? alRetroceder;

  @override
  Widget build(BuildContext context) {
    final alturaBarraEstado = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: alturaBarraEstado + alto + (alturaOla * 0.5),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: Paleta.degradadoCabecera,
              ),
              child: Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    48,
                    alturaBarraEstado + 8,
                    48,
                    0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        titulo,
                        textAlign: TextAlign.center,
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
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (mostrarRetroceso)
            Positioned(
              top: alturaBarraEstado + 4,
              left: 4,
              child: IconButton(
                tooltip: 'Volver',
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 22),
                onPressed: alRetroceder ?? () => Navigator.of(context).pop(),
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width, alturaOla),
              painter: PintorOla(color: Paleta.crema),
            ),
          ),
        ],
      ),
    );
  }
}

class PintorOla extends CustomPainter {
  final Color color;

  PintorOla({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final pintura = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Arco suave y bajo para una transicion homogenea.
    final trazo = Path()
      ..moveTo(0, 0)
      ..cubicTo(
        size.width * 0.33,
        size.height,
        size.width * 0.66,
        size.height,
        size.width,
        0,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(trazo, pintura);
  }

  @override
  bool shouldRepaint(covariant PintorOla delegadoAnterior) => false;
}