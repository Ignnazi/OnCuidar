import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/tema/paleta.dart';

class AccesosRapidos extends StatelessWidget {
  const AccesosRapidos({super.key});

  static final List<_Acceso> _accesos = [
    _Acceso(
      icono: Icons.chat_bubble_outline,
      color: Paleta.doradoPrincipal,
      titulo: 'Orientación',
      subtitulo: 'Guía de cuidados',
      ruta: '/chat',
      degradado: true,
    ),
    _Acceso(
      icono: Icons.notifications_outlined,
      color: const Color(0xFFF07830),
      titulo: 'Recordatorios',
      subtitulo: 'Programa avisos',
      ruta: '/recordatorios',
    ),
    _Acceso(
      icono: Icons.help_outline,
      color: const Color(0xFFE8A820),
      titulo: 'FAQ',
      subtitulo: 'Resuelve dudas',
      ruta: '/faq',
    ),
    _Acceso(
      icono: Icons.book_outlined,
      color: const Color(0xFF4EC4D4),
      titulo: 'Biblioteca',
      subtitulo: 'Materiales y guías',
      ruta: '/biblioteca',
    ),
    _Acceso(
      icono: Icons.assignment_rounded,
      color: const Color(0xFF10B981),
      titulo: 'Registro',
      subtitulo: 'Registrar datos',
      ruta: '/registro-clinico',
    ),
    _Acceso(
      icono: Icons.history,
      color: const Color(0xFF8B5CF6),
      titulo: 'Historial',
      subtitulo: 'Registros pasados',
      ruta: '/historial',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            'ACCESO RÁPIDO',
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Paleta.textoSecundario,
            ),
          ),
        ),
        _fila(context, _accesos[0], _accesos[1]),
        const SizedBox(height: 8),
        _fila(context, _accesos[2], _accesos[3]),
        const SizedBox(height: 8),
        _fila(context, _accesos[4], _accesos[5]),
      ],
    );
  }

  Widget _fila(BuildContext context, _Acceso a, _Acceso b) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _tarjeta(context, a)),
          const SizedBox(width: 8),
          Expanded(child: _tarjeta(context, b)),
        ],
      ),
    );
  }

  Widget _tarjeta(BuildContext context, _Acceso acceso) {
    final degradado = acceso.degradado;
    final colorIcono = degradado ? Colors.white : acceso.color;
    final colorFondoIcono = degradado
        ? Colors.white.withValues(alpha: 0.25)
        : acceso.color.withValues(alpha: 0.10);
    final colorTitulo = degradado ? Colors.white : Paleta.textoPrincipal;
    final colorSubtitulo = degradado
        ? Colors.white.withValues(alpha: 0.85)
        : Paleta.textoSecundario;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(acceso.ruta),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: degradado ? null : Paleta.tarjeta,
            gradient: degradado
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Paleta.doradoMedio, Paleta.doradoOscuro],
                  )
                : null,
            borderRadius: BorderRadius.circular(16),
            border: degradado
                ? null
                : Border.all(
                    color: acceso.color.withValues(alpha: 0.20),
                    width: 1.2,
                  ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorFondoIcono,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(acceso.icono, size: 17, color: colorIcono),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        acceso.titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: colorTitulo,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        acceso.subtitulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          fontSize: 11.5,
                          color: colorSubtitulo,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: degradado
                      ? Colors.white.withValues(alpha: 0.8)
                      : Paleta.textoSecundario,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Acceso {
  const _Acceso({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.subtitulo,
    required this.ruta,
    this.degradado = false,
  });

  final IconData icono;
  final Color color;
  final String titulo;
  final String subtitulo;
  final String ruta;
  final bool degradado;
}
