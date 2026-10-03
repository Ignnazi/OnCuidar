import 'package:flutter/material.dart';

enum NivelAlerta { normal, alerta, critico }

class SignosVitales {
  const SignosVitales({
    this.temperatura,
    this.frecuenciaCardiaca,
    this.saturacionOxigeno,
    this.frecuenciaRespiratoria,
  });

  final double? temperatura;
  final int? frecuenciaCardiaca;
  final int? saturacionOxigeno;
  final int? frecuenciaRespiratoria;
}

class EntradaSintoma {
  const EntradaSintoma({
    required this.nombre,
    required this.intensidad,
    this.notas,
  });

  final String nombre;
  final int intensidad;
  final String? notas;

  static Color colorPara(int intensidad) {
    switch (intensidad) {
      case 0:
        return const Color(0xFF6BA368);
      case 1:
      case 2:
      case 3:
        return const Color(0xFF8BC34A);
      case 4:
      case 5:
      case 6:
        return const Color(0xFFEF8A17);
      case 7:
      case 8:
      case 9:
        return const Color(0xFFD9534F);
      case 10:
        return const Color(0xFFB71C1C);
      default:
        return const Color(0xFF9A8060);
    }
  }

  static IconData iconoPara(int intensidad) {
    switch (intensidad) {
      case 0:
        return Icons.sentiment_very_satisfied;
      case 1:
      case 2:
      case 3:
        return Icons.sentiment_satisfied;
      case 4:
      case 5:
      case 6:
        return Icons.sentiment_dissatisfied;
      default:
        return Icons.sentiment_very_dissatisfied;
    }
  }

  static String etiquetaPara(int intensidad) {
    switch (intensidad) {
      case 0:
        return 'Sin síntoma';
      case 1:
      case 2:
      case 3:
        return 'Leve';
      case 4:
      case 5:
      case 6:
        return 'Moderado';
      case 7:
      case 8:
      case 9:
        return 'Severo';
      case 10:
        return 'Insoportable';
      default:
        return '';
    }
  }
}

class RegistroClinico {
  const RegistroClinico({
    required this.id,
    required this.pacienteId,
    required this.fecha,
    required this.creadoEn,
    required this.tipoRegistro,
    this.signosVitales,
    this.sintomas = const [],
    this.observaciones,
    this.nivelAlerta = NivelAlerta.normal,
    this.mensajeAlerta,
  });

  final String id;
  final String pacienteId;

  final DateTime fecha;

  final DateTime creadoEn;

  final String tipoRegistro;
  final SignosVitales? signosVitales;
  final List<EntradaSintoma> sintomas;
  final String? observaciones;
  final NivelAlerta nivelAlerta;

  final String? mensajeAlerta;
}
