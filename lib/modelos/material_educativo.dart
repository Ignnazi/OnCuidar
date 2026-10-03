class MaterialEducativo {
  final String id;
  final String title;
  final String category;
  final String topic;
  final String body;
  final String? imageUrl;
  final String? fileUrl;
  final String? thumbnailUrl;
  final String? fileType;
  final int? fileSizeBytes;
  final DateTime createdAt;

  const MaterialEducativo({
    required this.id,
    required this.title,
    required this.category,
    required this.topic,
    required this.body,
    this.imageUrl,
    this.fileUrl,
    this.thumbnailUrl,
    this.fileType,
    this.fileSizeBytes,
    required this.createdAt,
  });

  bool get esVideo => category.toLowerCase() == 'videos';

  bool get esChecklist => category.toLowerCase() == 'checklist';

  Map<String, dynamic> toMap() => {
    if (id.isNotEmpty) 'id': id,
    'title': title,
    'category': category,
    'topic': topic,
    'body': body,
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (fileUrl != null) 'fileUrl': fileUrl,
    if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
    if (fileType != null) 'fileType': fileType,
    if (fileSizeBytes != null) 'fileSizeBytes': fileSizeBytes,
    'createdAt': createdAt.toIso8601String(),
  };

  factory MaterialEducativo.fromMap(String id, Map<String, dynamic> mapa) {
    final creado = mapa['createdAt'];
    return MaterialEducativo(
      id: (mapa['id'] as String?) ?? id,
      title: mapa['title'] as String? ?? '',
      category: mapa['category'] as String? ?? '',
      topic: mapa['topic'] as String? ?? '',
      body: mapa['body'] as String? ?? '',
      imageUrl: mapa['imageUrl'] as String?,
      fileUrl: mapa['fileUrl'] as String?,
      thumbnailUrl: mapa['thumbnailUrl'] as String?,
      fileType: mapa['fileType'] as String?,
      fileSizeBytes: (mapa['fileSizeBytes'] as num?)?.toInt(),
      createdAt: creado is DateTime
          ? creado
          : DateTime.tryParse(creado?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
