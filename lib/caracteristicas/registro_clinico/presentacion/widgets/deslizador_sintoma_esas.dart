import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';

class EsasSymptomSlider extends StatelessWidget {
  const EsasSymptomSlider({
    super.key,
    required this.titulo,
    required this.etiqueta0,
    required this.etiqueta10,
    required this.valor,
    required this.color,
    required this.onChanged,
    this.accionDerecha,
    this.accesorioCabecera,
    this.mostrarLinea = true,
  });

  final String titulo;
  final String etiqueta0;
  final String etiqueta10;
  final int valor;
  final Color color;
  final ValueChanged<int> onChanged;
  final Widget? accionDerecha;
  final Widget? accesorioCabecera;
  final bool mostrarLinea;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                titulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Paleta.textoPrincipal,
                ),
              ),
            ),
            if (accesorioCabecera != null) ...[
              const SizedBox(width: 8),
              accesorioCabecera!,
            ],
            if (accionDerecha != null) ...[
              const SizedBox(width: 8),
              accionDerecha!,
            ],
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            activeTrackColor: color,
            inactiveTrackColor: color.withValues(alpha: 0.15),
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.15),
            tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 3),
            activeTickMarkColor: Colors.white,
            inactiveTickMarkColor: Colors.white,
            showValueIndicator: ShowValueIndicator.never,
          ),
          child: Slider(
            value: valor.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            onChanged: (nuevo) => onChanged(nuevo.round()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              for (var i = 0; i <= 10; i++)
                Expanded(
                  child: Text(
                    '$i',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: i == valor ? color : Paleta.textoSecundario,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (etiqueta0.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    etiqueta0,
                    textAlign: TextAlign.left,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 10.5,
                      height: 1.25,
                      color: Paleta.textoSecundario,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    etiqueta10,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 10.5,
                      height: 1.25,
                      color: Paleta.textoSecundario,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (mostrarLinea)
          Divider(height: 18, thickness: 1, color: Paleta.bordeTarjeta),
      ],
    );
  }
}
