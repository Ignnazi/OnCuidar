import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../compartidos/widgets/encabezado_gradiente.dart';
import '../../../core/tema/paleta.dart';

class CabeceraRegistro extends StatelessWidget {
  const CabeceraRegistro({
    super.key,
    required this.esEdicion,
    this.onVerHistorial,
  });

  final bool esEdicion;

  final VoidCallback? onVerHistorial;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: EncabezadoGradiente(
        titulo: esEdicion ? 'Editar registro' : 'Registro clínico',
        subtitulo: esEdicion
            ? 'Actualiza signos y síntomas'
            : 'Registra el cuidado',
        logo: const AssetImage('assets/images/OnCuidar.png'),
        tamanoTitulo: 20,
        reservaDerecha: 140,
        alTocarLogo: () => context.go('/dashboard'),
        accionDerecha: !esEdicion
            ? Tooltip(
                message: 'Ver historial',
                child: GestureDetector(
                  onTap: onVerHistorial,
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Paleta.doradoOscuro.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.history_rounded,
                          color: Paleta.doradoOscuro,
                          size: 17,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Ver historial',
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
              )
            : null,
      ),
    );
  }
}