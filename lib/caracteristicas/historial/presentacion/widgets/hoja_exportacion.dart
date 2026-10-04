import 'package:flutter/material.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/compartido/widgets/buscador.dart';
import 'package:oncuidar/compartido/widgets/fondo_hoja.dart';

enum AccionExportacion { abrir, compartir }

Future<AccionExportacion?> mostrarHojaExportacion(BuildContext context) {
  return showModalBottomSheet<AccionExportacion>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (contexto) => FondoHoja(
      sobreTarjeta: true,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('botonAbrirExportacion'),
              leading: Icon(
                Icons.open_in_new_rounded,
                color: Paleta.doradoOscuro,
              ),
              title: const Text('Abrir archivo'),
              onTap: () => Navigator.of(contexto).pop(AccionExportacion.abrir),
            ),
            ListTile(
              key: const Key('botonCompartirExportacion'),
              leading: Icon(Icons.share_rounded, color: Paleta.doradoOscuro),
              title: const Text('Compartir'),
              onTap: () =>
                  Navigator.of(contexto).pop(AccionExportacion.compartir),
            ),
          ],
        ),
      ),
    ),
  );
}

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
