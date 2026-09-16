import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/catalogos/catalogo_sintomas.dart';
import '../../../core/tema/paleta.dart';
import 'fila_intensidad_sintoma.dart';
import 'selector_multi_sintoma.dart';
import 'titulo_seccion.dart';

class SeccionSintomas extends StatelessWidget {
  const SeccionSintomas({
    super.key,
    required this.seleccionados,
    required this.catalogoPorNombre,
    required this.intensidades,
    required this.otroController,
    required this.onAlternar,
    required this.onIntensidad,
    required this.onCambioOtro,
  });

  final Set<String> seleccionados;
  final Map<String, SintomaSeleccionable> catalogoPorNombre;
  final Map<String, int> intensidades;
  final TextEditingController otroController;
  final ValueChanged<String> onAlternar;
  final void Function(String nombre, int valor) onIntensidad;
  final VoidCallback onCambioOtro;

  Future<void> _abrirSelector(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Paleta.tarjeta,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AnimatedPadding(
        duration: Duration.zero,
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: SizedBox(
          height: MediaQuery.sizeOf(ctx).height * 0.9,
          child: SelectorMultiSintoma(
            seleccionados: seleccionados,
            onAlternar: onAlternar,
            onCerrar: () => Navigator.of(ctx).pop(),
          ),
        ),
      ),
    );
  }

  Widget _campoSelectorSintomas(BuildContext context) {
    final vacio = seleccionados.isEmpty;
    return Material(
      color: Paleta.fondoEntrada,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: const Key('campoSelectorSintomas'),
        onTap: () => _abrirSelector(context),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Paleta.bordeTarjeta, width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  vacio
                      ? 'Selecciona los síntomas…'
                      : '${seleccionados.length} seleccionados',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: vacio ? FontWeight.w400 : FontWeight.w800,
                    color: vacio
                        ? Paleta.textoSecundario
                        : Paleta.doradoOscuro,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_drop_down,
                size: 26,
                color: Paleta.doradoOscuro,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filasIntensidad = catalogoUnificado
        .where((item) => seleccionados.contains(item.nombre))
        .map((item) => item.nombre)
        .toList();
    for (final nombre in seleccionados) {
      if (!catalogoPorNombre.containsKey(nombre)) {
        filasIntensidad.add(nombre);
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TituloSeccion('Síntomas observados', icono: Icons.healing_rounded),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Paleta.tarjeta,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Paleta.doradoClaro),
            boxShadow: [
              BoxShadow(
                color: Paleta.doradoOscuro.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Evaluación de síntomas (ESAS-r)',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Paleta.doradoOscuro,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Selecciona los síntomas que presenta el paciente ahora:',
                style: GoogleFonts.nunito(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Paleta.textoSecundario,
                ),
              ),
              const SizedBox(height: 10),
              _campoSelectorSintomas(context),
              if (seleccionados.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(
                    'Selecciona un síntoma para evaluar su intensidad.',
                    style: GoogleFonts.nunito(
                      fontSize: 12.5,
                      color: Paleta.textoSecundario,
                    ),
                  ),
                )
              else ...[
                const SizedBox(height: 16),
                Divider(color: Paleta.doradoClaro, height: 20),
                const SizedBox(height: 8),
                Text(
                  'Intensidad de cada síntoma:',
                  style: GoogleFonts.nunito(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Paleta.doradoOscuro,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Desliza para marcar del 0 (nada) al 10 (máximo).',
                  style: GoogleFonts.nunito(
                    fontSize: 11.5,
                    color: Paleta.textoSecundario,
                  ),
                ),
                const SizedBox(height: 8),
                for (final nombre in filasIntensidad)
                  FilaIntensidadSintoma(
                    nombre: nombre,
                    etiqueta0: catalogoPorNombre[nombre]?.etiqueta0 ?? '',
                    etiqueta10: catalogoPorNombre[nombre]?.etiqueta10 ?? '',
                    valor: intensidades[nombre] ?? 0,
                    esOtro: nombre == 'Otro problema',
                    onIntensidad: (v) => onIntensidad(nombre, v),
                    onEliminar: () => onAlternar(nombre),
                    otroController: nombre == 'Otro problema'
                        ? otroController
                        : null,
                    onCambioOtro: nombre == 'Otro problema'
                        ? onCambioOtro
                        : null,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}