import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/compartido/estilos.dart';

class BotonCircular extends StatelessWidget {
  const BotonCircular({
    super.key,
    this.clave,
    required this.tooltip,
    required this.alTocar,
    required this.hijo,
    this.tamano = 48,
  });

  final Key? clave;
  final String tooltip;
  final VoidCallback alTocar;
  final Widget hijo;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        key: clave,
        onTap: alTocar,
        child: Container(
          width: tamano,
          height: tamano,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Paleta.doradoOscuro.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: hijo,
        ),
      ),
    );
  }
}

class CampoBusqueda extends StatelessWidget {
  const CampoBusqueda({
    super.key,
    required this.claveCampo,
    required this.claveBorrar,
    required this.controlador,
    required this.pista,
    required this.alCambiar,
    required this.mostrarBorrar,
  });

  final Key claveCampo;
  final Key claveBorrar;
  final TextEditingController controlador;
  final String pista;
  final ValueChanged<String> alCambiar;
  final bool mostrarBorrar;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: claveCampo,
      controller: controlador,
      autofocus: true,
      onChanged: alCambiar,
      style: GoogleFonts.nunito(fontSize: 14, color: Paleta.textoPrincipal),
      decoration:
          entradaDorada(
            hintText: pista,
            prefixIcon: const Icon(
              Icons.search,
              color: Paleta.textoSecundario,
              size: 20,
            ),
          ).copyWith(
            suffixIcon: mostrarBorrar
                ? GestureDetector(
                    key: claveBorrar,
                    onTap: () {
                      controlador.clear();
                      alCambiar('');
                    },
                    child: const Icon(
                      Icons.cancel_rounded,
                      color: Paleta.textoSecundario,
                      size: 18,
                    ),
                  )
                : null,
          ),
    );
  }
}
