import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../compartidos/widgets/encabezado_gradiente.dart';
import '../../core/proveedores/proveedores.dart';
import '../../core/tema/paleta.dart';
import '../../core/util/estilos.dart';
import '../../modelos/conversacion.dart';
import '../faq/datos_faq.dart';
import '../faq/pregunta_base.dart';
import 'chat_activo_provider.dart';
import 'widgets/hoja_conversaciones.dart';

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

  List<MensajeConversacion> get _mensajes =>
      ref.read(chatActivoProvider).mensajes;

  String? get _tituloConversacion => ref.read(chatActivoProvider).titulo;

  Future<void> _colaGuardado = Future<void>.value();
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
    final activo = ref.read(chatActivoProvider);
    if (activo.mensajes.isNotEmpty) {
      _irAlFinal();
      return;
    }
    try {
      final id = await ref.read(chatActivoProvider.notifier).idGuardado();
      if (id != null && id.isNotEmpty) {
        final conversaciones = await ref
            .read(conversacionesProvider.future)
            .timeout(const Duration(seconds: 5));
        for (final conversacion in conversaciones) {
          if (conversacion.id == id && mounted) {
            _cargarConversacion(conversacion);
            return;
          }
        }
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

  List<PreguntaBase> get _preguntasNoUsadas {
    final usadas = _mensajes
        .where((m) => m.delUsuario)
        .map((m) => m.texto)
        .toSet();
    return preguntasFrecuentes
        .where((p) => !usadas.contains(p.pregunta))
        .toList();
  }

  bool get _muestraSugerenciasIniciales =>
      _mensajes.length == 1 && !_escribiendo && !_buscando;

  bool get _muestraSeguimiento =>
      _mensajes.length > 1 &&
      !_escribiendo &&
      !_buscando &&
      !_mensajes.last.delUsuario &&
      _preguntasNoUsadas.isNotEmpty;

  List<MensajeConversacion> get _mensajesFiltrados {
    final termino = normalizarTexto(_busqueda);
    if (termino.isEmpty) {
      return _mensajes;
    }
    return _mensajes
        .where((m) => normalizarTexto(m.texto).contains(termino))
        .toList();
  }

  PreguntaBase? _resolver(String texto) {
    final entrada = normalizarTexto(texto);
    if (entrada.isEmpty) {
      return null;
    }
    final tokens = entrada
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.length > 2)
        .toList();
    PreguntaBase? mejor;
    var mejorPuntaje = 0;
    for (final pregunta in preguntasFrecuentes) {
      final cuerpo = normalizarTexto(
        '${pregunta.pregunta} ${pregunta.claves.join(' ')}',
      );
      var puntaje = 0;
      if (cuerpo.contains(entrada)) {
        puntaje += 6;
      }
      for (final token in tokens) {
        if (cuerpo.contains(token)) {
          puntaje += token.length >= 6 ? 2 : 1;
        }
      }
      for (final clave in pregunta.claves) {
        final claveNormalizada = normalizarTexto(clave);
        if (claveNormalizada.length > 2 && entrada.contains(claveNormalizada)) {
          puntaje += 2;
        }
      }
      if (puntaje > mejorPuntaje) {
        mejorPuntaje = puntaje;
        mejor = pregunta;
      }
    }
    return mejorPuntaje >= 2 ? mejor : null;
  }

  void _enviar([String? plantilla]) {
    final texto = (plantilla ?? _controladorTexto.text).trim();
    if (texto.isEmpty || _escribiendo) {
      return;
    }
    final respuesta = _resolver(texto);
    setState(() {
      _escribiendo = true;
    });
    final notifier = ref.read(chatActivoProvider.notifier);
    notifier.agregarMensaje(
      MensajeConversacion(texto: texto, delUsuario: true),
    );
    if (respuesta != null && ref.read(chatActivoProvider).categoria == null) {
      notifier.fijarCategoria(respuesta.categoria);
    }
    _controladorTexto.clear();
    _focoEntrada.unfocus();
    _encolarGuardado();

    unawaited(
      Future<void>.delayed(_demoraRespuesta, () {
        if (!mounted) {
          return;
        }
        setState(() {
          _escribiendo = false;
        });
        ref
            .read(chatActivoProvider.notifier)
            .agregarMensaje(
              MensajeConversacion(
                texto: respuesta?.respuesta ?? mensajeSinCoincidencia,
                delUsuario: false,
              ),
            );
        _irAlFinal();
        _encolarGuardado();
      }),
    );
  }

  List<MensajeConversacion> get _mensajesAGuardar =>
      _mensajes.where((m) => m.texto != mensajeBienvenidaChat).toList();

  String _nombrePorDefecto() {
    final titulo = ref.read(chatActivoProvider).titulo?.trim();
    if (titulo != null && titulo.isNotEmpty) {
      return titulo;
    }
    final primera = _mensajesAGuardar.where((m) => m.delUsuario).firstOrNull;
    return tituloAutomaticoConversacion(primera?.texto ?? '');
  }

  void _encolarGuardado() {
    _colaGuardado = _colaGuardado.then((_) => _persistirConversacion());
  }

  Future<void> _persistirConversacion() async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final mensajes = _mensajesAGuardar;
    if (mensajes.isEmpty) return;
    try {
      final base = ref.read(servicioBaseDatosProvider);
      final activo = ref.read(chatActivoProvider);
      if (activo.conversacionId == null) {
        final id = await base.crearConversacion(
          titulo: _nombrePorDefecto(),
          mensajes: mensajes,
        );
        ref.read(chatActivoProvider.notifier).fijarId(id);
      } else {
        await base.actualizarConversacion(
          activo.conversacionId!,
          mensajes: mensajes,
        );
      }
    } catch (e, pila) {
      debugPrint('No se pudo persistir la conversación: $e\n$pila');
      if (!mounted || _avisoGuardadoMostrado) return;
      _avisoGuardadoMostrado = true;
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo guardar la conversación. Revisa tu conexión.',
          ),
          backgroundColor: Paleta.doradoPrincipal,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _abrirHojaConversaciones() {
    mostrarHojaConversaciones(
      context,
      alEntrar: _cargarConversacion,
      alEliminar: _alEliminarConversacion,
      alCrearNueva: _nuevaConversacion,
      alRenombrar: (id, titulo) {
        if (id == ref.read(chatActivoProvider).conversacionId) {
          ref.read(chatActivoProvider.notifier).fijarTitulo(titulo);
        }
      },
    );
  }

  void _cargarConversacion(Conversacion conversacion) {
    setState(() {
      _escribiendo = false;
      _buscando = false;
    });
    _controladorBusqueda.clear();
    _focoBusqueda.unfocus();
    ref
        .read(chatActivoProvider.notifier)
        .cargar(
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
    _irAlFinal();
  }

  void _nuevaConversacion(String? nombre) {
    setState(() {
      _escribiendo = false;
      _buscando = false;
    });
    _controladorBusqueda.clear();
    _focoBusqueda.unfocus();
    ref.read(chatActivoProvider.notifier).nueva(nombre: nombre);
    _irAlFinal();
  }

  void _alEliminarConversacion(Conversacion conversacion) {
    if (conversacion.id == ref.read(chatActivoProvider).conversacionId) {
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
    return Scaffold(
      backgroundColor: Paleta.crema,
      body: Column(
        children: [
          EncabezadoGradiente(
            titulo: 'Chat de orientación',
            subtitulo: _tituloConversacion ?? 'Resuelve tus dudas',
            logo: const AssetImage('assets/images/OnCuidar.png'),
            tamanoTitulo: 20,
            alto: 100,
            reservaDerecha: 104,
            alTocarLogo: () => context.go('/dashboard'),
            accionDerecha: _botonesAccion(),
          ),
          if (_buscando) _campoBusqueda(),
          Expanded(child: _zonaChat()),
          _areaEntrada(),
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
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        key: key,
        onTap: alTocar,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Paleta.doradoOscuro.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icono, color: Paleta.doradoOscuro, size: 22),
        ),
      ),
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

  Widget _zonaChat() {
    final filtrados = _mensajesFiltrados;
    if (_buscando && _busqueda.trim().isNotEmpty && filtrados.isEmpty) {
      return _estadoSinResultados();
    }
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        for (var i = 0; i < filtrados.length; i++)
          _burbuja(
            filtrados[i],
            agrupado:
                i > 0 && filtrados[i - 1].delUsuario == filtrados[i].delUsuario,
          ),
        if (!_buscando && _escribiendo) _indicadorEscribiendo(),
        if (_muestraSeguimiento) _sugerenciasSeguimiento(),
        if (_muestraSugerenciasIniciales) _preguntasSugeridas(),
      ],
    );
  }

  Widget _preguntasSugeridas() {
    final sugerencias = preguntasFrecuentes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Preguntas frecuentes',
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Paleta.textoTerciario,
            ),
          ),
        ),
        for (final pregunta in sugerencias)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              key: Key('sugerencia_${pregunta.id}'),
              onTap: () => _enviar(pregunta.pregunta),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Paleta.tarjeta,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Paleta.doradoOscuro.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Paleta.doradoBannerClaro,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.question_answer_outlined,
                        color: Paleta.doradoOscuro,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        pregunta.pregunta,
                        style: GoogleFonts.nunito(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Paleta.textoPrincipal,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Paleta.textoSecundario,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: GestureDetector(
            key: const Key('verPreguntasFrecuentes'),
            onTap: () => context.push('/faq'),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.help_outline_rounded,
                    size: 16,
                    color: Paleta.doradoOscuro,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Ver todas las preguntas frecuentes',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Paleta.doradoOscuro,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sugerenciasSeguimiento() {
    final sugerencias = _preguntasNoUsadas;
    return Padding(
      padding: const EdgeInsets.only(left: 36, top: 4, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Otras preguntas:',
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: Paleta.textoSecundario,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final pregunta in sugerencias)
                GestureDetector(
                  key: Key('seguimiento_${pregunta.id}'),
                  onTap: () => _enviar(pregunta.pregunta),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Paleta.doradoBannerClaro,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Paleta.doradoMedio.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      pregunta.pregunta,
                      style: GoogleFonts.nunito(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Paleta.doradoOscuro,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _indicadorEscribiendo() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _avatarAsistente(),
          const SizedBox(width: 8),
          Container(
            key: const Key('indicadorEscribiendo'),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: Paleta.tarjeta,
              borderRadius: BorderRadius.circular(
                18,
              ).copyWith(bottomLeft: const Radius.circular(6)),
              boxShadow: [
                BoxShadow(
                  color: Paleta.doradoOscuro.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const _IndicadorEscribiendo(),
          ),
        ],
      ),
    );
  }

  Widget _avatarAsistente() {
    return Container(
      width: 30,
      height: 30,
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        gradient: Paleta.degradadoCabecera,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Paleta.doradoOscuro.withValues(alpha: 0.18),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const Icon(
        Icons.smart_toy_outlined,
        color: Colors.white,
        size: 16,
      ),
    );
  }

  Widget _burbuja(MensajeConversacion mensaje, {bool agrupado = false}) {
    final delUsuario = mensaje.delUsuario;
    return Padding(
      padding: EdgeInsets.only(bottom: agrupado ? 4 : 10),
      child: Row(
        mainAxisAlignment: delUsuario
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!delUsuario) ...[_avatarAsistente(), const SizedBox(width: 8)],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                gradient: delUsuario ? Paleta.degradadoCabecera : null,
                color: delUsuario ? null : Paleta.tarjeta,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomRight: delUsuario ? const Radius.circular(6) : null,
                  bottomLeft: !delUsuario ? const Radius.circular(6) : null,
                ),
                border: delUsuario
                    ? Border.all(color: Colors.white.withValues(alpha: 0.25))
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Paleta.doradoOscuro.withValues(
                      alpha: delUsuario ? 0.18 : 0.06,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                mensaje.texto,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: delUsuario ? Colors.white : Paleta.textoPrincipal,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _areaEntrada() {
    return Container(
      color: Paleta.crema,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
                decoration: BoxDecoration(
                  color: Paleta.tarjeta,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Paleta.bordeTarjeta),
                  boxShadow: [
                    BoxShadow(
                      color: Paleta.doradoOscuro.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  key: const Key('campoMensajeChat'),
                  controller: _controladorTexto,
                  focusNode: _focoEntrada,
                  enabled: !_escribiendo,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _enviar(),
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: Paleta.textoPrincipal,
                    height: 1.4,
                  ),
                  decoration: InputDecoration.collapsed(
                    hintText: 'Escribe tu duda aquí…',
                    hintStyle: GoogleFonts.nunito(
                      fontSize: 14,
                      color: Paleta.textoSecundario,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controladorTexto,
              builder: (context, valor, _) {
                final tieneTexto = valor.text.trim().isNotEmpty;
                return GestureDetector(
                  key: const Key('enviarMensaje'),
                  onTap: _enviar,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: Paleta.degradadoCabecera,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Paleta.doradoOscuro.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Opacity(
                      opacity: tieneTexto ? 1 : 0.4,
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _estadoSinResultados() {
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

class _IndicadorEscribiendo extends StatefulWidget {
  const _IndicadorEscribiendo();

  @override
  State<_IndicadorEscribiendo> createState() => _IndicadorEscribiendoState();
}

class _IndicadorEscribiendoState extends State<_IndicadorEscribiendo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat();

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  Widget _punto(int indice) {
    final animacion = CurvedAnimation(
      parent: _controlador,
      curve: Interval(
        indice * 0.18,
        indice * 0.18 + 0.4,
        curve: Curves.easeInOut,
      ),
    );
    return AnimatedBuilder(
      animation: animacion,
      builder: (context, _) {
        final valor = animacion.value;
        return Transform.translate(
          offset: Offset(0, -3 * valor),
          child: Opacity(
            opacity: 0.25 + 0.75 * valor,
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Paleta.textoSecundario,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _punto(0),
        const SizedBox(width: 6),
        _punto(1),
        const SizedBox(width: 6),
        _punto(2),
      ],
    );
  }
}

const largoMaximoTituloConversacion = 40;

String tituloAutomaticoConversacion(String primeraPregunta) {
  final limpio = primeraPregunta.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (limpio.isEmpty) return 'Consulta';
  if (limpio.length <= largoMaximoTituloConversacion) return limpio;
  final corte = limpio.substring(0, largoMaximoTituloConversacion);
  final ultimoEspacio = corte.lastIndexOf(' ');
  final base = ultimoEspacio > 15 ? corte.substring(0, ultimoEspacio) : corte;
  return '${base.trimRight()}…';
}
