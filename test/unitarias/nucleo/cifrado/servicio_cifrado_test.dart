import 'dart:convert';

import 'package:cryptography/cryptography.dart';
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

  test(
    'PU-05 el texto cifrado no deja ver el original y se recupera con la clave',
    tags: 'criticos',
    () async {
      final valor = await cifrado.cifrar('u1', 'Leucemia linfoblástica');
      expect(valor, isNot(contains('Leucemia')));
      expect(valor.split('.'), hasLength(3));
      expect(await cifrado.descifrar('u1', valor), 'Leucemia linfoblástica');
    },
  );

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

  test(
    'PU-06 la clave de un usuario no sirve para otro',
    tags: 'criticos',
    () async {
      final deU1 = await cifrado.cifrar('u1', 'Leucemia linfoblástica');
      final claveDeU2 = base64.encode(List<int>.generate(32, (i) => 255 - i));
      await cifrado.fijarClave('u2', claveDeU2);

      await expectLater(
        cifrado.descifrar('u2', deU1),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
      await expectLater(cifrado.cifrar('u1', 'dato'), throwsStateError);
    },
  );

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

  test('olvidar la clave la quita de memoria y del teléfono', () async {
    final almacen = AlmacenSecretoMemoria();
    final servicio = _servicio(almacen: almacen);
    await servicio.fijarClave('u1', _clave);
    await servicio.fijarClave('u2', _clave);

    await servicio.olvidarClave('u1');

    expect(servicio.tieneClave('u1'), isFalse);
    expect(await almacen.leer('oncuidar.data-key.u1'), isNull);
    expect(await servicio.restaurarClave('u1'), isFalse);
    expect(await almacen.leer('oncuidar.data-key.u2'), _clave);
  });
}
