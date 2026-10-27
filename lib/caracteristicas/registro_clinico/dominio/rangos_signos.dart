import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';

/// Rango físico plausible de cada signo vital
class RangoFisico {
  const RangoFisico({
    required this.min,
    required this.max,
    required this.mensaje,
  });

  final double min;
  final double max;
  final String mensaje;
}

const rangoTemperatura = RangoFisico(
  min: 30,
  max: 45,
  mensaje: 'Temperatura debe estar entre 30 y 45°C',
);

const rangoFrecuenciaCardiaca = RangoFisico(
  min: 20,
  max: 250,
  mensaje: 'Frecuencia cardíaca debe estar entre 20 y 250 lpm',
);

const rangoSaturacion = RangoFisico(
  min: 50,
  max: 100,
  mensaje: 'Saturación de O₂ debe estar entre 50 y 100%',
);

const rangoFrecuenciaRespiratoria = RangoFisico(
  min: 4,
  max: 60,
  mensaje: 'Frecuencia respiratoria debe estar entre 4 y 60 rpm',
);

/// Mensaje del primer signo fuera de rango o null si todos son válidos
String? errorDeRango(SignosVitales signos) {
  final valores = [
    (signos.temperatura, rangoTemperatura),
    (signos.frecuenciaCardiaca, rangoFrecuenciaCardiaca),
    (signos.saturacionOxigeno, rangoSaturacion),
    (signos.frecuenciaRespiratoria, rangoFrecuenciaRespiratoria),
  ];
  for (final (valor, rango) in valores) {
    if (valor != null && (valor < rango.min || valor > rango.max)) {
      return rango.mensaje;
    }
  }
  return null;
}
