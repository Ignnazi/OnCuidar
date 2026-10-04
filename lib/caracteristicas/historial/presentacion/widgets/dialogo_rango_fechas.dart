import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/compartido/widgets/dialogo_confirmacion.dart';
import 'package:oncuidar/nucleo/utilidades/formato_fecha.dart';

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
    return DialogoTarjeta(
      icono: Icons.date_range_rounded,
      colores: [Paleta.doradoMedio, Paleta.doradoRelleno],
      colorSombra: Paleta.doradoOscuro,
      titulo: 'Filtrar por fecha',
      hijos: [
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
        BotonesDialogo(
          alCancelar: () => Navigator.of(context).pop(),
          alConfirmar: _aplicar,
          textoConfirmar: 'Aplicar',
        ),
      ],
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
          borderSide: BorderSide(color: Paleta.bordeTarjeta),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Paleta.bordeTarjeta),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Paleta.doradoPrincipal, width: 1.5),
        ),
      ),
    );
  }
}

void aplicarMascaraFecha(TextEditingController controlador, String texto) {
  final digitos = texto.replaceAll(RegExp(r'\D'), '');
  final buffer = StringBuffer();
  for (var i = 0; i < digitos.length && i < 8; i++) {
    if (i == 2 || i == 4) buffer.write('/');
    buffer.write(digitos[i]);
  }
  final formateado = buffer.toString();
  if (formateado == controlador.text) return;
  controlador.value = TextEditingValue(
    text: formateado,
    selection: TextSelection.collapsed(offset: formateado.length),
  );
}
