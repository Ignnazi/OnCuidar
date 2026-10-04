import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/autenticacion/presentacion/widgets/botones_acceso.dart';
import 'package:oncuidar/compartido/widgets/campos_formulario.dart';
import 'package:oncuidar/compartido/widgets/encabezado_gradiente.dart';
import 'package:oncuidar/compartido/widgets/marca.dart';
import 'package:oncuidar/nucleo/utilidades/validacion_correo.dart';

bool interpretarRespuestaRecuperacion(Object? data) =>
    data is Map && data['ok'] == true;

class RecuperarAcceso extends StatefulWidget {
  const RecuperarAcceso({super.key, this.onSubmit});

  final Future<void> Function(String email)? onSubmit;

  @override
  State<RecuperarAcceso> createState() => _RecuperarAccesoState();
}

class _RecuperarAccesoState extends State<RecuperarAcceso> {
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

  Future<void> _envioPorDefecto(String email) async {
    final resultado =
        await FirebaseFunctions.instanceFor(region: 'southamerica-west1')
            .httpsCallable('recuperarPorCorreoRespaldo')
            .call({'correo': email})
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () => throw FirebaseFunctionsException(
                code: 'unavailable',
                message: 'Sin conexión',
              ),
            );
    if (!interpretarRespuestaRecuperacion(resultado.data)) {
      throw StateError('Respuesta inesperada del servidor');
    }
  }

  Future<void> _recuperarAcceso() async {
    if (!_formKey.currentState!.validate()) return;
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
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _enviado = false;
        _errorMensaje =
            (e.code == 'unavailable' || e.code == 'deadline-exceeded')
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.go('/iniciar-sesion');
      },
      child: Scaffold(
        backgroundColor: Paleta.crema,
        body: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.of(context).padding.top + 100 + 8,
                  20,
                  24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Marca(tamano: 96),
                      const SizedBox(height: 16),
                      Text(
                        '¿No recuerdas tu correo?',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Paleta.textoPrincipal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ingresa tu correo de respaldo y te enviaremos los datos para recuperar tu cuenta.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: Paleta.textoSecundario,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TarjetaSeccion(
                        icono: Icons.lock_reset_rounded,
                        titulo: 'Correo de respaldo',
                        hijos: [
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
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _bloquearEnvios ? null : _recuperarAcceso,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Paleta.doradoPrincipal,
                            foregroundColor: Paleta.sobreDorado,
                            elevation: 2,
                            shadowColor: Paleta.doradoPrincipal.withValues(
                              alpha: 0.35,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            disabledBackgroundColor: Paleta.doradoPrincipal
                                .withValues(alpha: 0.5),
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
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_enviado) ...[
                        _PanelEstado(
                          color: Paleta.doradoPrincipal,
                          icono: Icons.mark_email_read_outlined,
                          texto:
                              'Si ese correo de respaldo está asociado a una cuenta, te enviamos un enlace para restablecer la contraseña. Revisa tu bandeja de entrada (y el spam).',
                        ),
                      ] else if (_errorMensaje != null) ...[
                        _PanelEstado(
                          color: Paleta.error,
                          icono: Icons.wifi_off_rounded,
                          texto: _errorMensaje!,
                        ),
                      ],
                      const SizedBox(height: 12),
                      EnlaceAcceso(
                        pregunta: '¿Recordaste tus datos? ',
                        accion: 'Iniciar sesión',
                        alPulsar: () => context.push('/iniciar-sesion'),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: EncabezadoGradiente(
                titulo: 'Recuperar acceso',
                subtitulo: 'Usa tu correo de respaldo para recuperar tu cuenta',
                logo: AssetImage('assets/images/OnCuidar.png'),
                tamanoTitulo: 20,
                alto: 100,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
