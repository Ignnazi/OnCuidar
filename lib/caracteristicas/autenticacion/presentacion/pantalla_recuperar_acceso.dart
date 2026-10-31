import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/compartido/widgets/aviso_sin_conexion.dart';
import 'package:oncuidar/compartido/widgets/campos_formulario.dart';
import 'package:oncuidar/compartido/widgets/hoja_segura.dart';
import 'package:oncuidar/nucleo/proveedores.dart';
import 'package:oncuidar/nucleo/sesion/servicio_sesion.dart';
import 'package:oncuidar/nucleo/utilidades/validacion_correo.dart';

bool interpretarRespuestaRecuperacion(Object? data) =>
    data is Map && data['ok'] == true;

Future<void> mostrarHojaRecuperarAcceso(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const RecuperarAcceso(enHoja: true),
  );
}

class RecuperarAcceso extends ConsumerStatefulWidget {
  const RecuperarAcceso({super.key, this.onSubmit, this.enHoja = false});

  final Future<void> Function(String email)? onSubmit;
  final bool enHoja;

  @override
  ConsumerState<RecuperarAcceso> createState() => _RecuperarAccesoState();
}

class _RecuperarAccesoState extends ConsumerState<RecuperarAcceso> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  bool _cargando = false;
  bool _enviado = false;
  String? _errorMensaje;

  @override
  void dispose() {
    _correoController.dispose();
    super.dispose();
  }

  Future<void> _envioPorDefecto(String email) =>
      ref.read(servicioSesionProvider).recuperarPorRespaldo(email);

  Future<void> _recuperarAcceso() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.onSubmit == null && estaSinConexion(ref)) {
      mostrarAvisoSinConexion(
        context,
        TextosSinConexion.necesitaInternetPara('recuperar tu acceso'),
      );
      return;
    }
    setState(() {
      _cargando = true;
      _errorMensaje = null;
    });

    try {
      await (widget.onSubmit ?? _envioPorDefecto)(
        _correoController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _enviado = true;
      });
    } on ExcepcionSesion catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _enviado = false;
        _errorMensaje =
            (e.codigo == CodigoErrorSesion.sinRed ||
                e.codigo == CodigoErrorSesion.tiempoAgotado)
            ? 'Sin conexión. Verifica tu internet e intenta de nuevo.'
            : 'No se pudo completar. Intenta de nuevo.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _enviado = false;
        _errorMensaje = 'No se pudo completar. Intenta de nuevo.';
      });
    }
  }

  bool get _bloquearEnvios => _cargando || _enviado;

  @override
  Widget build(BuildContext context) {
    final contenido = _contenido(context);
    if (widget.enHoja) return _MarcoHojaRespaldo(child: contenido);

    return Scaffold(
      backgroundColor: Paleta.crema,
      body: Align(alignment: Alignment.bottomCenter, child: contenido),
    );
  }

  Widget _contenido(BuildContext context) {
    return Material(
      color: Paleta.tarjeta,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Paleta.bordeTarjeta,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Paleta.doradoClaro,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.lock_reset_rounded,
                        color: Paleta.doradoOscuro,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Recuperar acceso',
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Paleta.textoPrincipal,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: Paleta.textoSecundario,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Escribe tu correo de respaldo. Te enviaremos un enlace para restablecer la contraseña.',
                  style: GoogleFonts.nunito(
                    fontSize: 13.5,
                    height: 1.4,
                    color: Paleta.textoSecundario,
                  ),
                ),
                const SizedBox(height: 20),
                const EtiquetaCampo(texto: 'Correo de respaldo'),
                const SizedBox(height: 8),
                CampoFormulario(
                  controlador: _correoController,
                  textoAyuda: 'correo@ejemplo.com',
                  icono: Icons.email_outlined,
                  tipoTeclado: TextInputType.emailAddress,
                  accionTeclado: TextInputAction.done,
                  alEnviar: (_) => _recuperarAcceso(),
                  habilitado: !_bloquearEnvios,
                  validador: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Ingresa tu correo de respaldo';
                    }
                    if (!regexCorreo.hasMatch(v.trim())) {
                      return 'Ingresa un correo válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _bloquearEnvios ? null : _recuperarAcceso,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Paleta.doradoPrincipal,
                      foregroundColor: Paleta.sobreDorado,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _cargando
                        ? SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Paleta.sobreDorado,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            _enviado ? 'Enlace enviado' : 'Enviar enlace',
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
                if (_enviado || _errorMensaje != null) ...[
                  const SizedBox(height: 16),
                  _PanelEstado(
                    color: _enviado ? Paleta.verdeExito : Paleta.error,
                    icono: _enviado
                        ? Icons.mark_email_read_outlined
                        : Icons.wifi_off_rounded,
                    texto: _enviado
                        ? 'Si ese correo está asociado a una cuenta, revisa tu bandeja de entrada y spam.'
                        : _errorMensaje!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MarcoHojaRespaldo extends StatelessWidget {
  const _MarcoHojaRespaldo({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      HojaConAreaSegura(separacionSuperior: 20, child: child);
}

class _PanelEstado extends StatelessWidget {
  const _PanelEstado({
    required this.color,
    required this.icono,
    required this.texto,
  });

  final Color color;
  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: GoogleFonts.nunito(
                fontSize: 13.5,
                height: 1.4,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
