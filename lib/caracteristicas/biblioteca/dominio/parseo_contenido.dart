class BloqueContenido {
  const BloqueContenido({required this.esTitulo, required this.texto});

  final bool esTitulo;
  final String texto;
}

List<BloqueContenido> parsearCuerpo(String cuerpo) {
  final bloques = <BloqueContenido>[];
  for (final linea in cuerpo.split('\n')) {
    final texto = linea.trim();
    if (texto.isEmpty) continue;
    if (texto.startsWith('# ')) {
      bloques.add(
        BloqueContenido(esTitulo: true, texto: texto.substring(2).trim()),
      );
    } else {
      bloques.add(BloqueContenido(esTitulo: false, texto: texto));
    }
  }
  return bloques;
}
