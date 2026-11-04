import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';

enum TonoAviso { info, alerta, conexion }

@immutable
class DatosAviso {
  const DatosAviso({required this.mensaje, required this.tono, this.icono});

  final String mensaje;
  final TonoAviso tono;
  final IconData? icono;

  Duration get visibleDurante {
    final base = switch (tono) {
      TonoAviso.alerta => 3800,
      TonoAviso.conexion => 4000,
      _ => 2600,
    };
    final extra = (mensaje.length - 40).clamp(0, 120) * 35;
    return Duration(milliseconds: base + extra);
  }
}

class AvisoApp {
  AvisoApp._();

  static const duracion = Duration(milliseconds: 2600);

  static ScaffoldMessengerState? _mensajero;
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _actual;

  static void info(BuildContext context, String mensaje, {IconData? icono}) =>
      _mostrar(
        context,
        DatosAviso(mensaje: mensaje, tono: TonoAviso.info, icono: icono),
      );

  static void alerta(BuildContext context, String mensaje, {IconData? icono}) =>
      _mostrar(
        context,
        DatosAviso(mensaje: mensaje, tono: TonoAviso.alerta, icono: icono),
      );

  static void conexion(
    BuildContext context,
    String mensaje, {
    IconData? icono,
  }) => _mostrar(
    context,
    DatosAviso(mensaje: mensaje, tono: TonoAviso.conexion, icono: icono),
  );

  static AvisoCapturado capturar(BuildContext context) =>
      AvisoCapturado._(ScaffoldMessenger.maybeOf(context));

  static void ocultar() {
    final mensajero = _mensajero;
    if (mensajero != null && mensajero.mounted) {
      mensajero.removeCurrentSnackBar();
    }
    _actual = null;
  }

  static void _mostrar(BuildContext context, DatosAviso datos) {
    final mensajero = ScaffoldMessenger.maybeOf(context);
    if (mensajero == null) return;
    _mostrarEn(mensajero, datos);
  }

  static void _mostrarEn(ScaffoldMessengerState mensajero, DatosAviso datos) {
    final reemplaza = _actual != null && identical(_mensajero, mensajero);
    mensajero.removeCurrentSnackBar();
    _mensajero = mensajero;
    final controlador = mensajero.showSnackBar(
      _construir(datos),
      snackBarAnimationStyle: reemplaza ? AnimationStyle.noAnimation : null,
    );
    _actual = controlador;
    controlador.closed.then((_) {
      if (identical(_actual, controlador)) _actual = null;
    });
  }

  static SnackBar _construir(DatosAviso datos) {
    final duracion = datos.visibleDurante;
    if (datos.tono == TonoAviso.conexion) {
      return SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: duracion,
        backgroundColor: Paleta.doradoBannerOscuro,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Semantics(
          liveRegion: true,
          child: Row(
            children: [
              Icon(
                datos.icono ?? Icons.cloud_off_rounded,
                size: 20,
                color: Paleta.textoTerciario,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  datos.mensaje,
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
      );
    }
    final fondo = switch (datos.tono) {
      TonoAviso.alerta => Paleta.error,
      _ => Paleta.doradoPrincipal,
    };
    if (datos.icono != null) {
      return SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: duracion,
        backgroundColor: fondo,
        content: Row(
          children: [
            Icon(datos.icono, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                datos.mensaje,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return SnackBar(
      duration: duracion,
      backgroundColor: fondo,
      content: Text(datos.mensaje, style: const TextStyle(color: Colors.white)),
    );
  }
}

class AvisoCapturado {
  const AvisoCapturado._(this._mensajero);

  final ScaffoldMessengerState? _mensajero;

  void info(String mensaje, {IconData? icono}) => _mostrar(
    DatosAviso(mensaje: mensaje, tono: TonoAviso.info, icono: icono),
  );

  void alerta(String mensaje, {IconData? icono}) => _mostrar(
    DatosAviso(mensaje: mensaje, tono: TonoAviso.alerta, icono: icono),
  );

  void _mostrar(DatosAviso datos) {
    final mensajero = _mensajero;
    if (mensajero == null || !mensajero.mounted) return;
    AvisoApp._mostrarEn(mensajero, datos);
  }
}
