class MaterialEducativo {
  final String id;
  final String titulo;
  final String categoria;
  final String tema;
  final String cuerpo;
  final String? urlImagen;
  final String? urlArchivo;
  final String? urlMiniatura;
  final String? tipoArchivo;
  final int? tamanoBytes;
  final DateTime creadoEn;

  const MaterialEducativo({
    required this.id,
    required this.titulo,
    required this.categoria,
    required this.tema,
    required this.cuerpo,
    this.urlImagen,
    this.urlArchivo,
    this.urlMiniatura,
    this.tipoArchivo,
    this.tamanoBytes,
    required this.creadoEn,
  });

  bool get esVideo => categoria.toLowerCase() == 'videos';

  bool get esChecklist => categoria.toLowerCase() == 'checklist';

  Map<String, dynamic> toMap() => {
    if (id.isNotEmpty) 'id': id,
    'titulo': titulo,
    'categoria': categoria,
    'tema': tema,
    'cuerpo': cuerpo,
    if (urlImagen != null) 'urlImagen': urlImagen,
    if (urlArchivo != null) 'urlArchivo': urlArchivo,
    if (urlMiniatura != null) 'urlMiniatura': urlMiniatura,
    if (tipoArchivo != null) 'tipoArchivo': tipoArchivo,
    if (tamanoBytes != null) 'tamanoBytes': tamanoBytes,
    'creadoEn': creadoEn.toIso8601String(),
  };

  factory MaterialEducativo.fromMap(String id, Map<String, dynamic> mapa) {
    final creado = mapa['creadoEn'];
    return MaterialEducativo(
      id: (mapa['id'] as String?) ?? id,
      titulo: mapa['titulo'] as String? ?? '',
      categoria: mapa['categoria'] as String? ?? '',
      tema: mapa['tema'] as String? ?? '',
      cuerpo: mapa['cuerpo'] as String? ?? '',
      urlImagen: mapa['urlImagen'] as String?,
      urlArchivo: mapa['urlArchivo'] as String?,
      urlMiniatura: mapa['urlMiniatura'] as String?,
      tipoArchivo: mapa['tipoArchivo'] as String?,
      tamanoBytes: (mapa['tamanoBytes'] as num?)?.toInt(),
      creadoEn: creado is DateTime
          ? creado
          : DateTime.tryParse(creado?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
