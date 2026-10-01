class ChecklistUsuario {
  final String id;
  final String titulo;
  final List<String> items;
  final List<int> indicesMarcados;
  final DateTime creadoEn;

  final DateTime? completadaEn;

  const ChecklistUsuario({
    required this.id,
    required this.titulo,
    required this.items,
    this.indicesMarcados = const [],
    required this.creadoEn,
    this.completadaEn,
  });

  List<int> get marcasValidas =>
      filtrarMarcas(indicesMarcados, items.length);

  bool get completada =>
      items.isNotEmpty && marcasValidas.length >= items.length;

  Map<String, dynamic> toMap() => {
    if (id.isNotEmpty) 'id': id,
    'titulo': titulo,
    'items': items,
    'indicesMarcados': indicesMarcados,
    'creadoEn': creadoEn.toIso8601String(),
    if (completadaEn != null) 'completadaEn': completadaEn!.toIso8601String(),
  };

  factory ChecklistUsuario.fromMap(String id, Map<String, dynamic> mapa) {
    final creado = mapa['creadoEn'];
    final completada = mapa['completadaEn'];
    return ChecklistUsuario(
      id: (mapa['id'] as String?) ?? id,
      titulo: mapa['titulo'] as String? ?? '',
      items:
          (mapa['items'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      indicesMarcados:
          (mapa['indicesMarcados'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      creadoEn: creado is DateTime
          ? creado
          : DateTime.tryParse(creado?.toString() ?? '') ?? DateTime.now(),
      completadaEn: completada is DateTime
          ? completada
          : DateTime.tryParse(completada?.toString() ?? ''),
    );
  }
}

List<int> filtrarMarcas(Iterable<int> marcas, int total) =>
    ({for (final i in marcas) if (i >= 0 && i < total) i}.toList()..sort());

List<int> recalcularMarcas({
  required List<String> itemsAnteriores,
  required Iterable<int> marcasAnteriores,
  required List<String> itemsNuevos,
}) {
  final pendientes = <String, int>{};
  for (final i in filtrarMarcas(marcasAnteriores, itemsAnteriores.length)) {
    final texto = itemsAnteriores[i].trim();
    pendientes[texto] = (pendientes[texto] ?? 0) + 1;
  }
  final resultado = <int>[];
  for (var j = 0; j < itemsNuevos.length; j++) {
    final texto = itemsNuevos[j].trim();
    final disponibles = pendientes[texto] ?? 0;
    if (disponibles > 0) {
      resultado.add(j);
      pendientes[texto] = disponibles - 1;
    }
  }
  return resultado;
}
