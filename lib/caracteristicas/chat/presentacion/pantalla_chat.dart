import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/proveedores_biblioteca.dart';
import 'package:oncuidar/caracteristicas/chat/dominio/conversacion.dart';
import 'package:oncuidar/caracteristicas/chat/presentacion/controlador_chat.dart';
import 'package:oncuidar/caracteristicas/chat/presentacion/proveedor_chat_activo.dart';
import 'package:oncuidar/caracteristicas/chat/presentacion/widgets/burbujas_chat.dart';
import 'package:oncuidar/caracteristicas/chat/presentacion/widgets/entrada_chat.dart';
import 'package:oncuidar/caracteristicas/chat/presentacion/widgets/hoja_conversaciones.dart';
import 'package:oncuidar/caracteristicas/chat/presentacion/widgets/sugerencias_chat.dart';
import 'package:oncuidar/caracteristicas/preguntas_frecuentes/dominio/catalogo_preguntas.dart';
import 'package:oncuidar/compartido/estilos.dart';
import 'package:oncuidar/compartido/widgets/buscador.dart';
import 'package:oncuidar/compartido/widgets/encabezado_gradiente.dart';
import 'package:oncuidar/nucleo/utilidades/formato_fecha.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  static const _demoraRespuesta = Duration(milliseconds: 900);

  final _controladorTexto = TextEditingController();
  final _controladorBusqueda = TextEditingController();
  final _focoEntrada = FocusNode();
  final _focoBusqueda = FocusNode();
  final _scroll = ScrollController();
  late final _chat = ControladorChat(ref);

  bool _avisoGuardadoMostrado = false;
  bool _escribiendo = false;
  bool _buscando = false;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _controladorBusqueda.addListener(_alCambiarBusqueda);
    _inicializar();
  }

  Future<void> _inicializar() async {
    if (_chat.mensajes.isNotEmpty) {
      _irAlFinal();
      return;
    }
    try {
      final guardada = await _chat.conversacionGuardada();
      if (guardada != null && mounted) {
        _cargarConversacion(guardada);
        return;
      }
    } catch (_) {
      // Si falla, se sigue igual.
    }
    if (!mounted) return;
    _nuevaConversacion(null);
  }

  @override
  void dispose() {
    _controladorTexto.dispose();
    _controladorBusqueda.dispose();
    _focoEntrada.dispose();
    _focoBusqueda.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _alCambiarBusqueda() {
    setState(() => _busqueda = _controladorBusqueda.text);
  }

  bool get _muestraSugerenciasIniciales =>
      _chat.mensajes.length == 1 && !_escribiendo && !_buscando;

  bool get _muestraSeguimiento =>
      _chat.mensajes.length > 1 &&
      !_escribiendo &&
      !_buscando &&
      !_chat.mensajes.last.delUsuario &&
      _chat.preguntasNoUsadas.isNotEmpty;

  void _enviar([String? plantilla]) {
    final texto = (plantilla ?? _controladorTexto.text).trim();
    if (texto.isEmpty || _escribiendo) {
      return;
    }
    setState(() => _escribiendo = true);
    final respuesta = _chat.preguntar(texto);
    _controladorTexto.clear();
    _focoEntrada.unfocus();
    _encolarGuardado();

    unawaited(
      Future<void>.delayed(_demoraRespuesta, () {
        if (!mounted) {
          return;
        }
        setState(() => _escribiendo = false);
        _chat.responder(respuesta, consulta: texto);
        _irAlFinal();
        _encolarGuardado();
      }),
    );
  }

  void _encolarGuardado() {
    _chat.encolarGuardado(
      sigueAbierta: () => mounted,
      alFallar: _avisarFalloGuardado,
    );
  }

  void _avisarFalloGuardado() {
    if (_avisoGuardadoMostrado) return;
    _avisoGuardadoMostrado = true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'No se pudo guardar la conversación. Revisa tu conexión.',
        ),
        backgroundColor: Paleta.doradoPrincipal,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _abrirHojaConversaciones() {
    mostrarHojaConversaciones(
      context,
      alEntrar: _cargarConversacion,
      alEliminar: _alEliminarConversacion,
      alCrearNueva: _nuevaConversacion,
      alRenombrar: _chat.renombrarActiva,
    );
  }

  void _reiniciarVista() {
    setState(() {
      _escribiendo = false;
      _buscando = false;
    });
    _controladorBusqueda.clear();
    _focoBusqueda.unfocus();
  }

  void _cargarConversacion(Conversacion conversacion) {
    _reiniciarVista();
    _chat.cargar(conversacion);
    _irAlFinal();
  }

  void _nuevaConversacion(String? nombre) {
    _reiniciarVista();
    _chat.nueva(nombre);
    _irAlFinal();
  }

  void _alEliminarConversacion(Conversacion conversacion) {
    if (_chat.esActiva(conversacion.id)) {
      _nuevaConversacion(null);
    }
  }

  void _irAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) {
        return;
      }
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _alternarBusqueda() {
    setState(() {
      _buscando = !_buscando;
      if (!_buscando) {
        _controladorBusqueda.clear();
        _focoBusqueda.unfocus();
      }
    });
    if (_buscando) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _focoBusqueda.requestFocus(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(chatActivoProvider);
    ref.watch(contenidosEducativosProvider);
    return Scaffold(
      backgroundColor: Paleta.crema,
      body: Column(
        children: [
          EncabezadoGradiente(
            titulo: 'Chat de orientación',
            subtitulo: _chat.tituloConversacion ?? 'Resuelve tus dudas',
            logo: const AssetImage('assets/images/OnCuidar.png'),
            tamanoTitulo: 20,
            alto: 100,
            reservaDerecha: 104,
            alTocarLogo: () => context.go('/dashboard'),
            accionDerecha: _botonesAccion(),
          ),
          if (_buscando) _campoBusqueda(),
          Expanded(child: _zonaChat()),
          EntradaChat(
            controlador: _controladorTexto,
            foco: _focoEntrada,
            habilitada: !_escribiendo,
            alEnviar: _enviar,
          ),
        ],
      ),
    );
  }

  Widget _botonAccion({
    required Key key,
    required IconData icono,
    required String tooltip,
    required VoidCallback alTocar,
  }) {
    return BotonCircular(
      clave: key,
      tooltip: tooltip,
      alTocar: alTocar,
      hijo: Icon(icono, color: Paleta.doradoOscuro, size: 22),
    );
  }

  Widget _botonesAccion() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _botonAccion(
          key: const Key('alternarBusquedaChat'),
          icono: _buscando ? Icons.arrow_back : Icons.search,
          tooltip: _buscando ? 'Cerrar búsqueda' : 'Buscar en el chat',
          alTocar: _alternarBusqueda,
        ),
        const SizedBox(width: 8),
        _botonAccion(
          key: const Key('botonConversacionesChat'),
          icono: Icons.folder_rounded,
          tooltip: 'Mis conversaciones',
          alTocar: _abrirHojaConversaciones,
        ),
      ],
    );
  }

  Widget _campoBusqueda() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        key: const Key('campoBusquedaChat'),
        controller: _controladorBusqueda,
        focusNode: _focoBusqueda,
        style: GoogleFonts.nunito(fontSize: 14, color: Paleta.textoPrincipal),
        decoration:
            entradaDorada(
              hintText: 'Buscar en el chat…',
              prefixIcon: const Icon(
                Icons.search,
                color: Paleta.textoSecundario,
                size: 20,
              ),
            ).copyWith(
              suffixIcon: _busqueda.isNotEmpty
                  ? GestureDetector(
                      key: const Key('borrarBusquedaChat'),
                      onTap: _controladorBusqueda.clear,
                      child: const Icon(
                        Icons.cancel_rounded,
                        color: Paleta.textoSecundario,
                        size: 18,
                      ),
                    )
                  : null,
            ),
      ),
    );
  }

  bool _empiezaDia(List<MensajeConversacion> mensajes, int i) {
    final fecha = mensajes[i].enviadoEn;
    if (fecha == null) return false;
    final previa = mensajes.take(i).map((m) => m.enviadoEn).nonNulls.lastOrNull;
    return previa == null || !mismoDia(previa, fecha);
  }

  Widget _zonaChat() {
    final filtrados = _chat.filtrar(_busqueda);
    if (_buscando && _busqueda.trim().isNotEmpty && filtrados.isEmpty) {
      return const _SinResultados();
    }
    final ahora = DateTime.now();
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        for (var i = 0; i < filtrados.length; i++) ...[
          if (_empiezaDia(filtrados, i))
            SeparadorDia(fecha: filtrados[i].enviadoEn!, ahora: ahora),
          BurbujaMensaje(
            mensaje: filtrados[i],
            alAbrirMaterial: filtrados[i].materialId == null
                ? null
                : () => unawaited(
                    context.push(
                      '/biblioteca?abrir=${filtrados[i].materialId}',
                    ),
                  ),
            agrupado:
                i > 0 &&
                !_empiezaDia(filtrados, i) &&
                filtrados[i - 1].delUsuario == filtrados[i].delUsuario,
          ),
        ],
        if (!_buscando && _escribiendo) const BurbujaEscribiendo(),
        if (_muestraSeguimiento)
          SugerenciasSeguimiento(
            preguntas: _chat.preguntasNoUsadas,
            alElegir: _enviar,
          ),
        if (_muestraSugerenciasIniciales)
          PreguntasSugeridas(preguntas: preguntasFrecuentes, alElegir: _enviar),
      ],
    );
  }
}

class _SinResultados extends StatelessWidget {
  const _SinResultados();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 40,
              color: Paleta.textoSecundario,
            ),
            const SizedBox(height: 8),
            Text(
              'Sin resultados para tu búsqueda.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: Paleta.textoSecundario,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
