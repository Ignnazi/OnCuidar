import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Paleta.doradoClaro),
        boxShadow: [
          BoxShadow(
            color: Paleta.doradoOscuro.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Paleta.doradoOscuro,
                  Paleta.doradoPrincipal,
                  Paleta.doradoMedio,
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icono, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    titulo,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: hijos,
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
    this.alCambiar,
    this.validador,
    this.habilitado = true,
  });

  final TextEditingController controlador;
  final String textoAyuda;
  final IconData icono;
  final TextInputType? tipoTeclado;
  final TextInputAction? accionTeclado;
  final bool oculto;
  final Widget? iconoSufijo;
  final ValueChanged<String>? alEnviar;
  final ValueChanged<String>? alCambiar;
  final String? Function(String?)? validador;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controlador,
      obscureText: oculto,
      enabled: habilitado,
      keyboardType: tipoTeclado,
      textInputAction: accionTeclado,
      onFieldSubmitted: alEnviar,
      onChanged: alCambiar,
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
      borderSide: const BorderSide(color: Paleta.bordeTarjeta),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Paleta.bordeTarjeta),
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
