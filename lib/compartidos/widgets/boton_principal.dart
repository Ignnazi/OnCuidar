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
    // FittedBox + maxLines 1: etiquetas como "Archivados (1)" jamás se bajan
    // de línea; se ajustan al ancho disponible.
    if (destacado) {
      return ElevatedButton(
        onPressed: alPulsar,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            etiqueta,
            maxLines: 1,
            overflow: TextOverflow.fade,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return OutlinedButton(
      onPressed: alPulsar,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Paleta.doradoPrincipal, width: 2),
        foregroundColor: Paleta.doradoPrincipal,
        minimumSize: const Size(double.infinity, 54),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          etiqueta,
          maxLines: 1,
          overflow: TextOverflow.fade,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
