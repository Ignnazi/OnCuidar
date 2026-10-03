const etiquetasFiltro = [
  'Todos',
  'Videos',
  'Guías',
  'Infografías',
  'Checklist',
];

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
    case 'Checklist':
      return normalizada == 'checklist';
    default:
      return true;
  }
}

String etiquetaCategoria(String categoria) {
  switch (categoria.toLowerCase()) {
    case 'videos':
      return 'Video';
    case 'guías':
      return 'Guía';
    case 'pdfs':
      return 'PDF';
    case 'infografías':
      return 'Infografía';
    case 'checklist':
      return 'Checklist';
    default:
      return categoria;
  }
}
