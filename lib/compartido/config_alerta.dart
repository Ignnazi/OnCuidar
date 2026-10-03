import 'package:flutter/material.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';

class ConfigAlerta {
  const ConfigAlerta({
    required this.label,
    required this.color,
    required this.fondo,
    required this.icono,
    required this.titulo,
    required this.subtitulo,
  });

  final String label;
  final Color color;
  final Color fondo;
  final IconData icono;
  final String titulo;
  final String subtitulo;
}

ConfigAlerta configAlerta(NivelAlerta nivel) {
  switch (nivel) {
    case NivelAlerta.critico:
      return const ConfigAlerta(
        label: 'Crítico',
        color: Color(0xFFEF4444),
        fondo: Color(0xFFFEF2F2),
        icono: Icons.error_outline,
        titulo: 'Se recomienda atención urgente',
        subtitulo: 'Contacta al equipo de salud inmediatamente',
      );
    case NivelAlerta.alerta:
      return const ConfigAlerta(
        label: 'Alerta',
        color: Color(0xFFF59E0B),
        fondo: Color(0xFFFFFBEB),
        icono: Icons.warning_amber_rounded,
        titulo: 'Se recomienda consultar',
        subtitulo: 'Contacta al equipo de salud',
      );
    case NivelAlerta.normal:
      return const ConfigAlerta(
        label: 'Normal',
        color: Color(0xFF10B981),
        fondo: Color(0xFFECFDF5),
        icono: Icons.check_circle_outline,
        titulo: 'Todo parece normal',
        subtitulo: 'Continúa con la vigilancia habitual',
      );
  }
}
