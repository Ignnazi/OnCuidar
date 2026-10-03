import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';

class BotonDegradado extends StatelessWidget {
  const BotonDegradado({
    super.key,
    required this.etiqueta,
    required this.cargando,
    required this.alPulsar,
  });

  final String etiqueta;
  final bool cargando;
  final VoidCallback alPulsar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Opacity(
        opacity: cargando ? 0.6 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Paleta.doradoPrincipal, Paleta.doradoOscuro],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Paleta.doradoPrincipal.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: cargando ? null : alPulsar,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.transparent,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: cargando
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    etiqueta,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class EnlaceAcceso extends StatelessWidget {
  const EnlaceAcceso({
    super.key,
    required this.pregunta,
    required this.accion,
    required this.alPulsar,
  });

  final String pregunta;
  final String accion;
  final VoidCallback alPulsar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: alPulsar,
        child: Text.rich(
          TextSpan(
            text: pregunta,
            style: GoogleFonts.nunito(
              color: Paleta.textoSecundario,
              fontSize: 14,
            ),
            children: [
              TextSpan(
                text: accion,
                style: GoogleFonts.nunito(
                  color: Paleta.doradoOscuro,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
