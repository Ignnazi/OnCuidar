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
