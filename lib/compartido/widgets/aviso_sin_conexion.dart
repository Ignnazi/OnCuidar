import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/nucleo/proveedores.dart';

class TextosSinConexion {
  const TextosSinConexion._();

  static const correos =
      'Sin conexión: no puedes cambiar el correo principal ni el de respaldo hasta que vuelvas a conectarte.';
  static const verificacion =
      'Sin conexión: no puedes reenviar el enlace hasta que vuelvas a conectarte.';
  static const iniciarSesion =
      'Sin conexión: necesitas internet para iniciar sesión.';
  static const cerrarSesion =
      'Estás sin conexión. Para volver a iniciar sesión necesitarás internet.';
  static const video =
      'Este video aún no está guardado en tu teléfono. Conéctate a internet para verlo.';

  static const archivo =
      'Este archivo aún no está guardado en tu teléfono. Conéctate a internet para verlo.';

  static String necesitaInternetPara(String accion) =>
      'Sin conexión: necesitas internet para $accion.';
}

bool estaSinConexion(WidgetRef ref) =>
    ref.read(estadoConexionProvider).value == false;

/// Aviso flotante breve con ícono de nube tachada.
void mostrarAvisoSinConexion(BuildContext context, String mensaje) {
  final mensajero = ScaffoldMessenger.of(context);
  mensajero.hideCurrentSnackBar();
  mensajero.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
      backgroundColor: Paleta.doradoBannerOscuro,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      content: Semantics(
        liveRegion: true,
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 20,
              color: Paleta.textoTerciario,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                mensaje,
                style: GoogleFonts.nunito(
                  fontSize: 13.5,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  color: Paleta.textoTerciario,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class NotaSinConexion extends ConsumerWidget {
  const NotaSinConexion({
    super.key,
    required this.texto,
    this.alineacion = TextAlign.start,
    this.margen = const EdgeInsets.only(bottom: 12),
  });

  final String texto;
  final TextAlign alineacion;
  final EdgeInsets margen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sinConexion = ref.watch(estadoConexionProvider).value == false;
    if (!sinConexion) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: margen,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 16,
                color: Paleta.textoSecundario,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                texto,
                textAlign: alineacion,
                style: GoogleFonts.nunito(
                  fontSize: 12.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: Paleta.textoSecundario,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
