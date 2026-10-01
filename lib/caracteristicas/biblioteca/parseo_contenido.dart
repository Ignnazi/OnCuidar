class BloqueContenido {
  const BloqueContenido({required this.esTitulo, required this.texto});

  final bool esTitulo;
  final String texto;
}

List<BloqueContenido> parsearCuerpo(String body) {
  final bloques = <BloqueContenido>[];
  for (final linea in body.split('\n')) {
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

List<String> parsearItemsChecklist(String body) {
  final items = <String>[];
  for (final linea in body.split('\n')) {
    final texto = linea.trim();
    if (texto.isEmpty) continue;
    if (texto.startsWith('- ')) items.add(texto.substring(2).trim());
  }
  return items;
}

String textoInformativoChecklist(String body) {
  final lineas = <String>[];
  for (final linea in body.split('\n')) {
    final texto = linea.trim();
    if (texto.isEmpty || texto.startsWith('- ')) continue;
    lineas.add(texto);
  }
  return lineas.join('\n');
}
