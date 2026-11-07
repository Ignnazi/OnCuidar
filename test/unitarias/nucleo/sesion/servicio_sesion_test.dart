import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oncuidar/nucleo/almacen/almacen_secreto.dart';
import 'package:oncuidar/nucleo/red/cliente_api.dart';
import 'package:oncuidar/nucleo/sesion/servicio_sesion.dart';

ServicioSesion _servicio(MockClient cliente) => ServicioSesion(
  api: ClienteApi(
    urlBase: 'http://servidor/api',
    obtenerToken: () => null,
    cliente: cliente,
  ),
  almacen: AlmacenSecretoMemoria(),
  esperaReintento: Duration.zero,
);

http.Response _sesionValida() => http.Response(
  jsonEncode({'uid': 'u1', 'token': 't1'}),
  200,
  headers: {'content-type': 'application/json'},
);

void main() {
  test('reintenta una vez si la primera conexión falla', () async {
    var llamadas = 0;
    final servicio = _servicio(
      MockClient((_) async {
        llamadas++;
        if (llamadas == 1) throw http.ClientException('conexión cerrada');
        return _sesionValida();
      }),
    );

    final sesion = await servicio.iniciarSesion('Ana@Correo.cl', 'clave');

    expect(llamadas, 2);
    expect(sesion.uid, 'u1');
    expect(sesion.correo, 'ana@correo.cl');
    expect(servicio.actual?.token, 't1');
  });

  test('si falla dos veces avisa que no hubo conexión', () async {
    var llamadas = 0;
    final servicio = _servicio(
      MockClient((_) async {
        llamadas++;
        throw http.ClientException('sin red');
      }),
    );

    await expectLater(
      servicio.iniciarSesion('ana@correo.cl', 'clave'),
      throwsA(
        isA<ExcepcionSesion>().having(
          (e) => e.codigo,
          'codigo',
          CodigoErrorSesion.sinRed,
        ),
      ),
    );
    expect(llamadas, 2);
    expect(servicio.actual, isNull);
  });

  test('no reintenta si la contraseña es incorrecta', () async {
    var llamadas = 0;
    final servicio = _servicio(
      MockClient((_) async {
        llamadas++;
        return http.Response(
          jsonEncode({'error': 'Correo o contraseña incorrectos'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    await expectLater(
      servicio.iniciarSesion('ana@correo.cl', 'mala'),
      throwsA(isA<ExcepcionSesion>()),
    );
    expect(llamadas, 1);
  });
}
