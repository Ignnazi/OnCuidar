import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';

class HojaDialogo extends StatelessWidget {
  const HojaDialogo({
    super.key,
    required this.icono,
    required this.titulo,
    required this.tamanoInicial,
    required this.tamanoMinimo,
    required this.tamanoMaximo,
    required this.cuerpo,
    this.tamanoTitulo = 17,
  });

  final IconData icono;
  final String titulo;
  final double tamanoInicial;
  final double tamanoMinimo;
  final double tamanoMaximo;
  final double tamanoTitulo;

  final List<Widget> Function(BuildContext ctx, ScrollController controlador)
  cuerpo;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: tamanoInicial,
      minChildSize: tamanoMinimo,
      maxChildSize: tamanoMaximo,
      builder: (ctx, controlador) => Container(
        decoration: BoxDecoration(
          color: Paleta.tarjeta,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Paleta.bordeTarjeta,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Paleta.doradoPrincipal, Paleta.doradoRelleno],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icono, color: Paleta.sobreDorado, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      titulo,
                      style: GoogleFonts.nunito(
                        fontSize: tamanoTitulo,
                        fontWeight: FontWeight.w800,
                        color: Paleta.textoPrincipal,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: Icon(Icons.close, color: Paleta.textoSecundario),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            ...cuerpo(ctx, controlador),
          ],
        ),
      ),
    );
  }
}

class FormularioDeHoja extends StatelessWidget {
  const FormularioDeHoja({
    super.key,
    required this.formKey,
    required this.controlador,
    required this.hijos,
    this.margenSuperior = 8,
  });

  final GlobalKey<FormState> formKey;
  final ScrollController controlador;
  final List<Widget> hijos;
  final double margenSuperior;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Form(
        key: formKey,
        child: ListView(
          controller: controlador,
          padding: EdgeInsets.fromLTRB(
            20,
            margenSuperior,
            20,
            24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          children: hijos,
        ),
      ),
    );
  }
}
