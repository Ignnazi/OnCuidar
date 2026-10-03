import 'package:oncuidar/caracteristicas/preguntas_frecuentes/dominio/catalogo_preguntas.dart';
import 'package:oncuidar/caracteristicas/preguntas_frecuentes/dominio/pregunta_base.dart';

PreguntaBase? resolverPregunta(String texto, List<PreguntaBase> preguntas) {
  final entrada = normalizarTexto(texto);
  if (entrada.isEmpty) {
    return null;
  }
  final tokens = entrada
      .split(RegExp(r'[^a-z0-9]+'))
      .where((t) => t.length > 2)
      .toList();
  PreguntaBase? mejor;
  var mejorPuntaje = 0;
  for (final pregunta in preguntas) {
    final cuerpo = normalizarTexto(
      '${pregunta.pregunta} ${pregunta.claves.join(' ')}',
    );
    var puntaje = 0;
    if (cuerpo.contains(entrada)) {
      puntaje += 6;
    }
    for (final token in tokens) {
      if (cuerpo.contains(token)) {
        puntaje += token.length >= 6 ? 2 : 1;
      }
    }
    for (final clave in pregunta.claves) {
      final claveNormalizada = normalizarTexto(clave);
      if (claveNormalizada.length > 2 && entrada.contains(claveNormalizada)) {
        puntaje += 2;
      }
    }
    if (puntaje > mejorPuntaje) {
      mejorPuntaje = puntaje;
      mejor = pregunta;
    }
  }
  return mejorPuntaje >= 2 ? mejor : null;
}

const largoMaximoTituloConversacion = 40;

String tituloAutomaticoConversacion(String primeraPregunta) {
  final limpio = primeraPregunta.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (limpio.isEmpty) return 'Consulta';
  if (limpio.length <= largoMaximoTituloConversacion) return limpio;
  final corte = limpio.substring(0, largoMaximoTituloConversacion);
  final ultimoEspacio = corte.lastIndexOf(' ');
  final base = ultimoEspacio > 15 ? corte.substring(0, ultimoEspacio) : corte;
  return '${base.trimRight()}…';
}
