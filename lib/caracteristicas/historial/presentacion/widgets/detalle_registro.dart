import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/motor_reglas_clinicas.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';
import 'package:oncuidar/compartido/config_alerta.dart';

class DetalleRegistro extends StatelessWidget {
  const DetalleRegistro({super.key, required this.registro});

  final RegistroClinico registro;

  @override
  Widget build(BuildContext context) {
    final config = configAlerta(registro.nivelAlerta);
    final observaciones = registro.observaciones;
    final motivos = MotorReglasClinicas.evaluar(
      registro.signosVitales,
      registro.sintomas,
    ).mensajes.where((m) => m != 'Sin síntomas preocupantes').toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Paleta.fondoEntrada,
        border: Border(
          top: BorderSide(
            color: Paleta.doradoPrincipal.withValues(alpha: 0.12),
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final sintoma in registro.sintomas)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ContenedorSintoma(sintoma),
            ),
          if (observaciones != null && observaciones.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Observaciones',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Paleta.doradoOscuro,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    observaciones,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      height: 1.45,
                      color: Paleta.textoPrincipal,
                    ),
                  ),
                ],
              ),
            ),
          if (motivos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: config.fondo,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: config.color.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Por qué este nivel?',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: config.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    for (final motivo in motivos)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '• $motivo',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Paleta.textoPrincipal,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ContenedorSintoma extends StatelessWidget {
  const _ContenedorSintoma(this.sintoma);

  final EntradaSintoma sintoma;

  @override
  Widget build(BuildContext context) {
    final color = EntradaSintoma.colorPara(sintoma.intensidad);
    final etiqueta = EntradaSintoma.etiquetaPara(sintoma.intensidad);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Síntoma',
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${sintoma.nombre} · $etiqueta (${sintoma.intensidad}/10)',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Paleta.textoPrincipal,
            ),
          ),
        ],
      ),
    );
  }
}
