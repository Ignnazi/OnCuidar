class MensajeConversacion {
  const MensajeConversacion({
    required this.texto,
    required this.delUsuario,
    this.enviadoEn,
    this.materialId,
    this.sugerenciaConsulta = false,
  });

  final String texto;
  final bool delUsuario;

  final DateTime? enviadoEn;

  final String? materialId;

  final bool sugerenciaConsulta;

  Map<String, dynamic> aMapa() => {
    'texto': texto,
    'delUsuario': delUsuario,
    if (enviadoEn != null) 'enviadoEn': enviadoEn!.toUtc().toIso8601String(),
    if (materialId != null) 'materialId': materialId,
    if (sugerenciaConsulta) 'sugerenciaConsulta': true,
  };

  factory MensajeConversacion.desdeMapa(Map<String, dynamic> mapa) {
    return MensajeConversacion(
      texto: (mapa['texto'] as String?) ?? '',
      delUsuario: (mapa['delUsuario'] as bool?) ?? false,
      enviadoEn: DateTime.tryParse(
        (mapa['enviadoEn'] as String?) ?? '',
      )?.toLocal(),
      materialId: mapa['materialId'] as String?,
      sugerenciaConsulta: (mapa['sugerenciaConsulta'] as bool?) ?? false,
    );
  }
}

class Conversacion {
  const Conversacion({
    required this.id,
    required this.titulo,
    required this.ultimaActividad,
    required this.creadoEn,
    required this.mensajes,
  });

  final String id;
  final String titulo;
  final DateTime ultimaActividad;
  final DateTime creadoEn;
  final List<MensajeConversacion> mensajes;
}
