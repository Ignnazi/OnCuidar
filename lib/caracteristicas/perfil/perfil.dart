import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/proveedores/proveedores.dart';
import '../../core/tema/paleta.dart';
import '../../compartidos/widgets/encabezado_gradiente.dart';

class Perfil extends ConsumerStatefulWidget {
  const Perfil({super.key});

  @override
  ConsumerState<Perfil> createState() => _PerfilState();
}

class _PerfilState extends ConsumerState<Perfil> {
  Map<String, String?>? _cuidador;
  bool _cargando = true;
  bool _error = false;
  bool _cerrandoSesion = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = false;
    });
    try {
      final datos = await ref.read(servicioBaseDatosProvider).obtenerCuidador();
      if (!mounted) return;
      setState(() => _cuidador = datos);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que deseas cerrar tu sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    setState(() => _cerrandoSesion = true);
    try {
      await ref.read(firebaseAuthProvider).signOut();
    } catch (_) {
      // El estado de sesion se resuelve con el listener de autenticacion.
    }
    if (mounted) context.go('/bienvenida');
  }

  String _iniciales(String nombre) {
    final partes = nombre.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return 'C';
    final letras = partes.take(2).map((p) => p[0]).join();
    return letras.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final email = _cuidador?['email'] ??
        ref.read(firebaseAuthProvider).currentUser?.email ??
        '';
    return Scaffold(
      backgroundColor: Paleta.crema,
      body: Column(
        children: [
          const EncabezadoGradiente(
            titulo: 'Mi perfil',
            subtitulo: 'Tu información personal',
            alto: 130,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  if (_cargando)
                    const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: CircularProgressIndicator(),
                    )
                  else if (_error)
                    _mensajeError()
                  else
                    _tarjetaPerfil(email),
                  if (!_cargando && !_error) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _cerrandoSesion ? null : _cerrarSesion,
                        icon: _cerrandoSesion
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Paleta.error,
                                ),
                              )
                            : const Icon(Icons.logout_rounded, size: 20),
                        label: const Text('Cerrar sesión'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Paleta.error,
                          side: const BorderSide(color: Paleta.error, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaPerfil(String email) {
    final nombre = _cuidador?['nombre'] ?? '';
    final telefono = _cuidador?['telefono'];
    final relacion = _cuidador?['relacion'];
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Paleta.tarjeta,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Paleta.bordeTarjeta),
        boxShadow: [
          BoxShadow(
            color: Paleta.doradoOscuro.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Paleta.doradoOscuro,
                  Paleta.doradoPrincipal,
                  Paleta.doradoClaro,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Paleta.doradoPrincipal,
                        Paleta.doradoOscuro,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Paleta.doradoOscuro.withValues(alpha: 0.30),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _iniciales(nombre),
                    style: GoogleFonts.nunito(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  nombre.isEmpty ? 'Cuidador' : nombre,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Paleta.textoPrincipal,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: Paleta.textoSecundario,
                    ),
                  ),
                ],
                if (relacion != null && relacion.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _dato(icono: Icons.family_restroom_outlined, texto: 'Relación: $relacion'),
                ],
                if (telefono != null && telefono.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _dato(icono: Icons.phone_outlined, texto: telefono),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dato({required IconData icono, required String texto}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icono, size: 16, color: Paleta.doradoOscuro),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            texto,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: Paleta.textoPrincipal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _mensajeError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Paleta.tarjeta,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Paleta.bordeTarjeta),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48, color: Paleta.error),
          const SizedBox(height: 12),
          Text(
            'No se pudieron cargar tus datos.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: Paleta.textoPrincipal,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _cargar,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}