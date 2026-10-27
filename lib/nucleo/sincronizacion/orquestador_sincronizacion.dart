import 'dart:async';

import 'package:oncuidar/nucleo/conectividad/servicio_conectividad.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
import 'package:oncuidar/nucleo/red/cliente_api.dart';
import 'package:oncuidar/nucleo/sincronizacion/cola_escrituras.dart';

class OrquestadorSincronizacion {
  OrquestadorSincronizacion({
    required this._cola,
    required this._base,
    required this._conectividad,
    required this._uidActual,
    this.retardoBase = const Duration(seconds: 2),
    this.retardoMaximo = const Duration(minutes: 1),
  });

  final ColaEscrituras _cola;
  final BaseDatosSegura _base;
  final ServicioConectividad _conectividad;
  final String? Function() _uidActual;
  final Duration retardoBase;
  final Duration retardoMaximo;

  StreamSubscription<bool>? _suscripcionRed;
  StreamSubscription<void>? _suscripcionEncolados;
  Timer? _temporizador;
  bool _drenando = false;
  bool _otraVuelta = false;
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
    if (error is ExcepcionApi) return error.esPermanente;
    return false;
  }

  Future<void> drenar() async {
    if (_cerrado) return;
    if (_drenando) {
      _otraVuelta = true;
      return;
    }
    _drenando = true;
    try {
      do {
        _otraVuelta = false;
        await _enviarPendientes();
      } while (_otraVuelta && !_cerrado);
    } finally {
      _drenando = false;
    }
  }

  Future<void> _enviarPendientes() async {
    final uid = _uidActual();
    if (uid == null) return;
    if (!await _conectividad.estaEnLinea()) return;
    while (_uidActual() == uid) {
      final pendientes = await _cola.pendientes(uid);
      if (pendientes.isEmpty) {
        _reintentosSeguidos = 0;
        return;
      }
      final escritura = pendientes.first;
      try {
        await _base.aplicarEscrituraPendiente(escritura);
        await _cola.quitar(uid, escritura.id);
      } catch (error) {
        if (error is ExcepcionApi && error.esTokenInvalido) return;
        if (_esPermanente(error)) {
          await _cola.moverAFallidas(uid, escritura.id);
          continue;
        }
        await _cola.registrarIntento(uid, escritura.id);
        _programarReintento();
        return;
      }
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
