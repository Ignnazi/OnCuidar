import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/historial/presentacion/widgets/cabecera_tarjeta_registro.dart';
import 'package:oncuidar/caracteristicas/historial/presentacion/widgets/detalle_registro.dart';
import 'package:oncuidar/caracteristicas/historial/presentacion/widgets/mini_signos.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';

class TarjetaRegistro extends StatelessWidget {
  const TarjetaRegistro({
    super.key,
    required this.registro,
    required this.etiqueta,
    required this.expandido,
    required this.onToggle,
    required this.onEditar,
    required this.onEliminar,
  });

  final RegistroClinico registro;
  final String etiqueta;
  final bool expandido;
  final VoidCallback onToggle;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Paleta.tarjeta,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Paleta.bordeTarjeta),
        boxShadow: [
          BoxShadow(
            color: Paleta.doradoOscuro.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: CabeceraRegistro(
              registro: registro,
              etiqueta: etiqueta,
              onEditar: onEditar,
              onEliminar: onEliminar,
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MiniSignos(signos: registro.signosVitales),
                  Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              expandido ? Icons.expand_less : Icons.expand_more,
                              size: 18,
                              color: Paleta.doradoOscuro,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Click para ver registro completo',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Paleta.doradoOscuro,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expandido) DetalleRegistro(registro: registro),
        ],
      ),
    );
  }
}
