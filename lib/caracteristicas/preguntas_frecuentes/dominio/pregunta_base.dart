class PreguntaBase {
  const PreguntaBase({
    required this.id,
    required this.categoria,
    required this.pregunta,
    required this.respuesta,
    this.claves = const [],
    this.contenidoRelacionadoId,
  });

  final String id;
  final String categoria;
  final String pregunta;
  final String respuesta;

  final List<String> claves;

  final String? contenidoRelacionadoId;
}
