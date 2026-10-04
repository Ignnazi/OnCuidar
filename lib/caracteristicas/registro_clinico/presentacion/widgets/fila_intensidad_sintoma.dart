import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/presentacion/widgets/deslizador_sintoma_esas.dart';
import 'package:oncuidar/compartido/estilos.dart';

class FilaIntensidadSintoma extends StatelessWidget {
  const FilaIntensidadSintoma({
    super.key,
    required this.nombre,
    required this.etiqueta0,
    required this.etiqueta10,
    required this.valor,
    required this.onIntensidad,
    required this.onEliminar,
    required this.esOtro,
    this.otroController,
    this.onCambioOtro,
  });

  final String nombre;
  final String etiqueta0;
  final String etiqueta10;
  final int valor;
  final ValueChanged<int> onIntensidad;
  final VoidCallback onEliminar;
  final bool esOtro;

  /// Controlador del campo de notas
  final TextEditingController? otroController;
  final VoidCallback? onCambioOtro;

  Widget _badgeIntensidad(int valor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Paleta.doradoClaro,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Paleta.doradoPrincipal.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            EntradaSintoma.iconoPara(valor),
            size: 15,
            color: EntradaSintoma.colorPara(valor),
          ),
          const SizedBox(width: 3),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 92),
              child: Text(
                EntradaSintoma.etiquetaPara(valor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Paleta.doradoOscuro,
                ),
              ),
            ),
          ),
          const SizedBox(width: 3),
          Text(
            '$valor/10',
            style: GoogleFonts.nunito(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Paleta.textoPrincipal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EsasSymptomSlider(
          titulo: nombre,
          etiqueta0: etiqueta0,
          etiqueta10: etiqueta10,
          valor: valor,
          color: EntradaSintoma.colorPara(valor),
          onChanged: onIntensidad,
          accionDerecha: IconButton(
            onPressed: onEliminar,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.close_rounded,
              size: 18,
              color: Paleta.textoSecundario,
            ),
          ),
          accesorioCabecera: _badgeIntensidad(valor),
          mostrarLinea: true,
        ),
        if (esOtro) ...[
          const SizedBox(height: 2),
          TextField(
            controller: otroController,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => onCambioOtro?.call(),
            style: GoogleFonts.nunito(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Paleta.textoPrincipal,
            ),
            decoration: entradaDorada(
              hintText: 'Describe el problema (por ej: sequedad de boca)',
              hintStyle: GoogleFonts.nunito(
                fontSize: 13,
                color: Paleta.textoAyuda,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
