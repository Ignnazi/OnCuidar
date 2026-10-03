import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';

class BotonTipo extends StatelessWidget {
  const BotonTipo({
    super.key,
    required this.etiqueta,
    required this.activo,
    required this.habilitado,
    required this.alPulsar,
  });

  final String etiqueta;
  final bool activo;
  final bool habilitado;
  final VoidCallback alPulsar;

  static const _grisDeshabilitado = Color(0xFFEDE4D6);
  static const _bordeDeshabilitado = Color(0xFFE0D8C8);

  @override
  Widget build(BuildContext context) {
    final resaltado = habilitado && activo;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      height: 40,
      decoration: BoxDecoration(
        gradient: resaltado
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Paleta.doradoMedio, Paleta.doradoOscuro],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  if (!habilitado) _grisDeshabilitado else Paleta.tarjeta,
                  if (!habilitado) _grisDeshabilitado else Paleta.tarjeta,
                ],
              ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: !habilitado
              ? _bordeDeshabilitado
              : resaltado
              ? Colors.transparent
              : Paleta.doradoClaro,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Paleta.doradoOscuro.withValues(
              alpha: resaltado ? 0.30 : 0.0,
            ),
            blurRadius: resaltado ? 6 : 0,
            offset: Offset(0, resaltado ? 2 : 0),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: habilitado ? alPulsar : null,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                style: GoogleFonts.nunito(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: !habilitado
                      ? Paleta.textoSecundario
                      : resaltado
                      ? Colors.white
                      : Paleta.doradoOscuro,
                ),
                child: Text(
                  etiqueta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
