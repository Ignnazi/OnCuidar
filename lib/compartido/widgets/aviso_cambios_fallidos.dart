import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/compartido/widgets/dialogo_confirmacion.dart';
import 'package:oncuidar/nucleo/proveedores.dart';

String textoCambiosFallidos(int fallidas) => fallidas == 1
    ? '1 cambio no se pudo guardar'
    : '$fallidas cambios no se pudieron guardar';

String textoDescartarFallidas(int fallidas) => fallidas == 1
    ? 'Se borrará 1 cambio que no se pudo guardar. Esto no se puede deshacer.'
    : 'Se borrarán $fallidas cambios que no se pudieron guardar. '
          'Esto no se puede deshacer.';

// No se oculta solo para que nada se pierda sin aviso
class AvisoCambiosFallidos extends ConsumerWidget {
  const AvisoCambiosFallidos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fallidas = ref.watch(resumenColaProvider).value?.fallidas ?? 0;
    final uid = ref.watch(estadoAutenticacionProvider).value?.uid;
    if (fallidas == 0 || uid == null) return const SizedBox.shrink();
    final cola = ref.read(colaEscriturasProvider);
    final estiloBoton = TextButton.styleFrom(
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      minimumSize: const Size(0, 36),
      textStyle: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800),
    );
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('aviso_cambios_fallidos'),
        width: double.infinity,
        color: Paleta.error,
        padding: const EdgeInsets.only(left: 16, right: 6, top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.sync_problem_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    textoCambiosFallidos(fallidas),
                    style: GoogleFonts.nunito(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            Wrap(
              alignment: WrapAlignment.end,
              children: [
                TextButton(
                  style: estiloBoton,
                  onPressed: () => cola.reintentarFallidas(uid),
                  child: const Text('Reintentar'),
                ),
                TextButton(
                  style: estiloBoton,
                  onPressed: () async {
                    final confirmar = await mostrarDialogoConfirmacion(
                      context,
                      icono: Icons.delete_outline_rounded,
                      titulo: 'Descartar cambios',
                      mensaje: textoDescartarFallidas(fallidas),
                      textoConfirmar: 'Descartar',
                      colorConfirmar: Paleta.error,
                      iconoConfirmar: Icons.delete_outline_rounded,
                      keyConfirmar: const Key('confirmar_descartar_fallidas'),
                    );
                    if (confirmar == true) await cola.descartarFallidas(uid);
                  },
                  child: const Text('Descartar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
