import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oncuidar/nucleo/almacen/almacen_secreto.dart';
import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
import 'package:oncuidar/nucleo/red/cliente_api.dart';
import 'package:oncuidar/nucleo/sesion/servicio_sesion.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('borrar la caché local quita solo los datos de ese usuario', () async {
    SharedPreferences.setMockInitialValues({
      'oncuidar.flujo.u1./pacientes': '[1]',
      'oncuidar.flujo.u1./pacientes/p1/registros': '[2]',
      'oncuidar.flujo.u2./pacientes': '[3]',
      'oncuidar.cola_escrituras.u1': '[]',
      'oncuidar.cola_fallidas.u1': '[]',
    });
    final api = ClienteApi(
      urlBase: 'http://localhost',
      obtenerToken: () => null,
    );
    final base = BaseDatosSegura(
      api: api,
      cifrado: ServicioCifrado(api: api, almacen: AlmacenSecretoMemoria()),
    );

    await base.borrarCacheLocal('u1');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), {
      'oncuidar.flujo.u2./pacientes',
      'oncuidar.cola_escrituras.u1',
      'oncuidar.cola_fallidas.u1',
    });
  });

  test('una consulta que termina tras cerrar sesión no deja caché', () async {
    SharedPreferences.setMockInitialValues({});
    final respuesta = Completer<http.Response>();
    late final ServicioSesion sesion;
    final api = ClienteApi(
      urlBase: 'http://localhost',
      obtenerToken: () => sesion.token,
      cliente: MockClient((pedido) async {
        if (pedido.url.path == '/auth/login') {
          return http.Response(jsonEncode({'uid': 'u1', 'token': 't1'}), 200);
        }
        return respuesta.future;
      }),
    );
    sesion = ServicioSesion(api: api, almacen: AlmacenSecretoMemoria());
    await sesion.iniciarSesion('ana@correo.cl', 'clave');
    final base = BaseDatosSegura(
      api: api,
      sesion: sesion,
      cifrado: ServicioCifrado(api: api, almacen: AlmacenSecretoMemoria()),
    );
    final sub = base
        .flujo<List<dynamic>>(
          '/pacientes',
          convertir: (json) async => List<dynamic>.from(json as List),
        )
        .listen((_) {}, onError: (_) {});
    addTearDown(sub.cancel);
    await pumpEventQueue();

    await sesion.cerrarSesion();
    respuesta.complete(http.Response('[1]', 200));
    await pumpEventQueue();

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getKeys().where((c) => c.startsWith('oncuidar.flujo.')),
      isEmpty,
    );
  });

  test('una lectura que termina tras cerrar sesión no deja caché', () async {
    SharedPreferences.setMockInitialValues({});
    final respuesta = Completer<http.Response>();
    late final ServicioSesion sesion;
    final api = ClienteApi(
      urlBase: 'http://localhost',
      obtenerToken: () => sesion.token,
      cliente: MockClient((pedido) async {
        if (pedido.url.path == '/auth/login') {
          return http.Response(jsonEncode({'uid': 'u1', 'token': 't1'}), 200);
        }
        return respuesta.future;
      }),
    );
    sesion = ServicioSesion(api: api, almacen: AlmacenSecretoMemoria());
    await sesion.iniciarSesion('ana@correo.cl', 'clave');
    final base = BaseDatosSegura(
      api: api,
      sesion: sesion,
      cifrado: ServicioCifrado(api: api, almacen: AlmacenSecretoMemoria()),
    );
    final lectura = base.leerConCache('/pacientes');
    await pumpEventQueue();

    await sesion.cerrarSesion();
    respuesta.complete(http.Response('[1]', 200));
    await lectura;

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getKeys().where((c) => c.startsWith('oncuidar.flujo.')),
      isEmpty,
    );
  });
}
