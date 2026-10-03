import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oncuidar/nucleo/conectividad/servicio_conectividad.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
import 'package:oncuidar/nucleo/sincronizacion/cola_escrituras.dart';

class OrquestadorSincronizacion {
  OrquestadorSincronizacion({
    required this._cola,
    required this._base,
    required this._conectividad,
    required this._uidActual,
    this.retardoBase = const Duration(seconds: 2),
    this.retardoMaximo = const Duration(minutes: 1),
    this.maxIntentosPorEscritura = 8,
  });

  final ColaEscrituras _cola;
  final BaseDatosSegura _base;
  final ServicioConectividad _conectividad;
  final String? Function() _uidActual;
  final Duration retardoBase;
  final Duration retardoMaximo;
  final int maxIntentosPorEscritura;

  static const _codigosPermanentes = {
    'permission-denied',
    'invalid-argument',
    'not-found',
    'already-exists',
  };

  StreamSubscription<bool>? _suscripcionRed;
  StreamSubscription<void>? _suscripcionEncolados;
  Timer? _temporizador;
  bool _drenando = false;
  bool _cerrado = false;
  int _reintentosSeguidos = 0;

  void iniciar() {
    _suscripcionRed ??= _conectividad.enLinea().listen((enLinea) {
      if (enLinea) {
        _reintentosSeguidos = 0;
        unawaited(drenar());
      }
    }, onError: (_) {});
    _suscripcionEncolados ??= _cola.encolados.listen(
      (_) => _programarReintento(),
    );
    unawaited(drenar());
  }

  void dispose() {
    _cerrado = true;
    _temporizador?.cancel();
    _suscripcionRed?.cancel();
    _suscripcionEncolados?.cancel();
  }

  bool _esPermanente(Object error) {
    if (error is ArgumentError) return true;
    if (error is FirebaseException) {
      return _codigosPermanentes.contains(error.code);
    }
    return false;
  }

  Future<void> drenar() async {
    if (_drenando || _cerrado) return;
    _drenando = true;
    try {
      final uid = _uidActual();
      if (uid == null) return;
      if (!await _conectividad.estaEnLinea()) return;
      for (final escritura in await _cola.pendientes(uid)) {
        if (_uidActual() != uid) return;
        try {
          await _base.aplicarEscrituraPendiente(escritura);
          await _cola.quitar(uid, escritura.id);
        } catch (error) {
          if (_esPermanente(error)) {
            await _cola.moverAFallidas(uid, escritura.id);
            continue;
          }
          final intentos = await _cola.registrarIntento(uid, escritura.id);
          if (intentos >= maxIntentosPorEscritura) {
            await _cola.moverAFallidas(uid, escritura.id);
            continue;
          }
          _programarReintento();
          return;
        }
      }
      _reintentosSeguidos = 0;
    } finally {
      _drenando = false;
    }
  }

  void _programarReintento() {
    if (_cerrado) return;
    _temporizador?.cancel();
    final exponente = _reintentosSeguidos > 16 ? 16 : _reintentosSeguidos;
    var espera = retardoBase * (1 << exponente);
    if (espera > retardoMaximo) espera = retardoMaximo;
    _reintentosSeguidos++;
    _temporizador = Timer(espera, () => unawaited(drenar()));
  }
}
