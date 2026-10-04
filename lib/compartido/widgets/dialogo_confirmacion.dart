import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';

Future<bool?> mostrarDialogoConfirmacion(
  BuildContext context, {
  Key? key,
  required IconData icono,
  required String titulo,
  required String mensaje,
  required String textoConfirmar,
  Color? colorConfirmar,
  IconData? iconoConfirmar,
  Key? keyConfirmar,
  String textoCancelar = 'Cancelar',
}) {
  final color = colorConfirmar ?? Paleta.doradoRelleno;
  return showDialog<bool>(
    context: context,
    builder: (dialogCtx) => DialogoTarjeta(
      key: key,
      icono: icono,
      colores: [color, Color.lerp(color, Colors.black, 0.18)!],
      colorSombra: color,
      titulo: titulo,
      hijos: [
        const SizedBox(height: 8),
        Text(
          mensaje,
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 13.5,
            height: 1.45,
            color: Paleta.textoSecundario,
          ),
        ),
        const SizedBox(height: 22),
        BotonesDialogo(
          alCancelar: () => Navigator.of(dialogCtx).pop(false),
          textoCancelar: textoCancelar,
          alConfirmar: () => Navigator.of(dialogCtx).pop(true),
          textoConfirmar: textoConfirmar,
          colorConfirmar: color,
          iconoConfirmar: iconoConfirmar,
          keyConfirmar: keyConfirmar,
        ),
      ],
    ),
  );
}

class DialogoTarjeta extends StatelessWidget {
  const DialogoTarjeta({
    super.key,
    required this.icono,
    required this.colores,
    required this.colorSombra,
    required this.titulo,
    required this.hijos,
  });

  final IconData icono;
  final List<Color> colores;
  final Color colorSombra;
  final String titulo;
  final List<Widget> hijos;

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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colores,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: colorSombra.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icono, color: Colors.white, size: 28),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Paleta.textoPrincipal,
              ),
            ),
            ...hijos,
          ],
        ),
      ),
    );
  }
}

class BotonesDialogo extends StatelessWidget {
  const BotonesDialogo({
    super.key,
    required this.alCancelar,
    required this.alConfirmar,
    required this.textoConfirmar,
    this.textoCancelar = 'Cancelar',
    this.colorConfirmar,
    this.iconoConfirmar,
    this.keyConfirmar,
  });

  final VoidCallback alCancelar;
  final VoidCallback alConfirmar;
  final String textoConfirmar;
  final String textoCancelar;
  final Color? colorConfirmar;
  final IconData? iconoConfirmar;
  final Key? keyConfirmar;

  @override
  Widget build(BuildContext context) {
    final textoBoton = GoogleFonts.nunito(
      fontSize: 14,
      fontWeight: FontWeight.w700,
    );
    final estiloConfirmar = ElevatedButton.styleFrom(
      backgroundColor: colorConfirmar ?? Paleta.doradoRelleno,
      foregroundColor: Colors.white,
      elevation: 0,
      minimumSize: const Size(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: textoBoton,
    );
    final icono = iconoConfirmar;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: alCancelar,
            style: OutlinedButton.styleFrom(
              foregroundColor: Paleta.textoSecundario,
              side: BorderSide(color: Paleta.bordeTarjeta),
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: textoBoton,
            ),
            child: Text(textoCancelar),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: icono == null
              ? ElevatedButton(
                  key: keyConfirmar,
                  onPressed: alConfirmar,
                  style: estiloConfirmar,
                  child: Text(textoConfirmar),
                )
              : ElevatedButton.icon(
                  onPressed: alConfirmar,
                  icon: Icon(icono, size: 18),
                  label: Text(textoConfirmar),
                  style: estiloConfirmar,
                ),
        ),
      ],
    );
  }
}
