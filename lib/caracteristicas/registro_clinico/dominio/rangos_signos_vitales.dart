/// Afebril según enfermería.
const rangoNormalTemperatura = '36-37,4';

/// Desde 95 % la tabla NICE NG143 ya pide atención.
const rangoNormalSaturacion = '96-100';

/// Rangos normales entregados por enfermería, por grupo de edad.
/// La frecuencia cardíaca usa los valores del niño despierto.
class RangoVital {
  const RangoVital(this.minimo, this.maximo);

  final int minimo;
  final int maximo;

  bool contiene(int valor) => valor >= minimo && valor <= maximo;

  @override
  String toString() => '$minimo-$maximo';
}

enum GrupoEdad {
  lactante(
    frecuenciaCardiaca: RangoVital(100, 180),
    frecuenciaRespiratoria: RangoVital(30, 53),
  ),
  unoADosAnios(
    frecuenciaCardiaca: RangoVital(98, 140),
    frecuenciaRespiratoria: RangoVital(22, 37),
  ),
  preescolar(
    frecuenciaCardiaca: RangoVital(80, 120),
    frecuenciaRespiratoria: RangoVital(20, 28),
  ),
  escolar(
    frecuenciaCardiaca: RangoVital(75, 118),
    frecuenciaRespiratoria: RangoVital(18, 25),
  ),
  adolescente(
    frecuenciaCardiaca: RangoVital(60, 100),
    frecuenciaRespiratoria: RangoVital(12, 20),
  );

  const GrupoEdad({
    required this.frecuenciaCardiaca,
    required this.frecuenciaRespiratoria,
  });

  final RangoVital frecuenciaCardiaca;
  final RangoVital frecuenciaRespiratoria;

  /// Bandas de edad de la tabla PALS de la que provienen los rangos.
  static GrupoEdad desdeEdad(int anios) {
    if (anios < 1) return lactante;
    if (anios <= 2) return unoADosAnios;
    if (anios <= 5) return preescolar;
    if (anios <= 12) return escolar;
    return adolescente;
  }
}
