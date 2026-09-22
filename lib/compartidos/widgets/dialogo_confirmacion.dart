import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/tema/paleta.dart';

Future<bool?> mostrarDialogoConfirmacion(
  BuildContext context, {
  Key? key,
  required IconData icono,
  required String titulo,
  required String mensaje,
  required String textoConfirmar,
  Color colorConfirmar = Paleta.doradoOscuro,
  IconData? iconoConfirmar,
  Key? keyConfirmar,
  String textoCancelar = 'Cancelar',
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogCtx) => Dialog(
      key: key,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Paleta.tarjeta,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorConfirmar,
                      Color.lerp(colorConfirmar, Colors.black, 0.18)!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: colorConfirmar.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icono, color: Colors.white, size: 28),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Paleta.textoPrincipal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 13.5,
                height: 1.45,
                color: Paleta.textoSecundario,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Paleta.textoSecundario,
                      side: const BorderSide(color: Paleta.bordeTarjeta),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(textoCancelar),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: iconoConfirmar == null
                      ? ElevatedButton(
                          key: keyConfirmar,
                          onPressed: () => Navigator.of(dialogCtx).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorConfirmar,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: Text(textoConfirmar),
                        )
                      : ElevatedButton.icon(
                          onPressed: () => Navigator.of(dialogCtx).pop(true),
                          icon: Icon(iconoConfirmar, size: 18),
                          label: Text(textoConfirmar),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorConfirmar,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
