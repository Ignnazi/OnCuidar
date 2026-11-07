import 'dart:async';

import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
import 'package:oncuidar/nucleo/notificaciones/silencio_avisos.dart';
import 'package:oncuidar/nucleo/sesion/servicio_sesion.dart';

// Todo cierre de sesión pasa por aquí, la cola se conserva
StreamSubscription<SesionUsuario?> escucharSesion(
  Stream<SesionUsuario?> cambios, {
  required ServicioCifrado Function() cifrado,
  required BaseDatosSegura Function() base,
  required void Function() alEntrar,
  required void Function() alSalir,
}) {
  var sesionPrevia = false;
  String? uidPrevio;
  return cambios.listen((usuario) {
    SilencioAvisos.usuario = usuario?.uid;
    if (usuario == null) {
      if (!sesionPrevia) return;
      alSalir();
      final uid = uidPrevio;
      uidPrevio = null;
      if (uid != null) unawaited(_limpiar(uid, cifrado(), base()));
    } else {
      sesionPrevia = true;
      uidPrevio = usuario.uid;
      alEntrar();
    }
  });
}

Future<void> _limpiar(
  String uid,
  ServicioCifrado cifrado,
  BaseDatosSegura base,
) async {
  try {
    await cifrado.olvidarClave(uid);
    await base.borrarCacheLocal(uid);
  } catch (_) {
    // Si falla, se sigue igual.
  }
}
