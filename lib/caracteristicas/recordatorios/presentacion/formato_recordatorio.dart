import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/recordatorios/dominio/recordatorio.dart';
import 'package:oncuidar/nucleo/notificaciones/calendario_avisos.dart';

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

DateTime? proximoAviso(Recordatorio recordatorio, DateTime ahora) {
  final base = recordatorio.fechaHora;
  if (recordatorio.esMensual) {
    var anio = ahora.year;
    var mes = ahora.month;
    for (var i = 0; i < 13; i++) {
      final diasEnMes = DateTime(anio, mes + 1, 0).day;
      final dia = base.day > diasEnMes ? diasEnMes : base.day;
      final candidato = DateTime(anio, mes, dia, base.hour, base.minute);
      if (candidato.isAfter(ahora)) return candidato;
      mes++;
      if (mes > 12) {
        mes = 1;
        anio++;
      }
    }
    return null;
  }
  if (recordatorio.diasRepeticion.isNotEmpty) {
    final objetivos = {
      for (final dia in recordatorio.diasRepeticion)
        if (diasPorSemana[dia] != null) diasPorSemana[dia]!,
    };
    if (objetivos.isEmpty) return null;
    for (var i = 0; i <= 7; i++) {
      final candidato = DateTime(
        ahora.year,
        ahora.month,
        ahora.day + i,
        base.hour,
        base.minute,
      );
      if (objetivos.contains(candidato.weekday) && candidato.isAfter(ahora)) {
        return candidato;
      }
    }
    return null;
  }
  return base.isAfter(ahora) ? base : null;
}

String textoProximoAviso(DateTime proximo, DateTime ahora) {
  final diferencia = proximo.difference(ahora);
  final minutos = diferencia.inMinutes;
  if (minutos < 1) return 'en menos de 1 min';
  final dias = diferencia.inDays;
  final horas = diferencia.inHours.remainder(24);
  final restoMinutos = minutos.remainder(60);
  final textoHoras = horas == 1 ? '1 h' : '$horas h';
  if (dias > 0) {
    return restoMinutos == 0
        ? 'en $dias d y $textoHoras'
        : 'en $dias d, $textoHoras y $restoMinutos min';
  }
  if (horas > 0) {
    return restoMinutos == 0
        ? 'en $textoHoras'
        : 'en $textoHoras y $restoMinutos min';
  }
  return 'en $restoMinutos min';
}

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
