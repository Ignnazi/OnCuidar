import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oncuidar/caracteristicas/chat/dominio/conversacion.dart';
import 'package:oncuidar/caracteristicas/preguntas_frecuentes/dominio/catalogo_preguntas.dart';
import 'package:oncuidar/nucleo/proveedores.dart';
import 'package:shared_preferences/shared_preferences.dart';

const claveConversacionActiva = 'chat_conversacion_activa';

String claveConversacionActivaDe(String uid) =>
    '${claveConversacionActiva}_$uid';

class ChatActivoEstado {
  const ChatActivoEstado({
    this.conversacionId,
    this.titulo,
    this.categoria,
    this.mensajes = const [],
  });

  final String? conversacionId;
  final String? titulo;
  final String? categoria;
  final List<MensajeConversacion> mensajes;
}

// Global para que no se repita aunque el proveedor se reconstruya
int _ultimaGeneracion = 0;

class ChatActivoNotifier extends Notifier<ChatActivoEstado> {
  int _generacion = 0;

  // Cambia cada vez que se abre otra conversación
  int get generacion => _generacion;

  @override
  ChatActivoEstado build() {
    ref.watch(uidSesionProvider);
    _generacion = ++_ultimaGeneracion;
    return const ChatActivoEstado();
  }

  Future<String?> idGuardado() async {
    final uid = ref.read(uidSesionProvider);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(claveConversacionActiva);
      if (uid == null) return null;
      return prefs.getString(claveConversacionActivaDe(uid));
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistirId() async {
    final uid = ref.read(uidSesionProvider);
    if (uid == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = state.conversacionId;
      final clave = claveConversacionActivaDe(uid);
      if (id == null) {
        await prefs.remove(clave);
      } else {
        await prefs.setString(clave, id);
      }
    } catch (_) {
      // Si falla, se sigue igual.
    }
  }

  void cargar({
    required String id,
    required String titulo,
    String? categoria,
    required List<MensajeConversacion> mensajes,
  }) {
    _generacion = ++_ultimaGeneracion;
    state = ChatActivoEstado(
      conversacionId: id,
      titulo: titulo,
      categoria: categoria,
      mensajes: mensajes,
    );
    _persistirId();
  }

  void nueva({String? nombre}) {
    final nombreLimpio = nombre?.trim();
    _generacion = ++_ultimaGeneracion;
    state = ChatActivoEstado(
      titulo: (nombreLimpio == null || nombreLimpio.isEmpty)
          ? null
          : nombreLimpio,
      mensajes: const [
        MensajeConversacion(texto: mensajeBienvenidaChat, delUsuario: false),
      ],
    );
    _persistirId();
  }

  void agregarMensaje(MensajeConversacion mensaje) {
    state = ChatActivoEstado(
      conversacionId: state.conversacionId,
      titulo: state.titulo,
      categoria: state.categoria,
      mensajes: [...state.mensajes, mensaje],
    );
  }

  void fijarCategoria(String? categoria) {
    if (state.categoria == categoria) return;
    state = ChatActivoEstado(
      conversacionId: state.conversacionId,
      titulo: state.titulo,
      categoria: categoria,
      mensajes: state.mensajes,
    );
  }

  void fijarId(String? id) {
    if (state.conversacionId == id) return;
    state = ChatActivoEstado(
      conversacionId: id,
      titulo: state.titulo,
      categoria: state.categoria,
      mensajes: state.mensajes,
    );
    _persistirId();
  }

  // Solo si sigue abierta la misma conversación
  void fijarIdSiSigue(int generacion, String id) {
    if (!ref.mounted || _generacion != generacion) return;
    fijarId(id);
  }

  void fijarTitulo(String titulo) {
    state = ChatActivoEstado(
      conversacionId: state.conversacionId,
      titulo: titulo,
      categoria: state.categoria,
      mensajes: state.mensajes,
    );
  }
}

final chatActivoProvider =
    NotifierProvider<ChatActivoNotifier, ChatActivoEstado>(
      ChatActivoNotifier.new,
    );
