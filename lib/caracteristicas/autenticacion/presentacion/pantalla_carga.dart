import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/enrutador/destino_aviso.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/proveedores_biblioteca.dart';
import 'package:oncuidar/caracteristicas/pacientes/datos/proveedores_pacientes.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/ciclo_de_vida_paciente.dart';
import 'package:oncuidar/compartido/widgets/marca.dart';
import 'package:oncuidar/nucleo/proveedores.dart';

class Splash extends ConsumerStatefulWidget {
  const Splash({super.key, required this.alFinalizar, this.destino});

  final VoidCallback alFinalizar;

  final String? destino;

  @override
  ConsumerState<Splash> createState() => _SplashState();
}

class _SplashState extends ConsumerState<Splash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador;
  late final Animation<double> _opacidadLogo;
  late final Animation<double> _escalaLogo;
  late final Animation<double> _opacidadTexto;
  late final Animation<double> _opacidadSpinner;

  final _esperaClave = Completer<void>();
  bool _haySesion = false;

  @override
  void initState() {
    super.initState();
    _controlador = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _opacidadLogo = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controlador,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _escalaLogo = Tween<double>(begin: 0.85, end: 1).animate(
      CurvedAnimation(
        parent: _controlador,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );
    _opacidadTexto = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controlador,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );
    _opacidadSpinner = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controlador,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );
    _controlador.forward();
    _asegurarClaveEnParalelo();
    _sincronizarBibliotecaEnParalelo();
    _iniciar();
  }

  void _sincronizarBibliotecaEnParalelo() {
    final usuario = ref.read(servicioSesionProvider).actual;
    if (usuario == null) return;
    ref
        .read(sincronizacionBibliotecaProvider.notifier)
        .sincronizarAlIniciarSesion();
  }

  Future<void> _asegurarClaveEnParalelo() async {
    final usuario = ref.read(servicioSesionProvider).actual;
    if (usuario == null) return;
    _haySesion = true;
    try {
      await ref.read(servicioCifradoProvider).asegurarClave(usuario.uid);
      ref.read(bloqueoCifradoProvider.notifier).fijarDesbloqueado(true);
      _reagendarAvisos();
    } catch (_) {
      // Si falla, se sigue igual.
    } finally {
      if (!_esperaClave.isCompleted) _esperaClave.complete();
    }
  }

  void _reagendarAvisos() {
    try {
      reagendarAvisosEnSegundoPlano(ref.read(cicloDeVidaPacienteProvider));
    } catch (_) {
      // Si falla, se sigue igual.
    }
  }

  Future<void> _iniciar() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    if (_haySesion) {
      await _esperaClave.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {},
      );
      if (!mounted) return;
    }
    EstadoArranque.completado = true;
    final destino =
        destinoInternoSeguro(widget.destino) ??
        destinoInternoSeguro(EstadoArranque.destinoPendiente);
    if (_haySesion) {
      EstadoArranque.destinoPendiente = null;
      context.go(destino ?? '/dashboard');
    } else {
      EstadoArranque.destinoPendiente = destino;
      widget.alFinalizar();
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Paleta.doradoRelleno,
                Paleta.doradoPrincipal,
                coloresClaros.doradoClaro,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                AnimatedBuilder(
                  animation: _controlador,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _opacidadLogo.value,
                      child: Transform.scale(
                        scale: _escalaLogo.value,
                        child: child,
                      ),
                    );
                  },
                  child: const LogoCircular(tamano: 150),
                ),
                const SizedBox(height: 28),
                AnimatedBuilder(
                  animation: _controlador,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _opacidadTexto.value,
                      child: Column(
                        children: [
                          Text(
                            'Oncuidar',
                            style: GoogleFonts.nunito(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Paleta.sobreDorado,
                              letterSpacing: -0.5,
                              height: 1.1,
                              shadows: const [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 2),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Seguimiento y orientación\npara cuidadores',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.85),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Spacer(flex: 4),
                AnimatedBuilder(
                  animation: _controlador,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _opacidadSpinner.value,
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          color: Paleta.sobreDorado,
                          strokeWidth: 2.5,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
