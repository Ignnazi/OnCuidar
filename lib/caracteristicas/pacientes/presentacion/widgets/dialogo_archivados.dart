import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/paciente.dart';
import 'package:oncuidar/caracteristicas/pacientes/presentacion/proveedores_pacientes.dart';
import 'package:oncuidar/compartido/widgets/hoja_dialogo.dart';

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
            ref.watch(pacientesArchivadosProvider).value ?? const <Paciente>[];
        return HojaDialogo(
          icono: Icons.archive_outlined,
          titulo: archivados.length == 1
              ? '1 paciente archivado'
              : '${archivados.length} pacientes archivados',
          tamanoInicial: 0.6,
          tamanoMinimo: 0.4,
          tamanoMaximo: 0.8,
          tamanoTitulo: 16,
          cuerpo: (ctx, scrollController) => [
            Divider(height: 1, color: Paleta.bordeTarjeta),
            if (archivados.isEmpty)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
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
                      _FilaArchivado(paciente: p, alDesarchivar: alDesarchivar),
                  ],
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _FilaArchivado extends StatelessWidget {
  const _FilaArchivado({required this.paciente, required this.alDesarchivar});

  final Paciente paciente;
  final Future<void> Function(Paciente) alDesarchivar;

  @override
  Widget build(BuildContext context) {
    final inicial = paciente.nombreCompleto.isNotEmpty
        ? paciente.nombreCompleto[0].toUpperCase()
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
                    paciente.nombreCompleto.isEmpty
                        ? 'Sin nombre'
                        : paciente.nombreCompleto,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Paleta.textoPrincipal,
                    ),
                  ),
                  if (paciente.diagnostico != null &&
                      paciente.diagnostico!.isNotEmpty)
                    Text(
                      paciente.diagnostico!,
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
              tooltip: 'Restaurar ${paciente.nombreCompleto}',
              icon: Icon(
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
