import 'package:flutter/material.dart';
import 'package:oncuidar/compartido/widgets/aviso_app.dart';

Future<void> descargarConAviso(
  BuildContext context,
  Future<bool> Function() descargar,
) async {
  final guardado = await descargar();
  if (!context.mounted) return;
  if (guardado) {
    AvisoApp.info(context, 'El archivo se guardó en tu teléfono.');
  } else {
    AvisoApp.alerta(context, 'No se pudo guardar el archivo.');
  }
}
