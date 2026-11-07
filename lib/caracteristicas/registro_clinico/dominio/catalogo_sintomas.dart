library;

class EsasSintoma {
  const EsasSintoma({
    required this.nombre,
    required this.etiqueta0,
    required this.etiqueta10,
    this.esOtro = false,
  });

  final String nombre;
  final String etiqueta0;
  final String etiqueta10;
  final bool esOtro;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EsasSintoma &&
          other.nombre == nombre &&
          other.etiqueta0 == etiqueta0 &&
          other.etiqueta10 == etiqueta10 &&
          other.esOtro == esOtro;

  @override
  int get hashCode => Object.hash(nombre, etiqueta0, etiqueta10, esOtro);
}

const List<EsasSintoma> catalogoEsasR = [
  EsasSintoma(
    nombre: 'Dolor',
    etiqueta0: 'Nada de dolor',
    etiqueta10: 'El peor dolor posible',
  ),
  EsasSintoma(
    nombre: 'Cansancio',
    etiqueta0: 'Sin cansancio',
    etiqueta10: 'Muy agotado',
  ),
  EsasSintoma(
    nombre: 'Somnolencia',
    etiqueta0: 'Sin somnolencia',
    etiqueta10: 'Muy somnoliento',
  ),
  EsasSintoma(
    nombre: 'Náuseas',
    etiqueta0: 'Sin náuseas',
    etiqueta10: 'Muchas náuseas',
  ),
  EsasSintoma(
    nombre: 'Apetito',
    etiqueta0: 'Con apetito',
    etiqueta10: 'Sin apetito',
  ),
  EsasSintoma(
    nombre: 'Respiración',
    etiqueta0: 'Respira bien',
    etiqueta10: 'Mucha dificultad para respirar',
  ),
  EsasSintoma(
    nombre: 'Depresión',
    etiqueta0: 'Nada desanimado',
    etiqueta10: 'Muy desanimado',
  ),
  EsasSintoma(
    nombre: 'Ansiedad',
    etiqueta0: 'Sin ansiedad',
    etiqueta10: 'Muy ansioso',
  ),
  EsasSintoma(
    nombre: 'Sueño',
    etiqueta0: 'Duerme bien',
    etiqueta10: 'No puede dormir',
  ),
  EsasSintoma(
    nombre: 'Bienestar',
    etiqueta0: 'Muy bien',
    etiqueta10: 'Muy mal',
  ),
  EsasSintoma(
    nombre: 'Otro problema',
    etiqueta0: 'Nada',
    etiqueta10: 'Lo peor posible',
    esOtro: true,
  ),
];

class SintomaPediatrico {
  const SintomaPediatrico({required this.nombre, required this.grupo});

  final String nombre;
  final String grupo;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SintomaPediatrico &&
          other.nombre == nombre &&
          other.grupo == grupo;

  @override
  int get hashCode => Object.hash(nombre, grupo);
}

const List<String> gruposSintomas = [
  'Síntomas generales y sistémicos',
  'Cabeza, piel y mucosas',
  'Sistema digestivo y nutrición',
  'Dolor y sistema músculo esquelético',
  'Sistema nervioso y neurosensorial',
  'Vasculares y renales',
];

