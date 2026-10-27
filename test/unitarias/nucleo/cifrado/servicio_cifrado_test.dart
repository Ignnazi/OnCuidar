import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/nucleo/almacen/almacen_secreto.dart';
import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';
import 'package:oncuidar/nucleo/red/cliente_api.dart';

final _clave = base64.encode(List<int>.generate(32, (i) => i));

ServicioCifrado _servicio({AlmacenSecreto? almacen}) => ServicioCifrado(
  api: ClienteApi(urlBase: 'http://localhost', obtenerToken: () => null),
  almacen: almacen ?? AlmacenSecretoMemoria(),
);

void main() {
  late ServicioCifrado cifrado;

  setUp(() async {
    cifrado = _servicio();
    await cifrado.fijarClave('u1', _clave);
  });

  test('cifra y descifra el mismo texto', () async {
    const texto = 'Fiebre de 38,5 y dolor de cabeza';
    final valor = await cifrado.cifrar('u1', texto);
    expect(await cifrado.descifrar('u1', valor), texto);
  });

  test('el texto cifrado no deja ver el texto original', () async {
    final valor = await cifrado.cifrar('u1', 'Leucemia linfoblástica');
    expect(valor, isNot(contains('Leucemia')));
    expect(valor.split('.'), hasLength(3));
  });

  test('el mismo texto cifrado dos veces da resultados distintos', () async {
    final a = await cifrado.cifrar('u1', 'dato');
    final b = await cifrado.cifrar('u1', 'dato');
    expect(a, isNot(b));
  });

  test('con la clave bloqueada no se puede cifrar ni descifrar', () async {
    final valor = await cifrado.cifrar('u1', 'dato');
    cifrado.bloquear();
    expect(cifrado.tieneClave('u1'), isFalse);
    expect(() => cifrado.cifrar('u1', 'dato'), throwsStateError);
    expect(() => cifrado.descifrar('u1', valor), throwsStateError);
  });

  test('la clave de un usuario no sirve para otro', () async {
    expect(cifrado.tieneClave('u2'), isFalse);
    expect(() => cifrado.cifrar('u2', 'dato'), throwsStateError);
  });

  test('un texto cifrado alterado no se puede descifrar', () async {
    final partes = (await cifrado.cifrar('u1', 'dato')).split('.');
    final alterado = [
      partes[0],
      base64UrlEncode([1, 2, 3, 4]),
      partes[2],
    ];
    expect(
      () => cifrado.descifrar('u1', alterado.join('.')),
      throwsA(anything),
    );
  });

  test('rechaza una clave que no es de 32 bytes', () {
    expect(
      () => cifrado.fijarClave('u1', base64.encode([1, 2, 3])),
      throwsFormatException,
    );
  });

  test(
    'la clave queda guardada y se recupera al volver a abrir la app',
    () async {
      final almacen = AlmacenSecretoMemoria();
      final primero = _servicio(almacen: almacen);
      await primero.fijarClave('u1', _clave);
      final valor = await primero.cifrar('u1', 'dato');

      final segundo = _servicio(almacen: almacen);
      expect(await segundo.restaurarClave('u1'), isTrue);
      expect(await segundo.descifrar('u1', valor), 'dato');
    },
  );
}
