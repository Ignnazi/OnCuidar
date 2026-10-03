import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';
import 'package:oncuidar/nucleo/conectividad/servicio_conectividad.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
import 'package:oncuidar/nucleo/notificaciones/servicio_notificaciones.dart';
import 'package:oncuidar/nucleo/sincronizacion/cola_escrituras.dart';
import 'package:oncuidar/nucleo/sincronizacion/orquestador_sincronizacion.dart';

final servicioCifradoProvider = Provider<ServicioCifrado>((ref) {
  return ServicioCifrado();
});

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final estadoAutenticacionProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final uidSesionProvider = Provider<String?>((ref) {
  final auth = ref.watch(estadoAutenticacionProvider);
  if (auth.hasValue) return auth.value?.uid;
  try {
    return ref.read(firebaseAuthProvider).currentUser?.uid;
  } catch (_) {
    return null;
  }
});

class BloqueoCifradoNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void fijarDesbloqueado(bool valor) => state = valor;
}

final bloqueoCifradoProvider = NotifierProvider<BloqueoCifradoNotifier, bool>(
  BloqueoCifradoNotifier.new,
);

final servicioConectividadProvider = Provider<ServicioConectividad>((ref) {
  return ServicioConectividad();
});

final estadoConexionProvider = StreamProvider<bool>((ref) async* {
  final conectividad = ref.watch(servicioConectividadProvider);
  yield await conectividad.estaEnLinea();
  yield* conectividad.enLinea().handleError((_) {});
});

final colaEscriturasProvider = Provider<ColaEscrituras>((ref) {
  return ColaEscrituras();
});

final baseDatosSeguraProvider = Provider<BaseDatosSegura>((ref) {
  return BaseDatosSegura(
    base: FirebaseFirestore.instance,
    auth: ref.watch(firebaseAuthProvider),
    cifrado: ref.watch(servicioCifradoProvider),
    cola: ref.watch(colaEscriturasProvider),
    conectividad: ref.watch(servicioConectividadProvider),
  );
});

final resumenColaProvider = StreamProvider.autoDispose<ResumenCola>((
  ref,
) async* {
  final uid = ref.watch(estadoAutenticacionProvider).value?.uid;
  if (uid == null) {
    yield ResumenCola.vacio;
    return;
  }
  final cola = ref.watch(colaEscriturasProvider);
  yield await cola.resumen(uid);
  await for (final uidCambiado in cola.cambios) {
    if (uidCambiado == uid) yield await cola.resumen(uid);
  }
});

final orquestadorSincronizacionProvider = Provider<OrquestadorSincronizacion>((
  ref,
) {
  final orquestador = OrquestadorSincronizacion(
    cola: ref.watch(colaEscriturasProvider),
    base: ref.watch(baseDatosSeguraProvider),
    conectividad: ref.watch(servicioConectividadProvider),
    uidActual: () => ref.read(firebaseAuthProvider).currentUser?.uid,
  )..iniciar();
  ref.onDispose(orquestador.dispose);
  return orquestador;
});

final servicioNotificacionesProvider = Provider<ServicioNotificaciones>((ref) {
  final notificaciones = ServicioNotificaciones();
  unawaited(notificaciones.inicializar().catchError((_) {}));
  return notificaciones;
});
