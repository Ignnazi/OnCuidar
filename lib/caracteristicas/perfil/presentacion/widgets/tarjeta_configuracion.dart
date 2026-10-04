import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/configuracion/presentacion/seccion_configuracion.dart';

class TarjetaConfiguracion extends StatelessWidget {
  const TarjetaConfiguracion({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Paleta.tarjeta,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: const Key('abrirConfiguracion'),
        borderRadius: BorderRadius.circular(18),
        onTap: () => mostrarHojaConfiguracion(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Paleta.bordeTarjeta),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Paleta.doradoClaro,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: Paleta.doradoOscuro,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuración de la app',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Paleta.textoPrincipal,
                      ),
                    ),
                    Text(
                      'Apariencia, tamaño del texto y avisos',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: Paleta.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Paleta.textoSecundario),
            ],
          ),
        ),
      ),
    );
  }
}
