import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/autenticacion/dominio/validaciones_registro.dart';
import 'package:oncuidar/compartido/widgets/campos_formulario.dart';
import 'package:oncuidar/nucleo/utilidades/rut.dart';

/// Campo de texto con su etiqueta encima.
class CampoEtiquetado extends StatelessWidget {
  const CampoEtiquetado({
    super.key,
    required this.etiqueta,
    required this.controlador,
    required this.textoAyuda,
    required this.icono,
    this.tipoTeclado,
    this.accionTeclado,
    this.oculto = false,
    this.iconoSufijo,
    this.validador,
  });

  final String etiqueta;
  final TextEditingController controlador;
  final String textoAyuda;
  final IconData icono;
  final TextInputType? tipoTeclado;
  final TextInputAction? accionTeclado;
  final bool oculto;
  final Widget? iconoSufijo;
  final String? Function(String?)? validador;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EtiquetaCampo(texto: etiqueta),
        const SizedBox(height: 8),
        CampoFormulario(
          controlador: controlador,
          textoAyuda: textoAyuda,
          icono: icono,
          tipoTeclado: tipoTeclado,
          accionTeclado: accionTeclado,
          oculto: oculto,
          iconoSufijo: iconoSufijo,
          validador: validador,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class DesplegableEtiquetado extends StatelessWidget {
  const DesplegableEtiquetado({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.opciones,
    required this.icono,
    required this.alCambiar,
    required this.mensajeValidacion,
  });

  final String etiqueta;
  final String? valor;
  final List<String> opciones;
  final IconData icono;
  final ValueChanged<String?> alCambiar;
  final String mensajeValidacion;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EtiquetaCampo(texto: etiqueta),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: valor,
          isExpanded: true,
          decoration: decoracionEntrada(
            textoAyuda: 'Seleccionar',
            icono: icono,
          ),
          items: opciones
              .map(
                (opcion) => DropdownMenuItem(
                  value: opcion,
                  child: Text(opcion, style: GoogleFonts.nunito(fontSize: 14)),
                ),
              )
              .toList(),
          onChanged: alCambiar,
          validator: (v) => v == null ? mensajeValidacion : null,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class CampoRut extends StatelessWidget {
  const CampoRut({super.key, required this.controlador});

  final TextEditingController controlador;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const EtiquetaCampo(texto: 'RUT del paciente'),
        const SizedBox(height: 8),
        TextFormField(
          controller: controlador,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9kK]')),
            LengthLimitingTextInputFormatter(9),
            TextInputFormatter.withFunction((valorAnterior, valorNuevo) {
              final formateado = formatearRut(valorNuevo.text);
              if (formateado == valorNuevo.text) return valorNuevo;
              return TextEditingValue(
                text: formateado,
                selection: TextSelection.collapsed(offset: formateado.length),
              );
            }),
          ],
          validator: validarRutPaciente,
          style: GoogleFonts.nunito(fontSize: 14, color: Paleta.textoPrincipal),
          decoration: decoracionEntrada(
            textoAyuda: '12.345.678-9',
            icono: Icons.badge_outlined,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class BotonVerContrasena extends StatelessWidget {
  const BotonVerContrasena({
    super.key,
    required this.oculta,
    required this.alPulsar,
  });

  final bool oculta;
  final VoidCallback alPulsar;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        oculta ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 20,
      ),
      onPressed: alPulsar,
    );
  }
}
