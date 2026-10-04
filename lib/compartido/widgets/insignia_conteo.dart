import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';

class InsigniaConteo extends StatelessWidget {
  const InsigniaConteo({super.key, required this.total});

  final int total;

  /// Color del número.
  static const colorNumero = Colors.white;

  /// Cuánto sobresale de la esquina del botón.
  static const sobresale = 8.0;

  static Color colorFondo() {
    final colores = Paleta.degradadoCabecera.colors;
    return Color.lerp(colores[1], colores[2], 0.55)!;
  }

  static Widget enEsquina(int total, {Key? clave}) => Positioned(
    top: -sobresale,
    right: -sobresale,
    child: InsigniaConteo(key: clave, total: total),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: colorFondo(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Paleta.aroInsignia, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        total > 99 ? '99+' : '$total',
        textScaler: TextScaler.noScaling,
        style: GoogleFonts.nunito(
          fontSize: 12,
          height: 1,
          fontWeight: FontWeight.w900,
          color: colorNumero,
          shadows: const [
            Shadow(
              color: Color(0x80000000),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}
