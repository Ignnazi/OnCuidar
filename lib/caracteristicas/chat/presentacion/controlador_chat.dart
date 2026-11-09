import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/proveedores_biblioteca.dart';
import 'package:oncuidar/caracteristicas/chat/datos/proveedores_chat.dart';
import 'package:oncuidar/caracteristicas/chat/dominio/conversacion.dart';
import 'package:oncuidar/caracteristicas/chat/dominio/respuestas_chat.dart';
import 'package:oncuidar/caracteristicas/chat/presentacion/proveedor_chat_activo.dart';
import 'package:oncuidar/caracteristicas/chat/presentacion/proveedores_chat.dart';
import 'package:oncuidar/caracteristicas/preguntas_frecuentes/dominio/catalogo_preguntas.dart';
import 'package:oncuidar/caracteristicas/preguntas_frecuentes/dominio/pregunta_base.dart';

class ControladorChat {
  ControladorChat(this._ref);

  final WidgetRef _ref;
  Future<void> _colaGuardado = Future<void>.value();
  final _idsCreados = <int, String>{};
  final _eliminadas = <String>{};

  ChatActivoNotifier get _activo => _ref.read(chatActivoProvider.notifier);

  int get generacion => _activo.generacion;

  List<MensajeConversacion> get mensajes =>
      _ref.read(chatActivoProvider).mensajes;

  String? get tituloConversacion => _ref.read(chatActivoProvider).titulo;

  List<PreguntaBase> get preguntasNoUsadas {
    final usadas = mensajes
        .where((m) => m.delUsuario)
        .map((m) => m.texto)
        .toSet();
    return preguntasFrecuentes
        .where((p) => !usadas.contains(p.pregunta))
        .toList();
  }

  List<MensajeConversacion> filtrar(String busqueda) {
    final termino = normalizarTexto(busqueda);
    if (termino.isEmpty) {
      return mensajes;
    }
    return mensajes
        .where((m) => normalizarTexto(m.texto).contains(termino))
        .toList();
  }

  PreguntaBase? preguntar(String texto) {
    final respuesta = resolverPregunta(texto, preguntasFrecuentes);
    _activo.agregarMensaje(
      MensajeConversacion(
        texto: texto,
        delUsuario: true,
        enviadoEn: DateTime.now(),
      ),
    );
    if (respuesta != null && _ref.read(chatActivoProvider).categoria == null) {
      _activo.fijarCategoria(respuesta.categoria);
    }
    return respuesta;
  }

  void responder(PreguntaBase? respuesta, {required String consulta}) {
    final catalogo = _ref.read(contenidosEducativosProvider).value ?? const [];
    final material = respuesta == null
        ? null
        : materialRelacionado(respuesta, catalogo);
    _activo.agregarMensaje(
      MensajeConversacion(
        texto: respuesta?.respuesta ?? mensajeSinCoincidencia,
        delUsuario: false,
        enviadoEn: DateTime.now(),
        materialId: material?.id,
        sugerenciaConsulta: sugiereConsultarEquipo(consulta),
      ),
    );
  }

  Future<Conversacion?> conversacionGuardada() async {
    final id = await _activo.idGuardado();
    if (id == null || id.isEmpty) return null;
    final conversaciones = await _ref
        .read(conversacionesProvider.future)
        .timeout(const Duration(seconds: 5));
    for (final conversacion in conversaciones) {
      if (conversacion.id == id) return conversacion;
    }
    return null;
  }

  void cargar(Conversacion conversacion) {
    _activo.cargar(
      id: conversacion.id,
      titulo: conversacion.titulo,
      mensajes: [
        const MensajeConversacion(
          texto: mensajeBienvenidaChat,
          delUsuario: false,
        ),
        ...conversacion.mensajes,
      ],
    );
  }

  void nueva(String? nombre) => _activo.nueva(nombre: nombre);

  // Un guardado pendiente no debe volver a crear lo que se eliminó
  void marcarEliminada(String id) => _eliminadas.add(id);

  void desmarcarEliminada(String id) => _eliminadas.remove(id);

  bool esActiva(String id) =>
      id == _ref.read(chatActivoProvider).conversacionId;

  void renombrarActiva(String id, String titulo) {
    if (esActiva(id)) _activo.fijarTitulo(titulo);
  }

  List<MensajeConversacion> get _mensajesAGuardar =>
      mensajes.where((m) => m.texto != mensajeBienvenidaChat).toList();

  String _nombrePorDefecto() {
    final titulo = _ref.read(chatActivoProvider).titulo?.trim();
    if (titulo != null && titulo.isNotEmpty) {
      return titulo;
    }
    final primera = _mensajesAGuardar.where((m) => m.delUsuario).firstOrNull;
    return tituloAutomaticoConversacion(primera?.texto ?? '');
  }

  void encolarGuardado({
    required bool Function() sigueAbierta,
    required VoidCallback alFallar,
  }) {
    // Se guarda lo que había al encolar, aunque luego se cambie de chat
    final generacion = this.generacion;
    final mensajes = _mensajesAGuardar;
    final id = _ref.read(chatActivoProvider).conversacionId;
    final titulo = _nombrePorDefecto();
    _colaGuardado = _colaGuardado.then(
      (_) => _persistir(
        generacion: generacion,
        mensajes: mensajes,
        id: id,
        titulo: titulo,
        sigueAbierta: sigueAbierta,
        alFallar: alFallar,
      ),
    );
  }

  Future<void> _persistir({
    required int generacion,
    required List<MensajeConversacion> mensajes,
    required String? id,
    required String titulo,
    required bool Function() sigueAbierta,
    required VoidCallback alFallar,
  }) async {
    if (!sigueAbierta()) return;
    if (mensajes.isEmpty) return;
    try {
      final repositorio = _ref.read(repositorioConversacionesProvider);
      // Se toma antes de esperar, la pantalla puede cerrarse entretanto
      final activo = _activo;
      final existente = id ?? _idsCreados[generacion];
      if (existente != null && _eliminadas.contains(existente)) return;
      if (existente == null) {
        final nuevo = await repositorio.crearConversacion(
          titulo: titulo,
          mensajes: mensajes,
        );
        _idsCreados[generacion] = nuevo;
        activo.fijarIdSiSigue(generacion, nuevo);
      } else {
        await repositorio.actualizarConversacion(existente, mensajes: mensajes);
      }
    } catch (e, pila) {
      debugPrint('No se pudo persistir la conversación: $e\n$pila');
      if (sigueAbierta()) alFallar();
    }
  }
}
