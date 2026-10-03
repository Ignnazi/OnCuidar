import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';

enum AccionExportacion { abrir, compartir }

Future<AccionExportacion?> mostrarHojaExportacion(BuildContext context) {
  return showModalBottomSheet<AccionExportacion>(
    context: context,
    backgroundColor: Paleta.tarjeta,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (contexto) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            key: const Key('botonAbrirExportacion'),
            leading: const Icon(
              Icons.open_in_new_rounded,
              color: Paleta.doradoOscuro,
            ),
            title: const Text('Abrir archivo'),
            onTap: () => Navigator.of(contexto).pop(AccionExportacion.abrir),
          ),
          ListTile(
            key: const Key('botonCompartirExportacion'),
            leading: const Icon(
              Icons.share_rounded,
              color: Paleta.doradoOscuro,
            ),
            title: const Text('Compartir'),
            onTap: () =>
                Navigator.of(contexto).pop(AccionExportacion.compartir),
          ),
        ],
      ),
    ),
  );
}

class BotonNuevoRegistro extends StatelessWidget {
  const BotonNuevoRegistro({super.key, required this.alPulsar});

  final VoidCallback alPulsar;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Nuevo registro',
      child: GestureDetector(
        key: const Key('botonNuevoRegistro'),
        onTap: alPulsar,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Paleta.doradoOscuro.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.add_rounded,
                color: Paleta.doradoOscuro,
                size: 17,
              ),
              const SizedBox(width: 6),
              Text(
                'Nuevo registro',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Paleta.doradoOscuro,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
