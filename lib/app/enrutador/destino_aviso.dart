const rutasPublicas = {
  '/',
  '/bienvenida',
  '/iniciar-sesion',
  '/crear-cuenta',
  '/recuperar-acceso',
};

class EstadoArranque {
  static bool completado = false;

  static String? destinoPendiente;

  static void reiniciar() {
    completado = false;
    destinoPendiente = null;
  }

  static String consumirDestino() {
    final destino = destinoInternoSeguro(destinoPendiente) ?? '/dashboard';
    destinoPendiente = null;
    return destino;
  }
}

void abrirDesdeNotificacion(
  String? payload,
  void Function(String ruta) ir, {
  required bool haySesion,
}) {
  final destino = destinoInternoSeguro(payload);
  if (destino == null) return;
  if (haySesion && EstadoArranque.completado) {
    ir(destino);
  } else {
    EstadoArranque.destinoPendiente = destino;
  }
}

void registrarLanzamientoPorNotificacion(String? payload) {
  final destino = destinoInternoSeguro(payload);
  if (destino != null) EstadoArranque.destinoPendiente = destino;
}

String? destinoInternoSeguro(String? destino) {
  if (destino == null || !destino.startsWith('/') || destino.startsWith('//')) {
    return null;
  }
  final ruta = Uri.tryParse(destino)?.path;
  if (ruta == null || rutasPublicas.contains(ruta)) return null;
  return destino;
}
