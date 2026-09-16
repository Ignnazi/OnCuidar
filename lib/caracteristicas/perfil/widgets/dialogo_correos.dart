import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/servicios/servicio_base_datos.dart';
import '../../../core/tema/paleta.dart';
import '../../../core/utilidades/validacion_correo.dart';
import '../../../compartidos/widgets/boton_principal.dart';
import '../../../compartidos/widgets/campos_formulario.dart';
import '../../../compartidos/widgets/titulo_seccion.dart';

Future<void> mostrarDialogoCorreos(
  BuildContext context, {
  required ServicioBaseDatos servicio,
  required String correoPrincipalOriginal,
  required String correoRespaldoOriginal,
  required bool editarPrincipal,
  required bool editarRespaldo,
  required Future<void> Function() alRefrescar,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    isDismissible: false,
    backgroundColor: Colors.transparent,
    builder: (_) => _DialogoCorreos(
      servicio: servicio,
      correoPrincipalOriginal: correoPrincipalOriginal,
      correoRespaldoOriginal: correoRespaldoOriginal,
      editarPrincipal: editarPrincipal,
      editarRespaldo: editarRespaldo,
      alRefrescar: alRefrescar,
    ),
  );
}

class _DialogoCorreos extends StatefulWidget {
  const _DialogoCorreos({
    required this.servicio,
    required this.correoPrincipalOriginal,
    required this.correoRespaldoOriginal,
    required this.editarPrincipal,
    required this.editarRespaldo,
    required this.alRefrescar,
  });

  final ServicioBaseDatos servicio;
  final String correoPrincipalOriginal;
  final String correoRespaldoOriginal;
  final bool editarPrincipal;
  final bool editarRespaldo;
  final Future<void> Function() alRefrescar;

  @override
  State<_DialogoCorreos> createState() => _DialogoCorreosState();
}

class _DialogoCorreosState extends State<_DialogoCorreos> {
  late final TextEditingController _principalController;
  late final TextEditingController _respaldoController;
  late final TextEditingController _contrasenaController;
  final _formKey = GlobalKey<FormState>();
  var _ocultarContrasena = true;
  var _cargando = false;

  @override
  void initState() {
    super.initState();
    _principalController = TextEditingController();
    _respaldoController = TextEditingController(
      text: widget.correoRespaldoOriginal,
    );
    _contrasenaController = TextEditingController();
  }

