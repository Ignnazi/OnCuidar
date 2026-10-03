import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/tema/paleta.dart';
import 'banner_conexion.dart';

class NavegacionPrincipal extends ConsumerStatefulWidget {
  const NavegacionPrincipal({
    super.key,
    required this.shell,
    required this.ubicacion,
    required this.child,
  });

  final StatefulNavigationShell shell;
  final String ubicacion;
  final Widget child;

  @override
  ConsumerState<NavegacionPrincipal> createState() =>
      _NavegacionPrincipalState();
}

class _NavegacionPrincipalState extends ConsumerState<NavegacionPrincipal> {
  static const _alturaBarra = 78.0;

  int get _indice {
    if (widget.ubicacion == '/registro-clinico' ||
        widget.ubicacion == '/historial') {
      return 2;
    }
    if (widget.ubicacion == '/chat') {
      return 1;
    }
    if (widget.ubicacion == '/biblioteca' ||
        widget.ubicacion.startsWith('/biblioteca/')) {
      return 3;
    }
    return widget.shell.currentIndex == 0 ? 0 : 4;
  }

  void _seleccionar(int indice) {
    switch (indice) {
      case 0:
        widget.shell.goBranch(0, initialLocation: true);
      case 1:
        if (widget.ubicacion == '/chat') break;
        context.push('/chat');
      case 2:
        if (widget.ubicacion == '/registro-clinico') {
          break;
        }
        context.push('/registro-clinico');
      case 3:
        if (widget.ubicacion.startsWith('/biblioteca')) {
          break;
        }
        context.push('/biblioteca');
      case 4:
        widget.shell.goBranch(1, initialLocation: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Paleta.crema,
      body: widget.child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [const BannerConexion(), _barraNavegacion()],
      ),
    );
  }

  Widget _barraNavegacion() {
    final paddingInferior = MediaQuery.of(context).padding.bottom;
    return Container(
      color: Paleta.tarjeta,
      padding: EdgeInsets.only(bottom: paddingInferior),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1, color: Paleta.bordeTarjeta),
          SizedBox(
            height: _alturaBarra,
            child: Row(
              children: [
                _elementoNav(
                  indice: 0,
                  icono: Icons.home_outlined,
                  iconoActivo: Icons.home_rounded,
                  etiqueta: 'Inicio',
                ),
                _elementoNav(
                  indice: 1,
                  icono: Icons.chat_bubble_outline,
                  iconoActivo: Icons.chat_bubble_rounded,
                  etiqueta: 'Chat',
                ),
                _elementoNav(
                  indice: 2,
                  icono: Icons.edit_note_outlined,
                  iconoActivo: Icons.edit_note_rounded,
                  etiqueta: 'Registro',
                ),
                _elementoNav(
                  indice: 3,
                  icono: Icons.menu_book_outlined,
                  iconoActivo: Icons.menu_book_rounded,
                  etiqueta: 'Aprende',
                ),
                _elementoNav(
                  indice: 4,
                  icono: Icons.person_outline,
                  iconoActivo: Icons.person_rounded,
                  etiqueta: 'Perfil',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _elementoNav({
    required int indice,
    required IconData icono,
    required IconData iconoActivo,
    required String etiqueta,
  }) {
    final activo = _indice == indice;
    return Expanded(
      child: GestureDetector(
        onTap: () => _seleccionar(indice),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 46,
              height: 34,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: activo
                      ? const [Paleta.doradoMedio, Paleta.doradoOscuro]
                      : const [Colors.transparent, Colors.transparent],
                ),
                borderRadius: BorderRadius.circular(17),
                boxShadow: [
                  BoxShadow(
                    color: Paleta.doradoOscuro.withValues(
                      alpha: activo ? 0.30 : 0.0,
                    ),
                    blurRadius: activo ? 8 : 0,
                    offset: Offset(0, activo ? 3 : 0),
                  ),
                ],
              ),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                tween: Tween<double>(end: activo ? 1 : 0),
                builder: (context, valor, child) => Icon(
                  activo ? iconoActivo : icono,
                  size: 22,
                  color: Color.lerp(
                    Paleta.textoSecundario,
                    Colors.white,
                    valor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: activo ? Paleta.doradoOscuro : Paleta.textoSecundario,
              ),
              child: Text(
                etiqueta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
