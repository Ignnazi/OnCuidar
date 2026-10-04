import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';

class BotonSalir extends StatelessWidget {
  const BotonSalir({super.key, required this.cargando, required this.alPulsar});

  final bool cargando;
  final VoidCallback alPulsar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Cerrar sesión',
      child: GestureDetector(
        key: const Key('botonCerrarSesion'),
        onTap: cargando ? null : alPulsar,
        child: Container(
          height: 48,
          constraints: const BoxConstraints(maxWidth: 170),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Paleta.tarjeta,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Paleta.doradoOscuro.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (cargando)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Paleta.doradoOscuro,
                    ),
                  )
                else
                  Icon(
                    Icons.logout_rounded,
                    color: Paleta.doradoOscuro,
                    size: 22,
                  ),
                const SizedBox(width: 8),
                Text(
                  'Cerrar sesión',
                  maxLines: 1,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Paleta.doradoOscuro,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
