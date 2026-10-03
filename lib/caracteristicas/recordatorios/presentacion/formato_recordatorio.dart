import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';

const todosLosDias = ['lun', 'mar', 'mie', 'jue', 'vie', 'sab', 'dom'];

/// Ícono y color de cada tipo de recordatorio.
({IconData icono, Color color}) estiloTipoRecordatorio(String tipo) {
  return switch (tipo) {
    'medicamento' => (
      icono: Icons.medication_rounded,
      color: const Color(0xFFF07830),
    ),
    'medicion' => (
      icono: Icons.monitor_heart_outlined,
      color: const Color(0xFF10B981),
    ),
    'cita' => (
      icono: Icons.event_available_rounded,
      color: const Color(0xFF4EC4D4),
    ),
    _ => (icono: Icons.lightbulb_rounded, color: const Color(0xFF8B5CF6)),
  };
}

String diaCorto(String dia) => switch (dia) {
  'lun' => 'Lun',
  'mar' => 'Mar',
  'mie' => 'Mié',
  'jue' => 'Jue',
  'vie' => 'Vie',
  'sab' => 'Sáb',
  'dom' => 'Dom',
  _ => dia,
};

class EtiquetaSeccionRecordatorio extends StatelessWidget {
  const EtiquetaSeccionRecordatorio(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Paleta.textoTerciario,
        letterSpacing: 0.3,
      ),
    );
  }
}
