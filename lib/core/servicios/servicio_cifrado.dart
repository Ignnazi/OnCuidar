import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ServicioCifrado {
  ServicioCifrado({this._clavePrueba});

  final String? _clavePrueba;
  final _almacen = const FlutterSecureStorage();
  final AesGcm _cifrador = AesGcm.with256bits();
  SecretKey? _claveActiva;
  String? _uidActivo;

  Future<bool> restaurarClave(String uid) async {
    final valor = _clavePrueba ?? await _almacen.read(key: 'oncuidar.data-key.$uid');
    if (valor == null) return false;
    await fijarClave(uid, valor);
    return true;
  }

  /// Asegura una clave para [uid]: la restaura del almacen si existe, o la
  /// solicita al servidor (getOrCreateDataKey) y la persiste.
  Future<void> asegurarClave(String uid) async {
    final local = await restaurarClave(uid);
    if (local) return;
    final resultado = await FirebaseFunctions.instanceFor(
      region: 'southamerica-west1',
    ).httpsCallable('getOrCreateDataKey').call();
    await fijarClave(uid, (resultado.data as Map)['dataKey'] as String);
  }

  Future<void> fijarClave(String uid, String codificada) async {
    final bytes = base64.decode(codificada);
    if (bytes.length != 32) throw const FormatException('Clave de datos invalida.');
    _claveActiva = SecretKey(bytes);
    _uidActivo = uid;
    if (_clavePrueba == null) {
      await _almacen.write(key: 'oncuidar.data-key.$uid', value: codificada);
    }
  }

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
    if (partes.length != 3) throw const FormatException('Texto cifrado invalido.');
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