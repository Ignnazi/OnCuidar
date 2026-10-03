import 'package:oncuidar/caracteristicas/biblioteca/dominio/categorias.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/material_educativo.dart';

class SeccionBiblioteca {
  const SeccionBiblioteca({required this.titulo, required this.materiales});

  final String titulo;
  final List<MaterialEducativo> materiales;
}

const ordenSecciones = ['Videos', 'Guías', 'Infografías'];

List<SeccionBiblioteca> agruparPorSeccion(List<MaterialEducativo> materiales) {
  final grupos = {
    for (final titulo in ordenSecciones) titulo: <MaterialEducativo>[],
  };
  final otros = <MaterialEducativo>[];
  for (final material in materiales) {
    final titulo = ordenSecciones.firstWhere(
      (filtro) => coincideFiltro(filtro, material.categoria),
      orElse: () => '',
    );
    (titulo.isEmpty ? otros : grupos[titulo]!).add(material);
  }
  return [
    for (final MapEntry(key: titulo, value: lista) in grupos.entries)
      if (lista.isNotEmpty)
        SeccionBiblioteca(titulo: titulo, materiales: lista),
    if (otros.isNotEmpty) SeccionBiblioteca(titulo: 'Otros', materiales: otros),
  ];
}
