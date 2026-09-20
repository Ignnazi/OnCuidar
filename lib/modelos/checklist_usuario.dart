class ChecklistUsuario {
  final String id;
  final String titulo;
  final List<String> items;
  final List<int> indicesMarcados;
  final DateTime creadoEn;

  const ChecklistUsuario({
    required this.id,
    required this.titulo,
    required this.items,
    this.indicesMarcados = const [],
    required this.creadoEn,
  });

  Map<String, dynamic> toMap() => {
    if (id.isNotEmpty) 'id': id,
    'titulo': titulo,
    'items': items,
    'indicesMarcados': indicesMarcados,
    'creadoEn': creadoEn.toIso8601String(),
  };

  factory ChecklistUsuario.fromMap(String id, Map<String, dynamic> mapa) {
    final creado = mapa['creadoEn'];
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
    );
  }
}