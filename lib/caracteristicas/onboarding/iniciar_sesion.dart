import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/proveedores/proveedores.dart';
import '../../core/tema/paleta.dart';
import '../../core/utilidades/validacion_correo.dart';
import '../../compartidos/widgets/campos_formulario.dart';
import '../../compartidos/widgets/encabezado_gradiente.dart';

class IniciarSesion extends ConsumerStatefulWidget {
  const IniciarSesion({super.key});

  @override
  ConsumerState<IniciarSesion> createState() => _IniciarSesionState();
}

class _IniciarSesionState extends ConsumerState<IniciarSesion> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  bool _ocultarContrasena = true;
  bool _cargando = false;

  @override
  void dispose() {
    _correoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);

    try {
      final auth = ref.read(firebaseAuthProvider);
      final credential = await auth.signInWithEmailAndPassword(
        email: _correoController.text.trim(),
        password: _contrasenaController.text,
      );
      final uid = credential.user!.uid;

      await ref.read(servicioCifradoProvider).asegurarClave(uid);
      ref.read(bloqueoCifradoProvider.notifier).fijarDesbloqueado(true);
      ref
          .read(sincronizacionBibliotecaProvider.notifier)
          .sincronizarAlIniciarSesion();

      if (mounted) {
        FocusManager.instance.primaryFocus?.unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Bienvenido de vuelta!'),
            backgroundColor: Paleta.doradoPrincipal,
          ),
        );
        context.go('/dashboard');
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String mensaje;
      switch (e.code) {
        case 'user-not-found':
          mensaje = 'No existe una cuenta con ese correo.';
          break;
        case 'wrong-password':
          mensaje = 'La contraseña es incorrecta.';
          break;
        case 'invalid-email':
          mensaje = 'El correo electrónico no es válido.';
          break;
        case 'user-disabled':
          mensaje = 'Esta cuenta ha sido deshabilitada.';
          break;
        case 'too-many-requests':
          mensaje = 'Demasiados intentos. Intenta de nuevo más tarde.';
          break;
        default:
          mensaje = 'Error al iniciar sesión. Intenta de nuevo.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje), backgroundColor: Paleta.error),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error inesperado. Intenta de nuevo.'),
          backgroundColor: Paleta.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _recuperarContrasena() async {
    final correo = _correoController.text.trim();
    if (correo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa tu correo para recuperar el acceso.'),
          backgroundColor: Paleta.error,
        ),
      );
      return;
    }
    try {
      await ref
          .read(firebaseAuthProvider)
          .sendPasswordResetEmail(
            email: correo,
            actionCodeSettings: ActionCodeSettings(
              url: 'https://oncuidar-v1.firebaseapp.com/__/auth/action',
              handleCodeInApp: false,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Te enviamos un correo para restablecer tu contraseña.',
          ),
          backgroundColor: Paleta.doradoPrincipal,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String mensaje;
      switch (e.code) {
        case 'invalid-email':
          mensaje = 'El correo electrónico no es válido.';
          break;
        case 'user-not-found':
          mensaje = 'No existe una cuenta con ese correo.';
          break;
        default:
          mensaje = 'No se pudo enviar el correo. Intenta de nuevo.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje), backgroundColor: Paleta.error),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo enviar el correo. Intenta de nuevo.'),
          backgroundColor: Paleta.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.go('/bienvenida');
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
                      const SizedBox(height: 28),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '¡Hola de nuevo!',
                          style: GoogleFonts.nunito(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Paleta.textoPrincipal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Ingresa tus datos para continuar cuidando',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: Paleta.textoSecundario,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TarjetaSeccion(
                        icono: Icons.login_rounded,
                        titulo: 'Acceso',
                        hijos: [
                          EtiquetaCampo(texto: 'Correo electrónico'),
                          const SizedBox(height: 8),
                          CampoFormulario(
                            controlador: _correoController,
                            textoAyuda: 'correo@ejemplo.com',
                            icono: Icons.email_outlined,
                            tipoTeclado: TextInputType.emailAddress,
                            accionTeclado: TextInputAction.next,
                            validador: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Ingresa tu correo';
                              }
                              if (!regexCorreo.hasMatch(v.trim())) {
                                return 'Ingresa un correo válido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          EtiquetaCampo(texto: 'Contraseña'),
                          const SizedBox(height: 8),
                          CampoFormulario(
                            controlador: _contrasenaController,
                            textoAyuda: 'Tu contraseña',
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
                            alEnviar: (_) => _iniciarSesion(),
                            validador: (v) => v == null || v.isEmpty
                                ? 'Ingresa tu contraseña'
                                : null,
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _recuperarContrasena,
                              child: Text(
                                '¿Olvidaste tu contraseña?',
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Paleta.doradoOscuro,
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () =>
                                  context.push('/recuperar-acceso'),
                              child: Text(
                                'Recuperar con el correo de respaldo',
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Paleta.doradoOscuro,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: Opacity(
                          opacity: _cargando ? 0.6 : 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Paleta.doradoPrincipal,
                                  Paleta.doradoOscuro,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Paleta.doradoPrincipal.withValues(
                                    alpha: 0.35,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _cargando ? null : _iniciarSesion,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.transparent,
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _cargando
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      'Iniciar sesión',
                                      style: GoogleFonts.nunito(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: () => context.go('/crear-cuenta'),
                          child: Text.rich(
                            TextSpan(
                              text: '¿No tienes cuenta? ',
                              style: GoogleFonts.nunito(
                                color: Paleta.textoSecundario,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Crear cuenta',
                                  style: GoogleFonts.nunito(
                                    color: Paleta.doradoOscuro,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: EncabezadoGradiente(
                titulo: 'Iniciar sesión',
                subtitulo: 'Bienvenido a tu espacio de cuidado',
                logo: const AssetImage('assets/images/OnCuidar.png'),
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
