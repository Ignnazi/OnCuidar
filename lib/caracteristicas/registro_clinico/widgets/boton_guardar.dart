import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/tema/paleta.dart';

class BotonGuardar extends StatelessWidget {
  const BotonGuardar({
    super.key,
    required this.guardando,
    required this.esEdicion,
    required this.onPressed,
  });

  final bool guardando;
  final bool esEdicion;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Paleta.doradoMedio, Paleta.doradoOscuro],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: guardando ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (guardando)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  const Icon(Icons.save, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  guardando
                      ? 'Guardando…'
                      : (esEdicion
                            ? 'Actualizar registro'
                            : 'Guardar registro'),
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
