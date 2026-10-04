import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';

class BotonCargarMas extends StatelessWidget {
  const BotonCargarMas({
    super.key,
    required this.cargando,
    required this.alPulsar,
  });

  final bool cargando;
  final VoidCallback alPulsar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: OutlinedButton.icon(
        onPressed: cargando ? null : alPulsar,
        icon: cargando
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Paleta.doradoOscuro,
                ),
              )
            : Icon(Icons.expand_more, color: Paleta.doradoOscuro),
        label: Text(
          'Cargar más registros',
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Paleta.doradoOscuro,
          ),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(46),
          side: BorderSide(color: Paleta.doradoMedio),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
