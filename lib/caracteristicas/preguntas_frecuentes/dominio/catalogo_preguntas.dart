import 'package:oncuidar/caracteristicas/biblioteca/dominio/material_educativo.dart';
import 'package:oncuidar/caracteristicas/preguntas_frecuentes/dominio/pregunta_base.dart';

const mensajeBienvenidaChat =
    'Hola, soy tu asistente de orientación. Elige una pregunta sugerida o '
    'escríbeme tu duda sobre el cuidado de tu niño.';

const mensajeSinCoincidencia =
    'Aún no tengo una respuesta exacta. Puedes preguntarme sobre fiebre, '
    'catéter o alimentación. Ante cualquier duda, consulta con el equipo '
    'médico de tu niño.';

final List<PreguntaBase> preguntasFrecuentes = [
  const PreguntaBase(
    id: 'fiebre',
    categoria: 'Fiebre',
    pregunta:
        '¿Qué temperatura se considera fiebre y cuándo debo llamar al médico?',
    respuesta:
        'Se considera fiebre desde los 38 °C axilares. En un niño en '
        'tratamiento oncológico, la fiebre siempre es una urgencia: llama de '
        'inmediato a su equipo médico, aunque se vea bien.',
    contenidoRelacionadoId: 'videos-como-medir-la-fiebre',
    claves: [
      'fiebre',
      'temperatura',
      'termómetro',
      '38',
      'llamar',
      'médico',
      'urgencia',
      'avisar',
      'sangrado',
      'petequias',
      'vómitos',
    ],
  ),
  const PreguntaBase(
    id: 'cateter',
    categoria: 'Catéter',
    pregunta: '¿Cómo debo cuidar el catéter y qué hago si se moja o se sale?',
    respuesta:
        'Mantén el apósito seco, bien adherido y sin golpes. Para bañarse, '
        'envuelve la zona con plástico y lava por partes con un paño húmedo; '
        'nada de piscinas, lagos, ríos ni mar. Si se moja, se golpea o se '
        'sale, avisa de inmediato al equipo de salud.',
    claves: [
      'catéter',
      'cvc',
      'hickman',
      'gripper',
      'apósito',
      'vía',
      'moja',
      'bañarse',
      'piscina',
      'lago',
      'río',
      'mar',
      'golpe',
      'sale',
      'infección',
    ],
  ),
  const PreguntaBase(
    id: 'alimentacion',
    categoria: 'Alimentación',
    pregunta: '¿Qué alimentos debo evitar y qué agua es segura?',
    respuesta:
        'Ofrece alimentos bien cocidos y de procedencia confiable. Evita los '
        'crudos, ahumados o sin pasteurizar, y las frutas sin pelar. El agua '
        'debe ser hervida o embotellada.',
    contenidoRelacionadoId: 'pdfs-guia-de-alimentacion-durante-el-tratamiento',
    claves: [
      'aliment',
      'comida',
      'comer',
      'crudo',
      'cocidos',
      'leche',
      'queso',
      'huevo',
      'pescado',
      'agua',
      'hidratación',
      'beber',
      'fruta',
      'verdura',
    ],
  ),
];

MaterialEducativo? materialRelacionado(
  PreguntaBase pregunta,
  List<MaterialEducativo> catalogo,
) {
  final id = pregunta.contenidoRelacionadoId;
  if (id == null || id.isEmpty) return null;
  for (final material in catalogo) {
    if (material.id == id) return material;
  }
  return null;
}

List<String> categoriasDePreguntas() {
  return preguntasFrecuentes.map((p) => p.categoria).toSet().toList();
}

String normalizarTexto(String texto) {
  const reemplazos = {
    'á': 'a',
    'à': 'a',
    'ä': 'a',
    'â': 'a',
    'ã': 'a',
    'é': 'e',
    'è': 'e',
    'ë': 'e',
    'ê': 'e',
    'í': 'i',
    'ì': 'i',
    'ï': 'i',
    'î': 'i',
    'ó': 'o',
    'ò': 'o',
    'ö': 'o',
    'ô': 'o',
    'õ': 'o',
    'ú': 'u',
    'ù': 'u',
    'ü': 'u',
    'û': 'u',
    'ñ': 'n',
  };
  final buffer = StringBuffer();
  for (final caracter in texto.toLowerCase().runes) {
    final letra = String.fromCharCode(caracter);
    buffer.write(reemplazos[letra] ?? letra);
  }
  return buffer.toString().trim();
}
