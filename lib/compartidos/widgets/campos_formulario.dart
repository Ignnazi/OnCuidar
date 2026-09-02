import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/tema/paleta.dart';

class TarjetaSeccion extends StatelessWidget {
  const TarjetaSeccion({
    super.key,
    required this.icono,
    required this.titulo,
    required this.hijos,
  });

  final IconData icono;
  final String titulo;
  final List<Widget> hijos;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Paleta.tarjeta,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Paleta.bordeTarjeta),
        boxShadow: [
          BoxShadow(
            color: Paleta.doradoOscuro.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Franja de acento dorado
          Container(
            height: 4,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Paleta.doradoOscuro,
                  Paleta.doradoPrincipal,
                  Paleta.doradoClaro,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Paleta.doradoPrincipal,
                            Paleta.doradoOscuro,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Paleta.doradoOscuro.withValues(alpha: 0.28),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(icono, color: Colors.white, size: 21),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      titulo,
                      style: GoogleFonts.nunito(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Paleta.textoPrincipal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...hijos,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EtiquetaCampo extends StatelessWidget {
  const EtiquetaCampo({super.key, required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: GoogleFonts.nunito(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Paleta.textoTerciario,
        letterSpacing: 0.2,
      ),
    );
  }
}

class CampoFormulario extends StatelessWidget {
  const CampoFormulario({
    super.key,
    required this.controlador,
    required this.textoAyuda,
    required this.icono,
    this.tipoTeclado,
    this.accionTeclado,
    this.oculto = false,
    this.iconoSufijo,
    this.alEnviar,
    this.validador,
  });

  final TextEditingController controlador;
  final String textoAyuda;
  final IconData icono;
  final TextInputType? tipoTeclado;
  final TextInputAction? accionTeclado;
  final bool oculto;
  final Widget? iconoSufijo;
  final ValueChanged<String>? alEnviar;
  final String? Function(String?)? validador;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controlador,
      obscureText: oculto,
      keyboardType: tipoTeclado,
      textInputAction: accionTeclado,
      onFieldSubmitted: alEnviar,
      validator: validador,
      style: GoogleFonts.nunito(fontSize: 14, color: Paleta.textoPrincipal),
      decoration: decoracionEntrada(
        textoAyuda: textoAyuda,
        icono: icono,
        iconoSufijo: iconoSufijo,
      ),
    );
  }
}

InputDecoration decoracionEntrada({
  required String textoAyuda,
  required IconData icono,
  Widget? iconoSufijo,
}) {
  return InputDecoration(
    hintText: textoAyuda,
    hintStyle: GoogleFonts.nunito(color: Paleta.textoAyuda, fontSize: 14),
    prefixIcon: Icon(icono, size: 20, color: Paleta.doradoOscuro),
    suffixIcon: iconoSufijo,
    filled: true,
    fillColor: Paleta.fondoEntrada,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Paleta.bordeTarjeta),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Paleta.bordeTarjeta),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Paleta.doradoPrincipal, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Paleta.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Paleta.error, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}