import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oncuidar/nucleo/almacen/almacen_secreto.dart';
import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
import 'package:oncuidar/nucleo/red/cliente_api.dart';
import 'package:oncuidar/nucleo/sesion/escucha_sesion.dart';
import 'package:oncuidar/nucleo/sesion/servicio_sesion.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'al vencer la sesión se borran la llave y la caché pero no la cola',
    () async {
      SharedPreferences.setMockInitialValues({
        'oncuidar.flujo.u1./pacientes': '[1]',
        'oncuidar.cola_escrituras.u1': '[]',
        'oncuidar.cola_fallidas.u1': '[]',
      });
      late final ServicioSesion sesion;
      final api = ClienteApi(
        urlBase: 'http://localhost',
        obtenerToken: () => sesion.token,
        cliente: MockClient((pedido) async {
          if (pedido.url.path == '/auth/login') {
            return http.Response(jsonEncode({'uid': 'u1', 'token': 't1'}), 200);
          }
          return http.Response(
            jsonEncode({'error': 'Token inválido o vencido'}),
            401,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      sesion = ServicioSesion(api: api, almacen: AlmacenSecretoMemoria());
      final almacenCifrado = AlmacenSecretoMemoria();
      await almacenCifrado.escribir('oncuidar.data-key.u1', 'llave');
      final cifrado = ServicioCifrado(api: api, almacen: almacenCifrado);
      final base = BaseDatosSegura(api: api, sesion: sesion, cifrado: cifrado);
      var salidas = 0;
      final sub = escucharSesion(
        sesion.cambios,
        cifrado: () => cifrado,
        base: () => base,
        alEntrar: () {},
        alSalir: () => salidas++,
      );
      addTearDown(sub.cancel);
      await sesion.iniciarSesion('ana@correo.cl', 'clave');
      await pumpEventQueue();

      await expectLater(api.get('/pacientes'), throwsA(isA<ExcepcionApi>()));
      await pumpEventQueue();

      expect(sesion.actual, isNull);
      expect(salidas, 1);
      expect(await almacenCifrado.leer('oncuidar.data-key.u1'), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), {
        'oncuidar.cola_escrituras.u1',
        'oncuidar.cola_fallidas.u1',
      });
    },
  );

  test('sin sesión previa un cambio vacío no limpia nada', () async {
    SharedPreferences.setMockInitialValues({
      'oncuidar.flujo.u1./pacientes': '[1]',
    });
    final api = ClienteApi(
      urlBase: 'http://localhost',
      obtenerToken: () => null,
    );
    final cifrado = ServicioCifrado(api: api, almacen: AlmacenSecretoMemoria());
    var salidas = 0;
    final sub = escucharSesion(
      Stream.value(null),
      cifrado: () => cifrado,
      base: () => BaseDatosSegura(api: api, cifrado: cifrado),
      alEntrar: () {},
      alSalir: () => salidas++,
    );
    addTearDown(sub.cancel);
    await pumpEventQueue();

    expect(salidas, 0);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), {'oncuidar.flujo.u1./pacientes'});
  });
}
