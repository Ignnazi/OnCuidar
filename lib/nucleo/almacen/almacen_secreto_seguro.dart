import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oncuidar/nucleo/almacen/almacen_secreto.dart';

class AlmacenSecretoSeguro implements AlmacenSecreto {
  const AlmacenSecretoSeguro();

  static const _almacen = FlutterSecureStorage();

  @override
  Future<String?> leer(String clave) => _almacen.read(key: clave);

  @override
  Future<void> escribir(String clave, String valor) =>
      _almacen.write(key: clave, value: valor);

  @override
  Future<void> borrar(String clave) => _almacen.delete(key: clave);
}
