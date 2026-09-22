import 'package:cloud_firestore/cloud_firestore.dart';

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
    this.completadoEn,
    this.activo = true,
    required this.creadoEn,
  });

  final String id;
  final String pacienteId;

  /// 'medicamento' | 'medicion' | 'cita' | 'otro'
  final String tipo;
  final String titulo;
  final String? descripcion;
  final DateTime fechaHora;

  final List<String> diasRepeticion;

  final String? recurrencia;

  final DateTime? completadoEn;
  final bool activo;
  final DateTime creadoEn;

  bool get esMensual => recurrencia == 'mensual';
  bool get estaCompletado => completadoEn != null;

  Map<String, dynamic> toMap() => {
    'tipo': tipo,
    'pacienteId': pacienteId,
    'titulo': titulo,
    if (descripcion != null) 'descripcion': descripcion,
    'fechaHora': fechaHora.toIso8601String(),
    'diasRepeticion': diasRepeticion,
    if (recurrencia != null) 'recurrencia': recurrencia,
    if (completadoEn != null) 'completadoEn': completadoEn!.toIso8601String(),
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
      completadoEn: mapa['completadoEn'] == null
          ? null
          : _parsearFecha(mapa['completadoEn']),
      creadoEn: _parsearFecha(mapa['creadoEn']),
    );
  }

  static DateTime _parsearFecha(dynamic valor) {
    if (valor is DateTime) return valor;
    if (valor is Timestamp) return valor.toDate();
    return DateTime.tryParse(valor?.toString() ?? '') ?? DateTime.now();
  }
}
