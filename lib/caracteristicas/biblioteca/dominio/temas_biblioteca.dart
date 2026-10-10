import 'package:oncuidar/caracteristicas/biblioteca/dominio/categorias.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/material_educativo.dart';

const temaTodas = 'Todas';

const _tildes = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u'};

String _claveTema(String tema) => tema.trim().toLowerCase();

String _claveOrden(String texto) {
  final minusculas = texto.trim().toLowerCase();
  final buffer = StringBuffer();
  for (final letra in minusculas.split('')) {
    if (letra == 'ñ') {
      buffer.write('n~');
    } else {
      buffer.write(_tildes[letra] ?? letra);
    }
  }
  return buffer.toString();
}

List<String> temasDistintos(Iterable<MaterialEducativo> materiales) {
  final porClave = <String, String>{};
  for (final material in materiales) {
    final tema = material.tema.trim();
    if (tema.isEmpty) continue;
    porClave.putIfAbsent(_claveTema(tema), () => tema);
  }
  final temas = porClave.values.toList()
    ..sort((a, b) => _claveOrden(a).compareTo(_claveOrden(b)));
  return temas;
}

bool coincideTema(String tema, String temaMaterial) =>
    tema == temaTodas || _claveTema(tema) == _claveTema(temaMaterial);

/// Filtra por tipo y tema.
List<MaterialEducativo> filtrarPorTipoYTema(
  Iterable<MaterialEducativo> materiales, {
  required String filtro,
  required String tema,
}) => [
  for (final material in materiales)
    if (coincideFiltro(filtro, material.categoria) &&
        coincideTema(tema, material.tema))
      material,
];

List<MaterialEducativo> ordenarPorTemaYTitulo(
  Iterable<MaterialEducativo> materiales,
) {
  final lista = materiales.toList();
  lista.sort((a, b) {
    final porTema = _claveOrden(a.tema).compareTo(_claveOrden(b.tema));
    return porTema != 0
        ? porTema
        : _claveOrden(a.titulo).compareTo(_claveOrden(b.titulo));
  });
  return lista;
}

String temaVigente(String seleccionado, Iterable<String> temas) =>
    seleccionado == temaTodas || temas.contains(seleccionado)
    ? seleccionado
    : temaTodas;