const List<SintomaPediatrico> catalogoSintomasPediatricos = [
  SintomaPediatrico(nombre: 'Fatiga', grupo: 'Síntomas generales y sistémicos'),
  SintomaPediatrico(
    nombre: 'Sudoración',
    grupo: 'Síntomas generales y sistémicos',
  ),
  SintomaPediatrico(
    nombre: 'Somnolencia',
    grupo: 'Síntomas generales y sistémicos',
  ),
  SintomaPediatrico(
    nombre: 'Pérdida de peso',
    grupo: 'Síntomas generales y sistémicos',
  ),
  SintomaPediatrico(
    nombre:
        'Edema (retención de líquidos en piernas, brazos, cara u otras zonas)',
    grupo: 'Síntomas generales y sistémicos',
  ),
  SintomaPediatrico(
    nombre: 'Alopecia (pérdida de cabello)',
    grupo: 'Cabeza, piel y mucosas',
  ),
  SintomaPediatrico(
    nombre:
        'Eritema (enrojecimiento o inflamación de la zona donde se administra la terapia)',
    grupo: 'Cabeza, piel y mucosas',
  ),
  SintomaPediatrico(
    nombre: 'Xerosis (sequedad de la piel)',
    grupo: 'Cabeza, piel y mucosas',
  ),
  SintomaPediatrico(
    nombre: 'Xerostomía (boca seca)',
    grupo: 'Cabeza, piel y mucosas',
  ),
  SintomaPediatrico(
    nombre:
        'Mucositis (inflamación dolorosa de las mucosas del tracto digestivo)',
    grupo: 'Cabeza, piel y mucosas',
  ),
  SintomaPediatrico(
    nombre: 'Epistaxis (sangrado nasal)',
    grupo: 'Cabeza, piel y mucosas',
  ),
  SintomaPediatrico(
    nombre: 'Disfagia (dificultad para tragar)',
    grupo: 'Cabeza, piel y mucosas',
  ),
  SintomaPediatrico(
    nombre: 'Anorexia (falta de apetito)',
    grupo: 'Sistema digestivo y nutrición',
  ),
  SintomaPediatrico(
    nombre: 'Vómitos/náuseas',
    grupo: 'Sistema digestivo y nutrición',
  ),
  SintomaPediatrico(nombre: 'Diarrea', grupo: 'Sistema digestivo y nutrición'),
  SintomaPediatrico(
    nombre: 'Estreñimiento',
    grupo: 'Sistema digestivo y nutrición',
  ),
  SintomaPediatrico(
    nombre: 'Dolor general',
    grupo: 'Dolor y sistema músculo esquelético',
  ),
  SintomaPediatrico(
    nombre: 'Cefalea (dolor de cabeza)',
    grupo: 'Dolor y sistema músculo esquelético',
  ),
  SintomaPediatrico(
    nombre: 'Mialgia (dolor muscular)',
    grupo: 'Dolor y sistema músculo esquelético',
  ),
  SintomaPediatrico(
    nombre: 'Artralgia (dolor de las articulaciones)',
    grupo: 'Dolor y sistema músculo esquelético',
  ),
  SintomaPediatrico(
    nombre: 'Ostealgia (dolor óseo)',
    grupo: 'Dolor y sistema músculo esquelético',
  ),
  SintomaPediatrico(
    nombre: 'Mareo',
    grupo: 'Sistema nervioso y neurosensorial',
  ),
  SintomaPediatrico(
    nombre:
        'Neuropatía periférica (hormigueo, entumecimiento o sensación de quemazón en manos y pies)',
    grupo: 'Sistema nervioso y neurosensorial',
  ),
  SintomaPediatrico(
    nombre: 'Insomnio',
    grupo: 'Sistema nervioso y neurosensorial',
  ),
  SintomaPediatrico(
    nombre: 'Dificultad para concentrarse',
    grupo: 'Sistema nervioso y neurosensorial',
  ),
  SintomaPediatrico(
    nombre: 'Disnea (falta de aire)',
    grupo: 'Sistema nervioso y neurosensorial',
  ),
  SintomaPediatrico(
    nombre: 'Hematomas (moretones inusuales)',
    grupo: 'Vasculares y renales',
  ),
  SintomaPediatrico(
    nombre: 'Disuria (dolor al orinar)',
    grupo: 'Vasculares y renales',
  ),
];

List<String> sintomasDelGrupo(String grupo) => [
  for (final item in catalogoSintomasPediatricos)
    if (item.grupo == grupo) item.nombre,
];

class SintomaSeleccionable {
  const SintomaSeleccionable({
    required this.nombre,
    this.etiqueta0 = '',
    this.etiqueta10 = '',
    this.esOtro = false,
    this.grupo,
  });

  final String nombre;
  final String etiqueta0;
  final String etiqueta10;
  final bool esOtro;
  final String? grupo;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SintomaSeleccionable && other.nombre == nombre;

  @override
  int get hashCode => nombre.hashCode;
}

final Set<String> _nombresEsas = {
  for (final item in catalogoEsasR) item.nombre,
};

final List<SintomaSeleccionable> catalogoUnificado = [
  for (final item in catalogoEsasR)
    SintomaSeleccionable(
      nombre: item.nombre,
      etiqueta0: item.etiqueta0,
      etiqueta10: item.etiqueta10,
      esOtro: item.esOtro,
    ),
  for (final item in catalogoSintomasPediatricos)
    if (!_nombresEsas.contains(item.nombre))
      SintomaSeleccionable(
        nombre: item.nombre,
        etiqueta10: '',
        grupo: item.grupo,
      ),
];

const List<String> filtrosSintomas = ['Todos', 'Escala', ...gruposSintomas];
