import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';

class TarjetaMapa extends StatelessWidget {
  const TarjetaMapa({super.key, required this.direccion, required this.onTap});

  final String direccion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 88,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Paleta.fondoEntrada,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Paleta.bordeTarjeta),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(painter: _MapaPintor()),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      direccion,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Paleta.doradoOscuro,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Paleta.doradoPrincipal,
                              Paleta.doradoOscuro,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Paleta.doradoOscuro.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.touch_app_outlined,
                              size: 17,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Click para ver mapa',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapaPintor extends CustomPainter {
  const _MapaPintor();

  @override
  void paint(Canvas canvas, Size size) {
    final fondo = Paint()..color = const Color(0xFFF7ECDA);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(4)),
      fondo,
    );

    final bloque = Paint()..color = const Color(0xFFFDF6EC);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.28 * 0.35,
          size.height * 0.22,
          size.width * 0.32,
          size.height * 0.28,
        ),
        const Radius.circular(8),
      ),
      bloque,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.62,
          size.height * 0.55,
          size.width * 0.30,
          size.height * 0.30,
        ),
        const Radius.circular(8),
      ),
      bloque,
    );

    final calle = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.12
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.5, 0),
      Offset(size.width * 0.62, size.height),
      calle,
    );
    final calle2 = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.07
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, size.height * 0.48),
      Offset(size.width, size.height * 0.30),
      calle2,
    );

    final via = Paint()
      ..color = const Color(0xFFF3DCA8).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.035
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, size.height * 0.72),
      Offset(size.width * 0.5, size.height),
      via,
    );
  }

  @override
  bool shouldRepaint(covariant _MapaPintor oldDelegate) => false;
}
