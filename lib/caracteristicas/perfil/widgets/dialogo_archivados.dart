import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/proveedores/proveedores.dart';
import '../../../core/tema/paleta.dart';
import '../../../modelos/paciente.dart';

Future<void> mostrarDialogoArchivados(
  BuildContext context, {
  required Future<void> Function(Paciente) alDesarchivar,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Consumer(
      builder: (context, ref, _) {
        final archivados =
            ref.watch(archivedPatientsListProvider).value ??
            const <Paciente>[];
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.8,
          builder: (ctx, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Paleta.tarjeta,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Paleta.bordeTarjeta,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Paleta.doradoPrincipal,
                              Paleta.doradoOscuro,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.archive_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          archivados.length == 1
                              ? '1 paciente archivado'
                              : '${archivados.length} pacientes archivados',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Paleta.textoPrincipal,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: Paleta.textoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Divider(height: 1, color: Paleta.bordeTarjeta),
                if (archivados.isEmpty)
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.inbox_outlined,
                              size: 40,
                              color: Paleta.textoSecundario,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No hay pacientes archivados.',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: Paleta.textoSecundario,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        for (final p in archivados)
                          _FilaArchivado(
                            paciente: p,
                            alDesarchivar: alDesarchivar,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _FilaArchivado extends StatelessWidget {
  const _FilaArchivado({
    required this.paciente,
    required this.alDesarchivar,
  });

  final Paciente paciente;
  final Future<void> Function(Paciente) alDesarchivar;

  @override
  Widget build(BuildContext context) {
    final inicial = paciente.fullName.isNotEmpty
        ? paciente.fullName[0].toUpperCase()
        : '?';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: BoxDecoration(
          color: Paleta.fondoEntrada.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Paleta.bordeTarjeta),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Paleta.doradoClaro.withValues(alpha: 0.7),
              child: Text(
                inicial,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800,
                  color: Paleta.doradoOscuro,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    paciente.fullName.isEmpty
                        ? 'Sin nombre'
                        : paciente.fullName,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Paleta.textoPrincipal,
                    ),
                  ),
                  if (paciente.diagnosis != null &&
                      paciente.diagnosis!.isNotEmpty)
                    Text(
                      paciente.diagnosis!,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: Paleta.textoSecundario,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => alDesarchivar(paciente),
              tooltip: 'Restaurar ${paciente.fullName}',
              icon: const Icon(
                Icons.unarchive_outlined,
                color: Paleta.doradoOscuro,
                size: 20,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Paleta.doradoClaro.withValues(alpha: 0.7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}