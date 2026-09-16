import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/servicios/motor_reglas_clinicas.dart';
import '../../../core/tema/config_alerta.dart';
import '../../../core/tema/paleta.dart';

class IndicadorAlerta extends StatelessWidget {
  const IndicadorAlerta({super.key, required this.alerta});

  final EvaluacionAlerta alerta;

  @override
  Widget build(BuildContext context) {
    final config = configAlerta(alerta.nivel);
    final mensajes = alerta.mensajes
        .where((m) => m != 'Sin síntomas preocupantes')
        .toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: config.fondo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: config.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: config.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(config.icono, size: 20, color: config.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.titulo,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: config.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  config.subtitulo,
                  style: GoogleFonts.nunito(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Paleta.textoSecundario,
                  ),
                ),
                if (mensajes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final mensaje in mensajes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '• $mensaje',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Paleta.textoPrincipal,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}