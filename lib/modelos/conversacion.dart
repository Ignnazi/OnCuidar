class MensajeConversacion {
  const MensajeConversacion({required this.texto, required this.delUsuario});

  final String texto;
  final bool delUsuario;

  Map<String, dynamic> aMapa() => {'texto': texto, 'delUsuario': delUsuario};

  factory MensajeConversacion.desdeMapa(Map<String, dynamic> mapa) {
    return MensajeConversacion(
      texto: (mapa['texto'] as String?) ?? '',
      delUsuario: (mapa['delUsuario'] as bool?) ?? false,
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
