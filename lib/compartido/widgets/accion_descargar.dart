import 'package:flutter/material.dart';

Future<void> descargarConAviso(
  BuildContext context,
  Future<bool> Function() descargar,
) async {
  final aviso = ScaffoldMessenger.of(context);
  final guardado = await descargar();
  aviso.showSnackBar(
    SnackBar(
      content: Text(
        guardado
            ? 'Archivo guardado en tu teléfono'
            : 'No se guardó el archivo',
      ),
    ),
  );
}
