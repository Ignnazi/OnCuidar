import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oncuidar/nucleo/almacen/almacen_secreto.dart';
import 'package:oncuidar/nucleo/almacen/almacen_secreto_seguro.dart';
import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';
import 'package:oncuidar/nucleo/conectividad/servicio_conectividad.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
import 'package:oncuidar/nucleo/notificaciones/servicio_notificaciones.dart';
import 'package:oncuidar/nucleo/red/cliente_api.dart';
import 'package:oncuidar/nucleo/red/config_api.dart';
import 'package:oncuidar/nucleo/sesion/servicio_sesion.dart';
import 'package:oncuidar/nucleo/sincronizacion/cola_escrituras.dart';
import 'package:oncuidar/nucleo/sincronizacion/orquestador_sincronizacion.dart';

final almacenSecretoProvider = Provider<AlmacenSecreto>((ref) {
  return const AlmacenSecretoSeguro();
});

final Provider<ClienteApi> clienteApiProvider = Provider<ClienteApi>((ref) {
  final api = ClienteApi(
    urlBase: ConfigApi.urlBase,
    obtenerToken: () => ref.read(servicioSesionProvider).token,
  );
  ref.onDispose(api.cerrar);
  return api;
});

final Provider<ServicioSesion> servicioSesionProvider =
    Provider<ServicioSesion>((ref) {
      final sesion = ServicioSesion(
        api: ref.watch(clienteApiProvider),
        almacen: ref.watch(almacenSecretoProvider),
      );
      unawaited(sesion.inicializar());
      ref.onDispose(sesion.dispose);
      return sesion;
    });

final servicioCifradoProvider = Provider<ServicioCifrado>((ref) {
  return ServicioCifrado(
    api: ref.watch(clienteApiProvider),
    almacen: ref.watch(almacenSecretoProvider),
  );
});

final estadoAutenticacionProvider = StreamProvider<SesionUsuario?>((ref) {
  return ref.watch(servicioSesionProvider).cambios;
});

final uidSesionProvider = Provider<String?>((ref) {
  final auth = ref.watch(estadoAutenticacionProvider);
  if (auth.hasValue) return auth.value?.uid;
  return ref.read(servicioSesionProvider).actual?.uid;
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
    api: ref.watch(clienteApiProvider),
    sesion: ref.watch(servicioSesionProvider),
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
    uidActual: () => ref.read(servicioSesionProvider).actual?.uid,
  )..iniciar();
  ref.onDispose(orquestador.dispose);
  return orquestador;
});

final servicioNotificacionesProvider = Provider<ServicioNotificaciones>((ref) {
  final notificaciones = ServicioNotificaciones();
  unawaited(notificaciones.inicializar().catchError((_) {}));
  return notificaciones;
});
