import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/chat/dominio/conversacion.dart';
import 'package:oncuidar/nucleo/utilidades/formato_fecha.dart';

/// Avatar redondo del asistente.
class AvatarAsistente extends StatelessWidget {
  const AvatarAsistente({super.key});

  @override
  Widget build(BuildContext context) {
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
}

class BurbujaMensaje extends StatelessWidget {
  const BurbujaMensaje({
    super.key,
    required this.mensaje,
    this.agrupado = false,
    this.alAbrirMaterial,
  });

  final MensajeConversacion mensaje;

  final bool agrupado;

  final VoidCallback? alAbrirMaterial;

  Future<void> _copiar(BuildContext context) async {
    final aviso = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: mensaje.texto));
    aviso.showSnackBar(
      const SnackBar(
        content: Text('Mensaje copiado'),
        backgroundColor: Paleta.doradoPrincipal,
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final delUsuario = mensaje.delUsuario;
    return Padding(
      padding: EdgeInsets.only(bottom: agrupado ? 4 : 10),
      child: Row(
        mainAxisAlignment: delUsuario
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!delUsuario) ...[
            const AvatarAsistente(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              key: const Key('burbujaMensajeChat'),
              onLongPress: () => unawaited(_copiar(context)),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        mensaje.texto,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: delUsuario
                              ? Colors.white
                              : Paleta.textoPrincipal,
                          height: 1.45,
                        ),
                      ),
                    ),
                    if (!delUsuario && mensaje.sugerenciaConsulta)
                      const _SugerenciaConsulta(),
                    if (!delUsuario && alAbrirMaterial != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          key: const Key('verMaterialChat'),
                          onPressed: alAbrirMaterial,
                          icon: const Icon(Icons.menu_book_rounded, size: 18),
                          label: const Text('Ver material relacionado'),
                          style: TextButton.styleFrom(
                            foregroundColor: Paleta.doradoOscuro,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    if (mensaje.enviadoEn != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        hora12(mensaje.enviadoEn!),
                        key: const Key('horaMensajeChat'),
                        style: GoogleFonts.nunito(
                          fontSize: 10.5,
                          color: delUsuario
                              ? Colors.white.withValues(alpha: 0.8)
                              : Paleta.textoSecundario,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SugerenciaConsulta extends StatelessWidget {
  const _SugerenciaConsulta();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('sugerenciaConsultaChat'),
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Paleta.doradoClaro,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            size: 17,
            color: Paleta.doradoOscuro,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Te sugiero comentárselo a su equipo médico si esto te '
              'preocupa; ellos conocen mejor su caso.',
              style: GoogleFonts.nunito(
                fontSize: 12.5,
                color: Paleta.doradoOscuro,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SeparadorDia extends StatelessWidget {
  const SeparadorDia({super.key, required this.fecha, required this.ahora});

  final DateTime fecha;
  final DateTime ahora;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 12),
      child: Center(
        child: Container(
          key: const Key('separadorDiaChat'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Paleta.doradoClaro,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            etiquetaDia(fecha, ahora),
            style: GoogleFonts.nunito(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Paleta.doradoOscuro,
            ),
          ),
        ),
      ),
    );
  }
}

class BurbujaEscribiendo extends StatelessWidget {
  const BurbujaEscribiendo({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const AvatarAsistente(),
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
            child: const _PuntosAnimados(),
          ),
        ],
      ),
    );
  }
}

class _PuntosAnimados extends StatefulWidget {
  const _PuntosAnimados();

  @override
  State<_PuntosAnimados> createState() => _PuntosAnimadosState();
}

class _PuntosAnimadosState extends State<_PuntosAnimados>
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
