import '../../modelos/registro_clinico.dart';

class EvaluacionAlerta {
  const EvaluacionAlerta({required this.nivel, required this.mensajes});

  final NivelAlerta nivel;
  final List<String> mensajes;
}

class MotorReglasClinicas {
  MotorReglasClinicas._();

  static EvaluacionAlerta evaluar(
    SignosVitales? signos,
    List<EntradaSintoma> sintomas,
  ) {
    var nivel = NivelAlerta.normal;
    final mensajes = <String>[];

    final temperatura = signos?.temperature;
    if (temperatura != null) {
      if (temperatura > 39.5) {
        nivel = NivelAlerta.critico;
        mensajes.add('Fiebre alta (${_numero(temperatura)}°C)');
      } else if (temperatura > 38.5 && nivel != NivelAlerta.critico) {
        nivel = NivelAlerta.alerta;
        mensajes.add('Fiebre moderada (${_numero(temperatura)}°C)');
      } else if (temperatura < 35) {
        nivel = NivelAlerta.critico;
        mensajes.add('Hipotermia (${_numero(temperatura)}°C)');
      } else if (temperatura < 36.5 && nivel != NivelAlerta.critico) {
        nivel = NivelAlerta.alerta;
        mensajes.add('Temperatura baja (${_numero(temperatura)}°C)');
      }
    }

    final fc = signos?.heartRate;
    if (fc != null) {
      if (fc > 130) {
        nivel = NivelAlerta.critico;
        mensajes.add('Taquicardia ($fc lpm)');
      } else if (fc > 100 && nivel != NivelAlerta.critico) {
        nivel = NivelAlerta.alerta;
        mensajes.add('Frecuencia cardíaca alta ($fc lpm)');
      } else if (fc < 40) {
        nivel = NivelAlerta.critico;
        mensajes.add('Bradicardia ($fc lpm)');
      } else if (fc < 50 && nivel != NivelAlerta.critico) {
        nivel = NivelAlerta.alerta;
        mensajes.add('Frecuencia cardíaca baja ($fc lpm)');
      }
    }

    final o2 = signos?.oxygenSaturation;
    if (o2 != null) {
      if (o2 < 90) {
        nivel = NivelAlerta.critico;
        mensajes.add('Saturación de O₂ muy baja ($o2%)');
      } else if (o2 < 92 && nivel != NivelAlerta.critico) {
        nivel = NivelAlerta.alerta;
        mensajes.add('Saturación de O₂ baja ($o2%)');
      }
    }

    final fr = signos?.respiratoryRate;
    if (fr != null) {
      if (fr > 28) {
        nivel = NivelAlerta.critico;
        mensajes.add('Taquipnea ($fr rpm)');
      } else if (fr > 20 && nivel != NivelAlerta.critico) {
        nivel = NivelAlerta.alerta;
        mensajes.add('Frecuencia respiratoria alta ($fr rpm)');
      } else if (fr < 8) {
        nivel = NivelAlerta.critico;
        mensajes.add('Bradipnea ($fr rpm)');
      } else if (fr < 12 && nivel != NivelAlerta.critico) {
        nivel = NivelAlerta.alerta;
        mensajes.add('Frecuencia respiratoria baja ($fr rpm)');
      }
    }

    final activos = sintomas.where((s) => s.intensity >= 1).toList();
    final insoportables = activos.where((s) => s.intensity >= 9).length;
    final intensos = activos
        .where((s) => s.intensity >= 7 && s.intensity <= 8)
        .length;
    final moderados = activos
        .where((s) => s.intensity >= 4 && s.intensity <= 6)
        .length;
    final leves = activos
        .where((s) => s.intensity >= 1 && s.intensity <= 3)
        .length;
    final total = activos.length;

    if (insoportables >= 1) {
      nivel = NivelAlerta.critico;
      mensajes.add(
        insoportables == 1
            ? '1 síntoma insoportable'
            : '$insoportables síntomas insoportables',
      );
    } else if (intensos >= 2) {
      nivel = NivelAlerta.critico;
      mensajes.add('$intensos síntomas intensos');
    } else if (intensos == 1) {
      if (nivel != NivelAlerta.critico) {
        nivel = NivelAlerta.alerta;
        mensajes.add('1 síntoma intenso');
      }
    } else if (moderados >= 3) {
      if (nivel != NivelAlerta.critico) {
        nivel = NivelAlerta.alerta;
        mensajes.add('$moderados síntomas moderados');
      }
    } else if (total > 0 && nivel == NivelAlerta.normal) {
      if (leves == total) {
        mensajes.add(
          total == 1
              ? '1 síntoma leve registrado'
              : '$total síntomas leves registrados',
        );
      } else {
        mensajes.add(
          total == 1
              ? '1 síntoma moderado registrado'
              : '$total síntomas moderados registrados',
        );
      }
    }

    if (mensajes.isEmpty) {
      mensajes.add('Sin síntomas preocupantes');
    }

    return EvaluacionAlerta(
      nivel: nivel,
      mensajes: List.unmodifiable(mensajes),
    );
  }

  static String _numero(double valor) => valor.toStringAsFixed(1);
}
