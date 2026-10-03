import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';

class BotonCerrarSesion extends StatelessWidget {
  const BotonCerrarSesion({
    super.key,
    required this.cargando,
    required this.alPulsar,
  });

  final bool cargando;
  final VoidCallback alPulsar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: ElevatedButton.icon(
        onPressed: cargando ? null : alPulsar,
        icon: cargando
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.logout_rounded, size: 19),
        label: const Text('Cerrar sesión'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Paleta.doradoPrincipal,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Paleta.doradoMedio,
          minimumSize: const Size(double.infinity, 54),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