  @override
  void dispose() {
    _principalController.dispose();
    _respaldoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  bool get _hayCambioPrincipal {
    final nuevo = _principalController.text.trim().toLowerCase();
    return nuevo.isNotEmpty &&
        nuevo != widget.correoPrincipalOriginal.toLowerCase();
  }

  bool get _hayCambioRespaldo {
    final nuevo = _respaldoController.text.trim().toLowerCase();
    return nuevo.isNotEmpty &&
        nuevo != widget.correoRespaldoOriginal.toLowerCase();
  }

  bool get _hayCambios => _hayCambioPrincipal || _hayCambioRespaldo;

  String? _validarCorreo(
    String? valor, {
    required String original,
    required String otro,
  }) {
    final normalizado = (valor ?? '').trim();
    if (normalizado.isEmpty) return null;
    if (normalizado.toLowerCase() == original.toLowerCase()) return null;
    if (normalizado.isEmpty || !regexCorreo.hasMatch(normalizado)) {
      return 'Ingresa un correo válido';
    }
    if (normalizado.toLowerCase() == otro.toLowerCase()) {
      return 'Ese correo ya está en uso';
    }
    return null;
  }

  String? _validarRespaldo(String? valor) {
    final normalizado = (valor ?? '').trim();
    if (normalizado.isEmpty) return 'Ingresa el correo de respaldo';
    if (normalizado.toLowerCase() ==
        widget.correoRespaldoOriginal.toLowerCase()) {
      return null;
    }
    final principal = _principalController.text.trim().toLowerCase();
    if (normalizado.toLowerCase() == principal) {
      return 'Ese correo ya está en uso';
    }
    if (!regexCorreo.hasMatch(normalizado)) return 'Ingresa un correo válido';
    return null;
  }

  String get _titulo {
    if (widget.editarPrincipal && widget.editarRespaldo) {
      return 'Editar correos';
    }
    if (widget.editarPrincipal) return 'Editar correo principal';
    return widget.correoRespaldoOriginal.isEmpty
        ? 'Configurar correo de respaldo'
        : 'Editar correo de respaldo';
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    if (!_hayCambios) {
      nav.pop();
      return;
    }
    setState(() => _cargando = true);
    String? errorCorreo;
    var respaldoConfirmado = true;
    var cambiadoPrincipal = false;
    String? principalEnviado;

    if (_hayCambioRespaldo) {
      try {
        respaldoConfirmado = await widget.servicio.cambiarCorreoRespaldo(
          contrasena: _contrasenaController.text,
          nuevoCorreo: _respaldoController.text.trim(),
        );
      } on FirebaseAuthException catch (e) {
        errorCorreo ??= _mensajeErrorCambioCorreo(e);
      } catch (_) {
        errorCorreo ??= 'El correo de respaldo no se pudo actualizar.';
      }
    }
    if (_hayCambioPrincipal) {
      cambiadoPrincipal = true;
      principalEnviado = _principalController.text.trim();
      try {
        await widget.servicio.cambiarCorreoPrincipal(
          contrasena: _contrasenaController.text,
          nuevoCorreo: principalEnviado,
        );
      } on FirebaseAuthException catch (e) {
        errorCorreo ??= _mensajeErrorCambioCorreo(e);
      } catch (_) {
        errorCorreo ??= 'El correo principal no se pudo actualizar.';
      }
    }
    await widget.alRefrescar();
    if (!mounted) return;
    nav.pop();
    if (errorCorreo != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(errorCorreo), backgroundColor: Paleta.error),
      );
    } else if (cambiadoPrincipal) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Te enviamos un correo a $principalEnviado. '
            'Confírmalo para completar el cambio.',
          ),
          backgroundColor: Paleta.doradoPrincipal,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            respaldoConfirmado
                ? 'Correo de respaldo actualizado'
                : 'Correo de respaldo guardado '
                      '(pendiente de confirmar en el servidor)',
          ),
          backgroundColor: Paleta.doradoPrincipal,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final correosEditados = _hayCambios;
    return PopScope(
      canPop: false,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.66,
        minChildSize: 0.48,
        maxChildSize: 0.88,
        builder: (ctx, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Paleta.tarjeta,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Paleta.bordeTarjeta,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Paleta.doradoPrincipal,
                            Paleta.doradoOscuro,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.mark_email_unread_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _titulo,
                        style: GoogleFonts.nunito(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Paleta.textoPrincipal,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Paleta.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(
                      20,
                      8,
                      20,
                      24 + MediaQuery.of(ctx).viewInsets.bottom,
                    ),
                    children: [
                      TituloSeccion(
                        Icons.mark_email_unread_outlined,
                        'Correos',
                      ),
                      const SizedBox(height: 10),
                      if (widget.editarPrincipal) ...[
                        CampoFormulario(
                          controlador: _principalController,
                          textoAyuda: widget.correoPrincipalOriginal.isEmpty
                              ? 'Correo principal (cuenta de acceso)'
                              : widget.correoPrincipalOriginal,
                          icono: Icons.alternate_email,
                          tipoTeclado: TextInputType.emailAddress,
                          accionTeclado: TextInputAction.next,
                          alCambiar: (_) => setState(() {}),
                          validador: (v) => _validarCorreo(
                            v,
                            original: widget.correoPrincipalOriginal,
                            otro: _respaldoController.text,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Al cambiarlo te enviaremos un enlace de '
                          'verificación al nuevo correo.',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            height: 1.4,
                            color: Paleta.textoSecundario,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (widget.editarRespaldo) ...[
                        CampoFormulario(
                          controlador: _respaldoController,
                          textoAyuda: 'Correo de respaldo *',
                          icono: Icons.mark_email_read_outlined,
                          tipoTeclado: TextInputType.emailAddress,
                          accionTeclado: TextInputAction.done,
                          alCambiar: (_) => setState(() {}),
                          validador: _validarRespaldo,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sirve para recuperar tu cuenta si pierdes el '
                          'acceso al correo principal.',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            height: 1.4,
                            color: Paleta.textoSecundario,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      TituloSeccion(
                        Icons.lock_outline,
                        'Confirmar cambios de correo',
                      ),
                      const SizedBox(height: 10),
                      CampoFormulario(
                        controlador: _contrasenaController,
                        textoAyuda: 'Contraseña actual',
                        icono: Icons.lock_outlined,
                        oculto: _ocultarContrasena,
                        iconoSufijo: IconButton(
                          icon: Icon(
                            _ocultarContrasena
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _ocultarContrasena = !_ocultarContrasena,
                          ),
                        ),
                        accionTeclado: TextInputAction.done,
                        validador: (v) {
                          if (correosEditados && (v == null || v.isEmpty)) {
                            return 'Ingresa tu contraseña';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Confirmamos tu identidad antes de '
                        'cualquier cambio de correo.',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          height: 1.4,
                          color: Paleta.textoSecundario,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: BotonPrincipal(
                              etiqueta: 'Cancelar',
                              alPulsar: () => Navigator.of(ctx).pop(),
                              destacado: false,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: BotonPrincipal(
                              etiqueta: _cargando
                                  ? 'Guardando…'
                                  : 'Guardar cambios',
                              alPulsar: _cargando ? () {} : _guardar,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _mensajeErrorCambioCorreo(FirebaseAuthException e) {
  switch (e.code) {
    case 'wrong-password':
    case 'invalid-credential':
      return 'Contraseña incorrecta. Intenta de nuevo.';
    case 'invalid-email':
      return 'El correo electrónico no es válido.';
    case 'email-already-in-use':
    case 'credential-already-in-use':
      return 'Ya existe una cuenta con ese correo electrónico.';
    case 'requires-recent-login':
      return 'Por seguridad, inicia sesión de nuevo e intenta otra vez.';
    case 'too-many-requests':
      return 'Demasiados intentos. Espera unos minutos e intenta de nuevo.';
    case 'network-request-failed':
      return 'Sin conexión. Verifica tu internet e intenta de nuevo.';
    default:
      return 'No se pudo actualizar. Intenta de nuevo.';
  }
}