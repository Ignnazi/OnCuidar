import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/motor_reglas_clinicas.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/rangos_signos_vitales.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';

EntradaSintoma _sintoma(String nombre, int intensidad) =>
    EntradaSintoma(nombre: nombre, intensidad: intensidad);

EvaluacionAlerta _signos(SignosVitales signos, {int? edad}) =>
    MotorReglasClinicas.evaluar(signos, const [], edad: edad);

void main() {
  group('temperatura', () {
    test('38 °C o más es febril y urgente', () {
      final resultado = _signos(const SignosVitales(temperatura: 38));
      expect(resultado.nivel, NivelAlerta.critico);
      expect(
        resultado.mensajes,
        contains('Febril (38.0°C): la fiebre siempre es una urgencia'),
      );
    });

    test('entre 37,5 y 37,9 °C es subfebril y da alerta', () {
      final resultado = _signos(const SignosVitales(temperatura: 37.6));
      expect(resultado.nivel, NivelAlerta.alerta);
      expect(resultado.mensajes, contains('Subfebril (37.6°C)'));
    });

    test('entre 36 y 37,4 °C es afebril', () {
      for (final t in [36.0, 36.8, 37.4]) {
        final resultado = _signos(SignosVitales(temperatura: t));
        expect(resultado.nivel, NivelAlerta.normal, reason: '$t');
        expect(resultado.mensajes, ['Sin síntomas preocupantes']);
      }
    });

    test('entre 35 y 35,9 °C es hipotermia leve y da alerta', () {
      final resultado = _signos(const SignosVitales(temperatura: 35.6));
      expect(resultado.nivel, NivelAlerta.alerta);
      expect(resultado.mensajes, contains('Hipotermia leve (35.6°C)'));
    });

    test('bajo 35 °C es hipotermia y urgente', () {
      final resultado = _signos(const SignosVitales(temperatura: 34.8));
      expect(resultado.nivel, NivelAlerta.critico);
      expect(resultado.mensajes, contains('Hipotermia (34.8°C)'));
    });

    test('en menores de 2 años bajo 35,5 °C es urgente', () {
      final resultado = _signos(
        const SignosVitales(temperatura: 35.3),
        edad: 1,
      );
      expect(resultado.nivel, NivelAlerta.critico);
      expect(
        resultado.mensajes,
        contains('Hipotermia en menor de 2 años (35.3°C)'),
      );
    });

    test('desde los 2 años 35,3 °C sigue siendo hipotermia leve', () {
      final resultado = _signos(
        const SignosVitales(temperatura: 35.3),
        edad: 2,
      );
      expect(resultado.nivel, NivelAlerta.alerta);
    });
  });

  group('frecuencia cardíaca según la edad', () {
    test('dentro del rango de su edad no avisa', () {
      final lactante = _signos(
        const SignosVitales(frecuenciaCardiaca: 150),
        edad: 0,
      );
      expect(lactante.nivel, NivelAlerta.normal);
    });

    test('sobre el rango de su edad da alerta con el rango normal', () {
      final resultado = _signos(
        const SignosVitales(frecuenciaCardiaca: 125),
        edad: 4,
      );
      expect(resultado.nivel, NivelAlerta.alerta);
      expect(
        resultado.mensajes,
        contains(
          'Frecuencia cardíaca alta para su edad (125 lpm, normal 80-120)',
        ),
      );
    });

    test('bajo el rango de su edad da alerta', () {
      final resultado = _signos(
        const SignosVitales(frecuenciaCardiaca: 55),
        edad: 15,
      );
      expect(resultado.nivel, NivelAlerta.alerta);
      expect(
        resultado.mensajes,
        contains(
          'Frecuencia cardíaca baja para su edad (55 lpm, normal 60-100)',
        ),
      );
    });

    test('sin edad registrada no se evalúa', () {
      final resultado = _signos(const SignosVitales(frecuenciaCardiaca: 190));
      expect(resultado.nivel, NivelAlerta.normal);
    });
  });

  group('frecuencia respiratoria según la edad', () {
    test('sobre el rango de su edad da alerta', () {
      final resultado = _signos(
        const SignosVitales(frecuenciaRespiratoria: 30),
        edad: 8,
      );
      expect(resultado.nivel, NivelAlerta.alerta);
      expect(
        resultado.mensajes,
        contains(
          'Frecuencia respiratoria alta para su edad (30 rpm, normal 18-25)',
        ),
      );
    });

    test('sobre 60 respiraciones por minuto es urgente', () {
      final resultado = _signos(
        const SignosVitales(frecuenciaRespiratoria: 62),
        edad: 0,
      );
      expect(resultado.nivel, NivelAlerta.critico);
      expect(resultado.mensajes, contains('Respiración muy rápida (62 rpm)'));
    });

    test('dentro del rango de su edad no avisa', () {
      final resultado = _signos(
        const SignosVitales(frecuenciaRespiratoria: 40),
        edad: 0,
      );
      expect(resultado.nivel, NivelAlerta.normal);
    });
  });

  group('saturación de oxígeno', () {
    test('96 % o más es normal', () {
      expect(
        _signos(const SignosVitales(saturacionOxigeno: 96)).nivel,
        NivelAlerta.normal,
      );
    });

    test('95 % o menos da alerta', () {
      final resultado = _signos(const SignosVitales(saturacionOxigeno: 95));
      expect(resultado.nivel, NivelAlerta.alerta);
      expect(resultado.mensajes, contains('Saturación de O₂ baja (95%)'));
    });

    test('bajo 90 % es urgente', () {
      final resultado = _signos(const SignosVitales(saturacionOxigeno: 89));
      expect(resultado.nivel, NivelAlerta.critico);
      expect(resultado.mensajes, contains('Saturación de O₂ muy baja (89%)'));
    });
  });

  group('síntomas', () {
    test('leves no dan aviso', () {
      final resultado = MotorReglasClinicas.evaluar(null, [
        _sintoma('Fatiga', 2),
        _sintoma('Mareo', 3),
      ]);
      expect(resultado.nivel, NivelAlerta.normal);
      expect(resultado.mensajes, ['2 síntomas leves registrados']);
    });

    test('intensidad 0 no cuenta', () {
      final resultado = MotorReglasClinicas.evaluar(null, [
        _sintoma('Fatiga', 0),
      ]);
      expect(resultado.mensajes, ['Sin síntomas preocupantes']);
    });

    test('un síntoma moderado avisa con sus recomendaciones', () {
      final resultado = MotorReglasClinicas.evaluar(null, [
        _sintoma('Náuseas', 5),
      ]);
      expect(resultado.nivel, NivelAlerta.alerta);
      expect(resultado.mensajes, [
        'Atención: Síntoma moderado registrado. Has registrado Náuseas con '
            'una intensidad de 5/10.',
        'Revisa si el equipo médico indicó alguna medicación de rescate para '
            'este síntoma.',
        'Vuelve a registrar el síntoma entre 1 y 3 horas.',
        'Si el síntoma no cede o se acompaña de otros malestares, llévalo al '
            'centro médico que haya sido notificado por el servicio de '
            'oncología pediátrica.',
      ]);
    });

    test('las recomendaciones aparecen una sola vez', () {
      final resultado = MotorReglasClinicas.evaluar(null, [
        _sintoma('Náuseas', 4),
        _sintoma('Cefalea', 6),
      ]);
      expect(resultado.mensajes, hasLength(5));
      expect(
        resultado.mensajes.where((m) => m.startsWith('Revisa si')),
        hasLength(1),
      );
    });

    test('severo es urgente', () {
      final resultado = MotorReglasClinicas.evaluar(null, [
        _sintoma('Dolor general', 8),
      ]);
      expect(resultado.nivel, NivelAlerta.critico);
      expect(resultado.mensajes, [
        'Alerta de Severidad alta: el síntoma Dolor general se ha marcado con '
            'intensidad 8/10 (severo).',
        'Este nivel de malestar requiere evaluación médica. Acude a urgencias '
            'de manera inmediata.',
      ]);
    });

    test('10 se marca como insoportable', () {
      final resultado = MotorReglasClinicas.evaluar(null, [
        _sintoma('Disnea', 10),
      ]);
      expect(resultado.nivel, NivelAlerta.critico);
      expect(
        resultado.mensajes.first,
        'Alerta de Severidad alta: el síntoma Disnea se ha marcado con '
        'intensidad 10/10 (insoportable).',
      );
    });

    test('con un síntoma severo no se repiten las recomendaciones de '
        'moderado', () {
      final resultado = MotorReglasClinicas.evaluar(null, [
        _sintoma('Disnea', 9),
        _sintoma('Náuseas', 5),
      ]);
      expect(resultado.nivel, NivelAlerta.critico);
      expect(
        resultado.mensajes.where((m) => m.startsWith('Revisa si')),
        isEmpty,
      );
      expect(
        resultado.mensajes,
        contains(
          'Atención: Síntoma moderado registrado. Has registrado Náuseas con '
          'una intensidad de 5/10.',
        ),
      );
    });
  });

  test('un signo urgente no baja por un síntoma moderado', () {
    final resultado = MotorReglasClinicas.evaluar(
      const SignosVitales(temperatura: 38.5),
      [_sintoma('Náuseas', 5)],
    );
    expect(resultado.nivel, NivelAlerta.critico);
  });

  test('sin datos no hay nada preocupante', () {
    final resultado = MotorReglasClinicas.evaluar(null, const []);
    expect(resultado.nivel, NivelAlerta.normal);
    expect(resultado.mensajes, ['Sin síntomas preocupantes']);
  });

  group('rango normal que se muestra en cada signo', () {
    test('temperatura y saturación no dependen de la edad', () {
      expect(rangoNormalTemperatura, '36-37,4');
      expect(rangoNormalSaturacion, '96-100');
    });

    test('frecuencias según la edad del paciente', () {
      expect(GrupoEdad.desdeEdad(0).frecuenciaCardiaca.toString(), '100-180');
      expect(GrupoEdad.desdeEdad(4).frecuenciaCardiaca.toString(), '80-120');
      expect(GrupoEdad.desdeEdad(8).frecuenciaRespiratoria.toString(), '18-25');
      expect(
        GrupoEdad.desdeEdad(15).frecuenciaRespiratoria.toString(),
        '12-20',
      );
    });
  });
}
