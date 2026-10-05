import 'package:flutter/material.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/compartido/widgets/buscador.dart';

class BotonNuevoRegistro extends StatelessWidget {
  const BotonNuevoRegistro({super.key, required this.alPulsar});

  final VoidCallback alPulsar;

  @override
  Widget build(BuildContext context) {
    return BotonCircular(
      clave: const Key('botonNuevoRegistro'),
      tooltip: 'Nuevo registro',
      alTocar: alPulsar,
      hijo: Icon(Icons.edit_note_rounded, color: Paleta.doradoOscuro, size: 26),
    );
  }
}
