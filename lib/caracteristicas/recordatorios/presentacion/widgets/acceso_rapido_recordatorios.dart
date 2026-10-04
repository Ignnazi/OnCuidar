import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/recordatorios/presentacion/formato_recordatorio.dart';

class AccesoRapidoRecordatorios extends StatelessWidget {
  const AccesoRapidoRecordatorios({super.key, required this.alElegirTipo});

  final ValueChanged<String> alElegirTipo;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (tipo, etiqueta) in const [
          ('medicamento', 'Medicamento'),
          ('medicion', 'Medición'),
          ('cita', 'Cita médica'),
        ])
          _botonConEtiqueta(tipo, etiqueta),
        _botonSoloIcono(),
      ],
    );
  }

  Widget _botonSoloIcono() {
    return GestureDetector(
      key: const Key('tarjetaRapida_otro'),
      onTap: () => alElegirTipo('otro'),
      child: Container(
        width: 36,
        height: 35,
        decoration: BoxDecoration(
          color: Paleta.doradoClaro,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Paleta.doradoPrincipal.withValues(alpha: 0.30),
          ),
        ),
        child: Icon(Icons.add, size: 18, color: Paleta.doradoPrincipal),
      ),
    );
  }

  Widget _botonConEtiqueta(String tipo, String etiqueta) {
    final (:icono, :color) = estiloTipoRecordatorio(tipo);
    return GestureDetector(
      key: Key('tarjetaRapida_$tipo'),
      onTap: () => alElegirTipo(tipo),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Paleta.tarjeta,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Paleta.doradoPrincipal.withValues(alpha: 0.20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              etiqueta,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Paleta.textoPrincipal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
