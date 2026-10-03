import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';

class EstadoSinPacientes extends StatelessWidget {
  const EstadoSinPacientes({super.key, this.nombreCuidador});

  static const _altoEncabezado = 100.0;

  final String? nombreCuidador;

  @override
  Widget build(BuildContext context) {
    final alto =
        MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        _altoEncabezado -
        48;
    final nombre = nombreCuidador;
    final subtitulo = (nombre != null && nombre.isNotEmpty)
        ? 'Hola, $nombre. Agrega un paciente para crear registros y '
              'recordatorios.'
        : 'Construye el grupo familiar: agrega un paciente para crear '
              'registros y recordatorios.';

    return SizedBox(
      height: alto < 0 ? 0 : alto,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.child_care_outlined,
              size: 64,
              color: Paleta.doradoPrincipal,
            ),
            const SizedBox(height: 16),
            Text(
              'Aún no tienes pacientes',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Paleta.textoPrincipal,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                subtitulo,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  height: 1.4,
                  color: Paleta.textoSecundario,
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/perfil'),
              icon: const Icon(Icons.person_add_alt_1, size: 20),
              label: const Text('Agregar paciente'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
