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
  const SintomaPediatrico({required this.nombre, required this.patologias});

  final String nombre;
  final List<String> patologias;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SintomaPediatrico || other.nombre != nombre) return false;
    if (other.patologias.length != patologias.length) return false;
    for (var i = 0; i < patologias.length; i++) {
      if (other.patologias[i] != patologias[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(nombre, Object.hashAll(patologias));
}

const List<SintomaPediatrico> catalogoSintomasPediatricos = [
  SintomaPediatrico(
    nombre: 'Dolor',
    patologias: ['Generales', 'LLA', 'Tumor de Wilms', 'Neuroblastoma'],
  ),
  SintomaPediatrico(
    nombre: 'Dolor de huesos y articulaciones',
    patologias: ['LLA'],
  ),
  SintomaPediatrico(
    nombre: 'Fiebre',
    patologias: ['LLA', 'Tumor de Wilms', 'Linfoma'],
  ),
  SintomaPediatrico(
    nombre: 'Fatiga o cansancio',
    patologias: ['LLA', 'Generales'],
  ),
  SintomaPediatrico(nombre: 'Debilidad', patologias: ['LLA', 'Linfoma']),
  SintomaPediatrico(nombre: 'Sangrado', patologias: ['LLA']),
  SintomaPediatrico(nombre: 'Pérdida de peso', patologias: ['LLA', 'Linfoma']),
  SintomaPediatrico(
    nombre: 'Falta de apetito (anorexia)',
    patologias: ['Tumor de Wilms', 'Generales'],
  ),
  SintomaPediatrico(nombre: 'Náuseas', patologias: ['Tumor de Wilms']),
  SintomaPediatrico(nombre: 'Vómitos', patologias: ['Tumores SNC']),
  SintomaPediatrico(
    nombre: 'Diarrea',
    patologias: ['Neuroblastoma', 'Generales'],
  ),
  SintomaPediatrico(nombre: 'Mareos', patologias: ['Tumores SNC']),
  SintomaPediatrico(
    nombre: 'Problemas de equilibrio',
    patologias: ['Tumores SNC'],
  ),
  SintomaPediatrico(
    nombre: 'Problemas de visión, audición o habla',
    patologias: ['Tumores SNC'],
  ),
  SintomaPediatrico(
    nombre: 'Dolor de cabeza (cefalea)',
    patologias: ['Tumores SNC'],
  ),
  SintomaPediatrico(nombre: 'Mucositis', patologias: ['Generales']),
  SintomaPediatrico(nombre: 'Caída de cabello', patologias: ['Generales']),
  SintomaPediatrico(nombre: 'Sudoración nocturna', patologias: ['Linfoma']),
  SintomaPediatrico(
    nombre: 'Ganglios linfáticos inflamados',
    patologias: ['Linfoma'],
  ),
  SintomaPediatrico(
    nombre: 'Dificultad para caminar',
    patologias: ['Neuroblastoma'],
  ),
  SintomaPediatrico(
    nombre: 'Cambios en los ojos (abultados, ojeras, párpados caídos)',
    patologias: ['Neuroblastoma'],
  ),
  SintomaPediatrico(
    nombre: 'Hinchazón o bulto en el vientre',
    patologias: ['Tumor de Wilms'],
  ),
  SintomaPediatrico(
    nombre: 'Presión sanguínea elevada',
    patologias: ['Neuroblastoma'],
  ),
];

class SintomaSeleccionable {
  const SintomaSeleccionable({
    required this.nombre,
    this.etiqueta0 = '',
    this.etiqueta10 = '',
    this.esOtro = false,
    this.patologias = const [],
  });

  final String nombre;
  final String etiqueta0;
  final String etiqueta10;
  final bool esOtro;
  final List<String> patologias;

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
        patologias: item.patologias,
      ),
];

const List<String> patologiasFiltro = [
  'Todos',
  'Generales',
  'Escala',
  'LLA',
  'Tumores SNC',
  'Neuroblastoma',
  'Tumor de Wilms',
  'Linfoma',
];
