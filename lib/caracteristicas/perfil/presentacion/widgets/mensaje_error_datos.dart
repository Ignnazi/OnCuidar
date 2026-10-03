import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';

class MensajeErrorDatos extends StatelessWidget {
  const MensajeErrorDatos({super.key, required this.alReintentar});

  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Paleta.tarjeta,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Paleta.bordeTarjeta),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48, color: Paleta.error),
          const SizedBox(height: 12),
          Text(
            'No se pudieron cargar tus datos.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: Paleta.textoPrincipal,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: alReintentar, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
