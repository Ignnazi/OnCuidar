import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/core/servicios/motor_reglas_clinicas.dart';
import 'package:oncuidar/modelos/registro_clinico.dart';

EntradaSintoma _sintoma(String nombre, int intensidad) =>
    EntradaSintoma(name: nombre, intensity: intensidad);

void main() {
  group('temperatura', () {
    test('fiebre sobre 39.5°C es crítica', () {
      final resultado = MotorReglasClinicas.evaluar(
        SignosVitales(temperature: 40),
        const [],
      );
      expect(resultado.nivel, NivelAlerta.critico);
      expect(resultado.mensajes, contains('Fiebre alta (40.0°C)'));
    });

    test('fiebre sobre 38.5°C es alerta', () {
      final resultado = MotorReglasClinicas.evaluar(
        SignosVitales(temperature: 39),
        const [],
      );
      expect(resultado.nivel, NivelAlerta.alerta);
      expect(resultado.mensajes, contains('Fiebre moderada (39.0°C)'));
    });

    test('temperatura normal no dispara', () {
      final resultado = MotorReglasClinicas.evaluar(
        SignosVitales(temperature: 37.5),
        const [],
      );
      expect(resultado.nivel, NivelAlerta.normal);
      expect(resultado.mensajes, contains('Sin síntomas preocupantes'));
    });

    test('borde 39.5°C aún no es crítica', () {
      final resultado = MotorReglasClinicas.evaluar(
        SignosVitales(temperature: 39.5),
        const [],
      );
      expect(resultado.nivel, NivelAlerta.alerta);
    });

    test('borde 38.5°C aún no dispara alerta', () {
      final resultado = MotorReglasClinicas.evaluar(
        SignosVitales(temperature: 38.5),
        const [],
      );
      expect(resultado.nivel, NivelAlerta.normal);
    });

    test('temperatura bajo 36.5°C es alerta (hipotermia leve)', () {
      final resultado = MotorReglasClinicas.evaluar(
        SignosVitales(temperature: 36),
        const [],
      );
      expect(resultado.nivel, NivelAlerta.alerta);
      expect(resultado.mensajes, contains('Temperatura baja (36.0°C)'));
    });

    test('temperatura bajo 35°C es crítica (hipotermia)', () {
      final resultado = MotorReglasClinicas.evaluar(
        SignosVitales(temperature: 34.5),
        const [],
      );
      expect(resultado.nivel, NivelAlerta.critico);
      expect(resultado.mensajes, contains('Hipotermia (34.5°C)'));
    });

    test('borde 36.5°C aún es normal', () {
      final resultado = MotorReglasClinicas.evaluar(
        SignosVitales(temperature: 36.5),
        const [],
      );
      expect(resultado.nivel, NivelAlerta.normal);
    });
  });

  group('frecuencia cardíaca', () {
    test('FC sobre 130 lpm es crítica (taquicardia)', () {
      final resultado = MotorReglasClinicas.evaluar(
        SignosVitales(heartRate: 135),
        const [],
      );
      expect(resultado.nivel, NivelAlerta.critico);
      expect(resultado.mensajes, contains('Taquicardia (135 lpm)'));
    });

    test('FC sobre 100 lpm es alerta', () {
      final resultado = MotorReglasClinicas.evaluar(
        SignosVitales(heartRate: 110),
        const [],
      );
      expect(resultado.nivel, NivelAlerta.alerta);
      expect(
        resultado.mensajes,
        contains('Frecuencia cardíaca alta (110 lpm)'),
      );
    });

    test('FC bajo 50 lpm es alerta (bradicardia)', () {
      final resultado = MotorReglasClinicas.evaluar(
        SignosVitales(heartRate: 45),
        const [],
      );
      expect(resultado.nivel, NivelAlerta.alerta);
      expect(resultado.mensajes, contains('Frecuencia cardíaca baja (45 lpm)'));
    });

    test('FC bajo 40 lpm es crítica (bradicardia severa)', () {
      final resultado = MotorReglasClinicas.evaluar(
        SignosVitales(heartRate: 38),
        const [],
      );
      expect(resultado.nivel, NivelAlerta.critico);
      expect(resultado.mensajes, contains('Bradicardia (38 lpm)'));
    });

    test('FC normal no dispara', () {
      final resultado = MotorReglasClinicas.evaluar(
        SignosVitales(heartRate: 72),
        const [],
      );
      expect(resultado.nivel, NivelAlerta.normal);
    });
  });

  group('frecuencia respiratoria', () {
    test('FR sobre 28 rpm es crítica (taquipnea)', () {
      final resultado = MotorReglasClinicas.evaluar(
        SignosVitales(respiratoryRate: 30),
        const [],
      );
      expect(resultado.nivel, NivelAlerta.critico);
      expect(resultado.mensajes, contains('Taquipnea (30 rpm)'));
    });

    test('FR sobre 20 rpm es alerta', () {
      final resultado = MotorReglasClinicas.evaluar(
        SignosVitales(respiratoryRate: 24),
        const [],
      );
      expect(resultado.nivel, NivelAlerta.alerta);
      expect(
        resultado.mensajes,
        contains('Frecuencia respiratoria alta (24 rpm)'),
      );
    });

    test('FR bajo 12 rpm es alerta (bradipnea)', () {
      final resultado = MotorReglasClinicas.evaluar(
        SignosVitales(respiratoryRate: 10),
        const [],
      );
      expect(resultado.nivel, NivelAlerta.alerta);
      expect(
        resultado.mensajes,
        contains('Frecuencia respiratoria baja (10 rpm)'),
      );
    });

    test('FR bajo 8 rpm es crítica (bradipnea severa)', () {
      final resultado = MotorReglasClinicas.evaluar(
        SignosVitales(respiratoryRate: 7),
        const [],
      );
      expect(resultado.nivel, NivelAlerta.critico);
      expect(resultado.mensajes, contains('Bradipnea (7 rpm)'));
    });

    test('FR normal no dispara', () {
      final resultado = MotorReglasClinicas.evaluar(
        SignosVitales(respiratoryRate: 16),
        const [],
      );
      expect(resultado.nivel, NivelAlerta.normal);
    });
  });

  group('saturación de oxígeno', () {
    test('O₂ bajo 90% es crítico', () {
      final resultado = MotorReglasClinicas.evaluar(
        SignosVitales(oxygenSaturation: 88),
        const [],
      );
      expect(resultado.nivel, NivelAlerta.critico);
      expect(resultado.mensajes, contains('Saturación de O₂ muy baja (88%)'));
    });

    test('O₂ bajo 92% es alerta', () {
      final resultado = MotorReglasClinicas.evaluar(
        SignosVitales(oxygenSaturation: 91),
        const [],
      );
      expect(resultado.nivel, NivelAlerta.alerta);
      expect(resultado.mensajes, contains('Saturación de O₂ baja (91%)'));
    });

    test('O₂ 92% no dispara', () {
      final resultado = MotorReglasClinicas.evaluar(
        SignosVitales(oxygenSaturation: 92),
        const [],
      );
      expect(resultado.nivel, NivelAlerta.normal);
    });
  });

  group('síntomas', () {
    test('un síntoma insoportable (10) es crítico', () {
      final resultado = MotorReglasClinicas.evaluar(null, [
        _sintoma('Dolor', 10),
      ]);
      expect(resultado.nivel, NivelAlerta.critico);
      expect(resultado.mensajes, contains('1 síntoma insoportable'));
    });

    test('varios síntomas de 10 cuentan en el mensaje crítico', () {
      final resultado = MotorReglasClinicas.evaluar(null, [
        _sintoma('Dolor', 10),
        _sintoma('Fiebre', 10),
      ]);
      expect(resultado.nivel, NivelAlerta.critico);
      expect(resultado.mensajes, contains('2 síntomas insoportables'));
    });

    test('dos síntomas severos (7-9) son críticos', () {
      final resultado = MotorReglasClinicas.evaluar(null, [
        _sintoma('Dolor', 7),
        _sintoma('Náuseas', 8),
      ]);
      expect(resultado.nivel, NivelAlerta.critico);
      expect(resultado.mensajes, contains('2 síntomas severos'));
    });

    test('un síntoma severo (7-9) es alerta', () {
      final resultado = MotorReglasClinicas.evaluar(null, [
        _sintoma('Dolor', 7),
      ]);
      expect(resultado.nivel, NivelAlerta.alerta);
      expect(resultado.mensajes, contains('1 síntoma severo'));
    });

    test('tres síntomas moderados son alerta', () {
      final resultado = MotorReglasClinicas.evaluar(null, [
        _sintoma('Dolor', 4),
        _sintoma('Náuseas', 5),
        _sintoma('Fatiga', 6),
      ]);
      expect(resultado.nivel, NivelAlerta.alerta);
      expect(resultado.mensajes, contains('3 síntomas moderados'));
    });

    test('un único síntoma moderado no sale de normal', () {
      final resultado = MotorReglasClinicas.evaluar(null, [
        _sintoma('Dolor', 5),
      ]);
      expect(resultado.nivel, NivelAlerta.normal);
      expect(resultado.mensajes, contains('1 síntoma moderado registrado'));
    });

    test('un síntoma leve no sale de normal', () {
      final resultado = MotorReglasClinicas.evaluar(null, [_sintoma('Tos', 2)]);
      expect(resultado.nivel, NivelAlerta.normal);
      expect(resultado.mensajes, contains('1 síntoma leve registrado'));
    });

    test('"Otro problema" cuenta como síntoma como cualquier otro', () {
      final resultado = MotorReglasClinicas.evaluar(null, [
        _sintoma('Otro problema', 7),
      ]);
      expect(resultado.nivel, NivelAlerta.alerta);
      expect(resultado.mensajes, contains('1 síntoma severo'));
    });

    test('sin datos no hay síntomas preocupantes', () {
      final resultado = MotorReglasClinicas.evaluar(null, const []);
      expect(resultado.nivel, NivelAlerta.normal);
      expect(resultado.mensajes, ['Sin síntomas preocupantes']);
    });

    test('un solo síntoma en 0 no dispara nada', () {
      final resultado = MotorReglasClinicas.evaluar(null, [
        _sintoma('Dolor', 0),
      ]);
      expect(resultado.nivel, NivelAlerta.normal);
      expect(resultado.mensajes, ['Sin síntomas preocupantes']);
    });

    test('todos los síntomas en 0 equivalen a "sin datos"', () {
      final resultado = MotorReglasClinicas.evaluar(null, [
        _sintoma('Dolor', 0),
        _sintoma('Náuseas', 0),
      ]);
      expect(resultado.nivel, NivelAlerta.normal);
      expect(resultado.mensajes, ['Sin síntomas preocupantes']);
    });

    test('una mezcla de 0 y leves solo cuenta los leves', () {
      final resultado = MotorReglasClinicas.evaluar(null, [
        _sintoma('Dolor', 0),
        _sintoma('Tos', 2),
        _sintoma('Fiebre', 0),
      ]);
      expect(resultado.nivel, NivelAlerta.normal);
      expect(
        resultado.mensajes,
        contains('1 síntoma leve registrado'),
        reason: 'los ítems en 0 no suman al total de leves',
      );
    });

    test('una mezcla de leve y moderado sin alerta informa moderados', () {
      final resultado = MotorReglasClinicas.evaluar(null, [
        _sintoma('Tos', 2),
        _sintoma('Dolor', 5),
      ]);
      expect(resultado.nivel, NivelAlerta.normal);
      expect(resultado.mensajes, contains('2 síntomas moderados registrados'));
    });

    test(
      'un síntoma insoportable con varios severos manda el mensaje insoportable',
      () {
        final resultado = MotorReglasClinicas.evaluar(null, [
          _sintoma('Dolor', 10),
          _sintoma('Náuseas', 8),
          _sintoma('Fiebre', 7),
        ]);
        expect(resultado.nivel, NivelAlerta.critico);
        expect(resultado.mensajes, contains('1 síntoma insoportable'));
        expect(
          resultado.mensajes.join(' '),
          isNot(contains('intensos')),
          reason: 'el mensaje insoportable gana sobre el de severos',
        );
      },
    );

    test('dos severos y un moderado son críticos', () {
      final resultado = MotorReglasClinicas.evaluar(null, [
        _sintoma('Dolor', 8),
        _sintoma('Náuseas', 7),
        _sintoma('Fiebre', 5),
      ]);
      expect(resultado.nivel, NivelAlerta.critico);
      expect(resultado.mensajes, contains('2 síntomas severos'));
    });

    test('un único moderado habla en singular y plural', () {
      final unSoloModerado = MotorReglasClinicas.evaluar(null, [
        _sintoma('Dolor', 4),
      ]);
      expect(unSoloModerado.nivel, NivelAlerta.normal);
      expect(
        unSoloModerado.mensajes,
        contains('1 síntoma moderado registrado'),
      );

      final dosModerados = MotorReglasClinicas.evaluar(null, [
        _sintoma('Dolor', 4),
        _sintoma('Náuseas', 5),
      ]);
      expect(dosModerados.nivel, NivelAlerta.normal);
      expect(
        dosModerados.mensajes,
        contains('2 síntomas moderados registrados'),
      );
    });
  });

  group('monotonicidad', () {
    test('crítico por fiebre no baja aunque solo haya síntomas leves', () {
      final resultado = MotorReglasClinicas.evaluar(
        SignosVitales(temperature: 40),
        [_sintoma('Tos', 2)],
      );
      expect(resultado.nivel, NivelAlerta.critico);
      expect(resultado.mensajes, contains('Fiebre alta (40.0°C)'));
    });

    test('crítico por O₂ no baja con síntomas severos después', () {
      final resultado = MotorReglasClinicas.evaluar(
        SignosVitales(oxygenSaturation: 88),
        [_sintoma('Dolor', 6), _sintoma('Náuseas', 7), _sintoma('Fiebre', 8)],
      );
      expect(resultado.nivel, NivelAlerta.critico);
    });

    test('los mensajes anteriores se conservan al subir', () {
      final resultado = MotorReglasClinicas.evaluar(
        SignosVitales(temperature: 39, oxygenSaturation: 88),
        const [],
      );
      expect(resultado.nivel, NivelAlerta.critico);
      expect(resultado.mensajes, contains('Fiebre moderada (39.0°C)'));
      expect(resultado.mensajes, contains('Saturación de O₂ muy baja (88%)'));
    });
  });
}
