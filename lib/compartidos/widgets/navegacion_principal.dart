import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/tema/paleta.dart';

class NavegacionPrincipal extends ConsumerStatefulWidget {
  const NavegacionPrincipal({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NavegacionPrincipal> createState() =>
      _NavegacionPrincipalState();
}

class _NavegacionPrincipalState extends ConsumerState<NavegacionPrincipal> {
  int _indice = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ubicacion = GoRouterState.of(context).uri.path;
    if (ubicacion == '/dashboard') {
      _indice = 0;
    } else if (ubicacion == '/perfil') {
      _indice = 3;
    }
  }

  void _seleccionar(int indice) {
    switch (indice) {
      case 0:
        context.go('/dashboard');
      case 1:
        context.push('/proximamente?titulo=Chat');
      case 2:
        context.push('/proximamente?titulo=Educativo');
      case 3:
        context.go('/perfil');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Paleta.crema,
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Paleta.doradoOscuro.withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _elementoNav(
                  indice: 0,
                  icono: Icons.home_rounded,
                  etiqueta: 'Inicio',
                ),
                _elementoNav(
                  indice: 1,
                  icono: Icons.chat_bubble_rounded,
                  etiqueta: 'Chat',
                ),
                _elementoNav(
                  indice: 2,
                  icono: Icons.school_rounded,
                  etiqueta: 'Educativo',
                ),
                _elementoNav(
                  indice: 3,
                  icono: Icons.person_rounded,
                  etiqueta: 'Perfil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _elementoNav({
    required int indice,
    required IconData icono,
    required String etiqueta,
  }) {
    final activo = _indice == indice;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _seleccionar(indice),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: activo ? Paleta.doradoClaro : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icono,
                  size: 26,
                  color: activo ? Paleta.doradoOscuro : Paleta.textoSecundario,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                etiqueta,
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: activo ? FontWeight.w800 : FontWeight.w500,
                  color: activo ? Paleta.doradoOscuro : Paleta.textoSecundario,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}