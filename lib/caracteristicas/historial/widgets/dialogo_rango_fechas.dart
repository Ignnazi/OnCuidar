import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/tema/paleta.dart';
import '../../../core/util/formato_fecha.dart';

Future<({DateTime? inicio, DateTime? fin})?> mostrarDialogoRangoFechas(
  BuildContext context, {
  DateTime? fechaInicio,
  DateTime? fechaFin,
}) {
  return showDialog<({DateTime? inicio, DateTime? fin})>(
    context: context,
    builder: (_) =>
        _DialogoRangoFechas(fechaInicio: fechaInicio, fechaFin: fechaFin),
  );
}

class _DialogoRangoFechas extends StatefulWidget {
  const _DialogoRangoFechas({this.fechaInicio, this.fechaFin});

  final DateTime? fechaInicio;
  final DateTime? fechaFin;

  @override
  State<_DialogoRangoFechas> createState() => _DialogoRangoFechasState();
}

class _DialogoRangoFechasState extends State<_DialogoRangoFechas> {
  late final TextEditingController _desdeController;
  late final TextEditingController _hastaController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _desdeController = TextEditingController(
      text: widget.fechaInicio == null ? '' : fechaEntrada(widget.fechaInicio!),
    );
    _hastaController = TextEditingController(
      text: widget.fechaFin == null ? '' : fechaEntrada(widget.fechaFin!),
    );
  }

  @override
  void dispose() {
    _desdeController.dispose();
    _hastaController.dispose();
    super.dispose();
  }

  void _aplicar() {
    final desde = parsearFechaEntrada(_desdeController.text);
    final hasta = parsearFechaEntrada(_hastaController.text);
    if (_desdeController.text.trim().isNotEmpty && desde == null) {
      setState(() {
        _error = 'La fecha "Desde" no es válida. Usa el formato DD/MM/AAAA.';
      });
      return;
    }
    if (_hastaController.text.trim().isNotEmpty && hasta == null) {
      setState(() {
        _error = 'La fecha "Hasta" no es válida. Usa el formato DD/MM/AAAA.';
      });
      return;
    }
    Navigator.of(context).pop((inicio: desde, fin: hasta));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Paleta.tarjeta,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Paleta.doradoMedio, Paleta.doradoOscuro],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Paleta.doradoOscuro.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.date_range_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Filtrar por fecha',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Paleta.textoPrincipal,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Escribe la fecha y las barras se agregan solas '
              '(DD/MM/AAAA). Deja vacío para no limitar.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 12.5,
                height: 1.4,
                color: Paleta.textoSecundario,
              ),
            ),
            const SizedBox(height: 18),
            _CampoFechaDialogo(
              keyDialogo: const Key('campoFechaDesde'),
              etiqueta: 'Desde',
              controlador: _desdeController,
              alCambiar: (texto) => setState(() {
                aplicarMascaraFecha(_desdeController, texto);
              }),
            ),
            const SizedBox(height: 12),
            _CampoFechaDialogo(
              keyDialogo: const Key('campoFechaHasta'),
              etiqueta: 'Hasta',
              controlador: _hastaController,
              alCambiar: (texto) => setState(() {
                aplicarMascaraFecha(_hastaController, texto);
              }),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Paleta.error,
                ),
              ),
            ],
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Paleta.textoSecundario,
                      side: const BorderSide(color: Paleta.bordeTarjeta),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _aplicar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Paleta.doradoOscuro,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CampoFechaDialogo extends StatelessWidget {
  const _CampoFechaDialogo({
    required this.keyDialogo,
    required this.etiqueta,
    required this.controlador,
    required this.alCambiar,
  });

  final Key keyDialogo;
  final String etiqueta;
  final TextEditingController controlador;
  final ValueChanged<String> alCambiar;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: keyDialogo,
      controller: controlador,
      keyboardType: TextInputType.number,
      maxLength: 10,
      onChanged: alCambiar,
      style: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Paleta.textoPrincipal,
      ),
      decoration: InputDecoration(
        labelText: etiqueta,
        labelStyle: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Paleta.doradoOscuro,
        ),
        hintText: 'DD/MM/AAAA',
        hintStyle: GoogleFonts.nunito(fontSize: 13, color: Paleta.textoAyuda),
        counterText: '',
        prefixIcon: Icon(
          Icons.calendar_today_outlined,
          size: 18,
          color: Paleta.doradoOscuro,
        ),
        filled: true,
        fillColor: Paleta.fondoEntrada,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Paleta.bordeTarjeta),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Paleta.bordeTarjeta),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Paleta.doradoPrincipal,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
