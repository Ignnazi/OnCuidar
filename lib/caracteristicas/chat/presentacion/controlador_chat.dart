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

  ChatActivoNotifier get _activo => _ref.read(chatActivoProvider.notifier);

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
    _colaGuardado = _colaGuardado.then(
      (_) => _persistir(sigueAbierta: sigueAbierta, alFallar: alFallar),
    );
  }

  Future<void> _persistir({
    required bool Function() sigueAbierta,
    required VoidCallback alFallar,
  }) async {
    if (!sigueAbierta()) return;
    final mensajes = _mensajesAGuardar;
    if (mensajes.isEmpty) return;
    try {
      final repositorio = _ref.read(repositorioConversacionesProvider);
      final activo = _ref.read(chatActivoProvider);
      if (activo.conversacionId == null) {
        final id = await repositorio.crearConversacion(
          titulo: _nombrePorDefecto(),
          mensajes: mensajes,
        );
        _activo.fijarId(id);
      } else {
        await repositorio.actualizarConversacion(
          activo.conversacionId!,
          mensajes: mensajes,
        );
      }
    } catch (e, pila) {
      debugPrint('No se pudo persistir la conversación: $e\n$pila');
      if (sigueAbierta()) alFallar();
    }
  }
}
