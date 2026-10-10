class Recordatorio {
  const Recordatorio({
    required this.id,
    required this.pacienteId,
    required this.tipo,
    required this.titulo,
    this.descripcion,
    required this.fechaHora,
    this.diasRepeticion = const [],
    this.recurrencia,
    this.asignadoA = asignadoAPaciente,
    this.activo = true,
    required this.creadoEn,
  });

  static const asignadoAPaciente = 'paciente';
  static const asignadoACuidador = 'cuidador';

  final String id;
  final String pacienteId;

  /// 'medicamento' | 'medicion' | 'cita' | 'otro'
  final String tipo;
  final String titulo;
  final String? descripcion;
  final DateTime fechaHora;

  final List<String> diasRepeticion;

  final String? recurrencia;

  final String asignadoA;
  final bool activo;
  final DateTime creadoEn;

  bool get esMensual => recurrencia == 'mensual';
  bool get esRecurrente => esMensual || diasRepeticion.isNotEmpty;
  bool get esParaCuidador => asignadoA == asignadoACuidador;

  String tituloAviso(String nombrePaciente, String etiquetaTipo) =>
      esParaCuidador
      ? 'Cuidador · $etiquetaTipo'
      : '$nombrePaciente · $etiquetaTipo';

  String get cuerpoAviso =>
      '$titulo${descripcion != null && descripcion!.isNotEmpty ? ' · $descripcion' : ''}';

  Map<String, dynamic> toMap() => {
    'tipo': tipo,
    'pacienteId': pacienteId,
    'titulo': titulo,
    if (descripcion != null) 'descripcion': descripcion,
    'fechaHora': fechaHora.toIso8601String(),
    'diasRepeticion': diasRepeticion,
    if (recurrencia != null) 'recurrencia': recurrencia,
    'asignadoA': asignadoA,
    'activo': activo,
    'creadoEn': creadoEn.toIso8601String(),
  };

  factory Recordatorio.fromMap(String id, Map<String, dynamic> mapa) {
    return Recordatorio(
      id: id,
      pacienteId: (mapa['pacienteId'] as String?) ?? '',
      tipo: (mapa['tipo'] as String?) ?? 'otro',
      titulo: (mapa['titulo'] as String?) ?? '',
      descripcion: mapa['descripcion'] as String?,
      fechaHora: _parsearFecha(mapa['fechaHora']),
      diasRepeticion:
          (mapa['diasRepeticion'] as List<dynamic>?)
              ?.map((d) => d.toString())
              .toList() ??
          const [],
      activo: (mapa['activo'] as bool?) ?? true,
      recurrencia: mapa['recurrencia'] as String?,
      asignadoA: (mapa['asignadoA'] as String?) ?? asignadoAPaciente,
      creadoEn: _parsearFecha(mapa['creadoEn']),
    );
  }

  static DateTime _parsearFecha(dynamic valor) {
    if (valor is DateTime) return valor;
    return DateTime.tryParse(valor?.toString() ?? '') ?? DateTime.now();
  }
}

/// Nombre legible del tipo de recordatorio.
String etiquetaTipoRecordatorio(String tipo) => switch (tipo) {
  'medicamento' => 'Medicamento',
  'medicion' => 'Medición',
  'cita' => 'Cita médica',
  _ => 'Recordatorio',
};
