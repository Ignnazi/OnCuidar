import 'package:flutter/material.dart';
import '../../core/tema/paleta.dart';

class BotonPrincipal extends StatelessWidget {
  const BotonPrincipal({
    super.key,
    required this.etiqueta,
    required this.alPulsar,
    this.destacado = true,
  });

  final String etiqueta;
  final VoidCallback alPulsar;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    if (destacado) {
      return ElevatedButton(
        onPressed: alPulsar,
        child: Text(etiqueta),
      );
    }
    return OutlinedButton(
      onPressed: alPulsar,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Paleta.doradoPrincipal, width: 2),
        foregroundColor: Paleta.doradoPrincipal,
        minimumSize: const Size(double.infinity, 54),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Text(etiqueta),
    );
  }
}