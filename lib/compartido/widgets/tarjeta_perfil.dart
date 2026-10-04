import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';

class MarcoTarjetaPerfil extends StatelessWidget {
  const MarcoTarjetaPerfil({
    super.key,
    required this.hijos,
    required this.menu,
    this.menuArriba = 10,
  });

  final List<Widget> hijos;
  final Widget menu;
  final double menuArriba;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Paleta.tarjeta,
            borderRadius: const BorderRadius.vertical(
              top: Radius.zero,
              bottom: Radius.circular(24),
            ),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: hijos,
          ),
        ),
        Positioned(top: menuArriba, right: 10, child: menu),
      ],
    );
  }
}

class CabeceraDorada extends StatelessWidget {
  const CabeceraDorada({
    super.key,
    required this.icono,
    required this.etiqueta,
    required this.nombre,
    this.franjas = const [],
  });

  final IconData icono;
  final String etiqueta;
  final String nombre;
  final List<Widget> franjas;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 44, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Paleta.degradadoBanner,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: Paleta.alfa(claro: 0.22, oscuro: 0.35),
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icono, color: Paleta.sobreDorado, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta,
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Paleta.sobreDorado.withValues(
                      alpha: Paleta.alfa(claro: 0.85, oscuro: 0.8),
                    ),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nombre,
                  style: GoogleFonts.nunito(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Paleta.sobreDorado,
                  ),
                ),
                if (franjas.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(spacing: 8, runSpacing: 6, children: franjas),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
