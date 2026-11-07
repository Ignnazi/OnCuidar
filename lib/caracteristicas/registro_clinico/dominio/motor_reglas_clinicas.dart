import 'package:oncuidar/caracteristicas/registro_clinico/dominio/rangos_signos_vitales.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';

class EvaluacionAlerta {
  const EvaluacionAlerta({required this.nivel, required this.mensajes});

  final NivelAlerta nivel;
  final List<String> mensajes;
}

/// Reglas de aviso según el material de enfermería. Lo que ese material no
/// define (saturación y urgencia por frecuencia respiratoria) sigue la tabla
/// NICE NG143 y la guía de oxigenoterapia infantil de la OMS.
class MotorReglasClinicas {
  MotorReglasClinicas._();

  static const recomendacionesModerado = [
    'Revisa si el equipo médico indicó alguna medicación de rescate para '
        'este síntoma.',
    'Vuelve a registrar el síntoma entre 1 y 3 horas.',
    'Si el síntoma no cede o se acompaña de otros malestares, llévalo al '
        'centro médico que haya sido notificado por el servicio de oncología '
        'pediátrica.',
  ];

  static const indicacionSeveridadAlta =
      'Este nivel de malestar requiere evaluación médica. Acude a urgencias '
      'de manera inmediata.';

  static EvaluacionAlerta evaluar(
    SignosVitales? signos,
    List<EntradaSintoma> sintomas, {
    int? edad,
  }) {
    var nivel = NivelAlerta.normal;
    final mensajes = <String>[];

    void avisar(NivelAlerta nuevo, String mensaje) {
      if (nuevo.index > nivel.index) nivel = nuevo;
      mensajes.add(mensaje);
    }

    final temperatura = signos?.temperatura;
    if (temperatura != null) {
      final t = _numero(temperatura);
      if (temperatura >= 38) {
        avisar(
          NivelAlerta.critico,
          'Febril ($t°C): la fiebre siempre es una urgencia',
        );
      } else if (temperatura >= 37.5) {
        avisar(NivelAlerta.alerta, 'Subfebril ($t°C)');
      } else if (temperatura < 35) {
        avisar(NivelAlerta.critico, 'Hipotermia ($t°C)');
      } else if (temperatura < 35.5 && edad != null && edad < 2) {
        avisar(NivelAlerta.critico, 'Hipotermia en menor de 2 años ($t°C)');
      } else if (temperatura < 36) {
        avisar(NivelAlerta.alerta, 'Hipotermia leve ($t°C)');
      }
    }

    final grupo = edad == null ? null : GrupoEdad.desdeEdad(edad);

    final fc = signos?.frecuenciaCardiaca;
    if (fc != null && grupo != null) {
      final rango = grupo.frecuenciaCardiaca;
      if (!rango.contiene(fc)) {
        final sentido = fc > rango.maximo ? 'alta' : 'baja';
        avisar(
          NivelAlerta.alerta,
          'Frecuencia cardíaca $sentido para su edad ($fc lpm, normal $rango)',
        );
      }
    }

    final fr = signos?.frecuenciaRespiratoria;
    if (fr != null) {
      if (fr > 60) {
        avisar(NivelAlerta.critico, 'Respiración muy rápida ($fr rpm)');
      } else if (grupo != null && !grupo.frecuenciaRespiratoria.contiene(fr)) {
        final rango = grupo.frecuenciaRespiratoria;
        final sentido = fr > rango.maximo ? 'alta' : 'baja';
        avisar(
          NivelAlerta.alerta,
          'Frecuencia respiratoria $sentido para su edad '
          '($fr rpm, normal $rango)',
        );
      }
    }

    final o2 = signos?.saturacionOxigeno;
    if (o2 != null) {
      if (o2 < 90) {
        avisar(NivelAlerta.critico, 'Saturación de O₂ muy baja ($o2%)');
      } else if (o2 <= 95) {
        avisar(NivelAlerta.alerta, 'Saturación de O₂ baja ($o2%)');
      }
    }

    final activos = sintomas.where((s) => s.intensidad >= 1).toList();
    final severos = activos.where((s) => s.intensidad >= 7).toList();
    final moderados = activos
        .where((s) => s.intensidad >= 4 && s.intensidad <= 6)
        .toList();

    for (final s in severos) {
      final grado = s.intensidad == 10 ? 'insoportable' : 'severo';
      avisar(
        NivelAlerta.critico,
        'Alerta de Severidad alta: el síntoma ${s.nombre} se ha marcado con '
        'intensidad ${s.intensidad}/10 ($grado).',
      );
    }
    if (severos.isNotEmpty) mensajes.add(indicacionSeveridadAlta);

    for (final s in moderados) {
      avisar(
        NivelAlerta.alerta,
        'Atención: Síntoma moderado registrado. Has registrado ${s.nombre} '
        'con una intensidad de ${s.intensidad}/10.',
      );
    }
    if (moderados.isNotEmpty && severos.isEmpty) {
      mensajes.addAll(recomendacionesModerado);
    }

    if (mensajes.isEmpty && activos.isNotEmpty) {
      mensajes.add(
        activos.length == 1
            ? '1 síntoma leve registrado'
            : '${activos.length} síntomas leves registrados',
      );
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
