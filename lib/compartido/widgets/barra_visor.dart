import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';

PreferredSizeWidget barraVisor({
  required String titulo,
  required VoidCallback alVolver,
  Key? claveVolver,
  List<Widget> acciones = const [],
  IconData iconoVolver = Icons.arrow_back_rounded,
  String ayudaVolver = 'Volver',
}) {
  final color = Paleta.sobreDorado;
  return AppBar(
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    foregroundColor: color,
    iconTheme: IconThemeData(color: color),
    actionsIconTheme: IconThemeData(color: color),
    systemOverlayStyle: SystemUiOverlayStyle.dark,
    flexibleSpace: SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: Paleta.degradadoCabecera),
      ),
    ),
    // Título a la izquierda, junto al botón de volver.
    centerTitle: false,
    titleSpacing: 0,
    leading: IconButton(
      key: claveVolver,
      tooltip: ayudaVolver,
      icon: Icon(iconoVolver),
      onPressed: alVolver,
    ),
    title: Text(
      titulo,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: color,
      ),
    ),
    actions: acciones,
  );
}
