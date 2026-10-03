import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';

class IconoDorado extends StatelessWidget {
  const IconoDorado(this.icono, {super.key});

  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Paleta.doradoPrincipal, Paleta.doradoOscuro],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icono, size: 17, color: Colors.white),
    );
  }
}

class TarjetaDorada extends StatelessWidget {
  const TarjetaDorada({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Paleta.tarjeta,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Paleta.doradoClaro),
        boxShadow: [
          BoxShadow(
            color: Paleta.doradoOscuro.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class FilaDato extends StatelessWidget {
  const FilaDato({
    super.key,
    required this.icono,
    required this.etiqueta,
    required this.valor,
    this.valorAusente = false,
    this.recortar = false,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;

  final bool valorAusente;

  final bool recortar;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconoDorado(icono),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                etiqueta,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Paleta.textoTerciario,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                valor,
                overflow: recortar ? TextOverflow.ellipsis : null,
                style: valorAusente
                    ? GoogleFonts.nunito(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Paleta.textoSecundario,
                      )
                    : GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Paleta.textoPrincipal,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
