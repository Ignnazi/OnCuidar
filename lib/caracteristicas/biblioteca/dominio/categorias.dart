const etiquetasFiltro = ['Todos', 'Videos', 'Guías', 'Infografías'];

const _gruposGuia = {'Guías', 'PDFs'};

bool coincideFiltro(String filtro, String categoria) {
  final normalizada = categoria.toLowerCase();
  switch (filtro) {
    case 'Todos':
      return true;
    case 'Videos':
      return normalizada == 'videos';
    case 'Guías':
      return _gruposGuia.contains(categoria) || normalizada == 'guías';
    case 'Infografías':
      return normalizada == 'infografías';
    default:
      return true;
  }
}

String etiquetaCategoria(String categoria) {
  switch (categoria.toLowerCase()) {
    case 'videos':
      return 'Video';
    case 'guías':
    case 'pdfs':
      return 'Guía';
    case 'infografías':
      return 'Infografía';
    default:
      return categoria;
  }
}
