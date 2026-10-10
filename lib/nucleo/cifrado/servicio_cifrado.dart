import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:oncuidar/nucleo/almacen/almacen_secreto.dart';
import 'package:oncuidar/nucleo/red/cliente_api.dart';

class ClaveNoDisponibleSinConexion implements Exception {
  const ClaveNoDisponibleSinConexion();

  static const mensaje =
      'Sin conexión y sin la clave de cifrado en este dispositivo. '
      'Conéctate a internet para guardar datos clínicos.';

  @override
  String toString() => mensaje;
}

class ServicioCifrado {
  ServicioCifrado({
    required this._api,
    required this._almacen,
    this._clavePrueba,
  });

  final ClienteApi _api;
  final AlmacenSecreto _almacen;
  final String? _clavePrueba;
  final AesGcm _cifrador = AesGcm.with256bits();
  SecretKey? _claveActiva;
  String? _uidActivo;

  Future<bool> restaurarClave(String uid) async {
    if (_clavePrueba != null) {
      await fijarClave(uid, _clavePrueba);
      return true;
    }

    String? valor;
    try {
      valor = await _almacen.leer('oncuidar.data-key.$uid');
    } catch (_) {
      return false;
    }
    if (valor == null) return false;
    try {
      final bytes = base64.decode(valor);
      if (bytes.length != 32) return false;
    } catch (_) {
      return false;
    }
    await fijarClave(uid, valor);
    return true;
  }

  Future<void> asegurarClave(String uid) async {
    final local = await restaurarClave(uid);
    if (local) return;
    try {
      await _almacen.borrar('oncuidar.data-key.$uid');
    } catch (_) {}
    final resultado = await _api.post(
      '/clave-datos',
      const {},
      const Duration(seconds: 5),
    );
    final clave = resultado is Map ? resultado['claveDatos'] : null;
    if (clave is! String) {
      throw const FormatException('Clave de datos invalida.');
    }
    await fijarClave(uid, clave);
  }

  Future<void> fijarClave(String uid, String codificada) async {
    final bytes = base64.decode(codificada);
    if (bytes.length != 32) {
      throw const FormatException('Clave de datos invalida.');
    }
    _claveActiva = SecretKey(bytes);
    _uidActivo = uid;
    if (_clavePrueba == null) {
      await _almacen.escribir('oncuidar.data-key.$uid', codificada);
    }
  }

  bool tieneClave(String uid) => _claveActiva != null && _uidActivo == uid;

  void bloquear() {
    _claveActiva = null;
    _uidActivo = null;
  }

  Future<String> cifrar(String uid, String texto) async {
    final caja = await _cifrador.encrypt(
      utf8.encode(texto),
      secretKey: _clave(uid),
    );
    return [
      base64UrlEncode(caja.nonce),
      base64UrlEncode(caja.cipherText),
      base64UrlEncode(caja.mac.bytes),
    ].join('.');
  }

  Future<String> descifrar(String uid, String valor) async {
    final partes = valor.split('.');
    if (partes.length != 3) {
      throw const FormatException('Texto cifrado invalido.');
    }
    final claro = await _cifrador.decrypt(
      SecretBox(
        base64Url.decode(partes[1]),
        nonce: base64Url.decode(partes[0]),
        mac: Mac(base64Url.decode(partes[2])),
      ),
      secretKey: _clave(uid),
    );
    return utf8.decode(claro);
  }

  SecretKey _clave(String uid) {
    if (_claveActiva != null && _uidActivo == uid) return _claveActiva!;
    throw StateError('Clave de datos no disponible.');
  }
}
