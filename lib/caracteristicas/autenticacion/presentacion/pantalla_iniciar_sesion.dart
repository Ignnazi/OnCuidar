import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/enrutador/destino_aviso.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/autenticacion/presentacion/widgets/botones_acceso.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/proveedores_biblioteca.dart';
import 'package:oncuidar/caracteristicas/pacientes/datos/proveedores_pacientes.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/ciclo_de_vida_paciente.dart';
import 'package:oncuidar/compartido/widgets/campos_formulario.dart';
import 'package:oncuidar/compartido/widgets/encabezado_gradiente.dart';
import 'package:oncuidar/nucleo/proveedores.dart';
import 'package:oncuidar/nucleo/sesion/servicio_sesion.dart';
import 'package:oncuidar/nucleo/utilidades/validacion_correo.dart';

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
      final sesion = await ref
          .read(servicioSesionProvider)
          .iniciarSesion(_correoController.text, _contrasenaController.text);

      await ref.read(servicioCifradoProvider).asegurarClave(sesion.uid);
      ref.read(bloqueoCifradoProvider.notifier).fijarDesbloqueado(true);
      unawaited(
        ref
            .read(sincronizacionBibliotecaProvider.notifier)
            .sincronizarAlIniciarSesion(),
      );
      try {
        reagendarAvisosEnSegundoPlano(ref.read(cicloDeVidaPacienteProvider));
      } catch (_) {
        // Si falla, se sigue igual.
      }

      if (mounted) {
        FocusManager.instance.primaryFocus?.unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('¡Bienvenido de vuelta!'),
            backgroundColor: Paleta.doradoPrincipal,
          ),
        );
        context.go(EstadoArranque.consumirDestino());
      }
    } on ExcepcionSesion catch (e) {
      if (!mounted) return;
      final mensaje = switch (e.codigo) {
        CodigoErrorSesion.credencialesInvalidas =>
          'Correo o contraseña incorrectos.',
        CodigoErrorSesion.correoInvalido =>
          'El correo electrónico no es válido.',
        CodigoErrorSesion.demasiadosIntentos =>
          'Demasiados intentos. Intenta de nuevo más tarde.',
        CodigoErrorSesion.sinRed || CodigoErrorSesion.tiempoAgotado =>
          'Sin conexión. Verifica tu internet e intenta de nuevo.',
        _ => 'Error al iniciar sesión. Intenta de nuevo.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje), backgroundColor: Paleta.error),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error inesperado. Intenta de nuevo.'),
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
        SnackBar(
          content: const Text('Ingresa tu correo para recuperar el acceso.'),
          backgroundColor: Paleta.error,
        ),
      );
      return;
    }
    try {
      await ref.read(servicioSesionProvider).recuperarContrasena(correo);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Te enviamos un correo para restablecer tu contraseña.',
          ),
          backgroundColor: Paleta.doradoPrincipal,
        ),
      );
    } on ExcepcionSesion catch (e) {
      if (!mounted) return;
      final mensaje = switch (e.codigo) {
        CodigoErrorSesion.correoInvalido =>
          'El correo electrónico no es válido.',
        CodigoErrorSesion.sinRed || CodigoErrorSesion.tiempoAgotado =>
          'Sin conexión. Verifica tu internet e intenta de nuevo.',
        _ => 'No se pudo enviar el correo. Intenta de nuevo.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje), backgroundColor: Paleta.error),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No se pudo enviar el correo. Intenta de nuevo.'),
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
                          const EtiquetaCampo(texto: 'Correo electrónico'),
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
                          const EtiquetaCampo(texto: 'Contraseña'),
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
                      BotonDegradado(
                        etiqueta: 'Iniciar sesión',
                        cargando: _cargando,
                        alPulsar: _iniciarSesion,
                      ),
                      const SizedBox(height: 12),
                      EnlaceAcceso(
                        pregunta: '¿No tienes cuenta? ',
                        accion: 'Crear cuenta',
                        alPulsar: () => context.go('/crear-cuenta'),
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
                titulo: 'Iniciar sesión',
                subtitulo: 'Bienvenido a tu espacio de cuidado',
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
