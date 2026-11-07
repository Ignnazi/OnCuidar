import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oncuidar/nucleo/almacen/almacen_secreto.dart';
import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
import 'package:oncuidar/nucleo/red/cliente_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _claveCache = 'oncuidar.flujo.u1./pacientes';

BaseDatosSegura _base(ClienteApi api) => BaseDatosSegura(
  api: api,
  uidPrueba: 'u1',
  cifrado: ServicioCifrado(api: api, almacen: AlmacenSecretoMemoria()),
  intervaloConsulta: const Duration(milliseconds: 20),
);

ClienteApi _api(Future<http.Response> Function() responder) => ClienteApi(
  urlBase: 'http://localhost',
  obtenerToken: () => 'token',
  cliente: MockClient((_) => responder()),
);

http.Response _json(Object cuerpo, int codigo) =>
    http.Response.bytes(utf8.encode(jsonEncode(cuerpo)), codigo);

Future<(List<dynamic>, List<Object>)> _escuchar(
  Stream<List<dynamic>> flujo, {
  Duration espera = const Duration(milliseconds: 120),
}) async {
  final datos = <dynamic>[];
  final errores = <Object>[];
  final sub = flujo.listen(datos.add, onError: errores.add);
  await Future<void>.delayed(espera);
  await sub.cancel();
  return (datos, errores);
}

Stream<List<dynamic>> _flujo(BaseDatosSegura base) => base.flujo<List<dynamic>>(
  '/pacientes',
  convertir: (json) async => List<dynamic>.from(json as List),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('error 5xx sin caché llega como error y no como lista vacía', () async {
    final base = _base(_api(() async => _json({'error': 'Fallo'}, 500)));

    final (datos, errores) = await _escuchar(_flujo(base));

    expect(datos, isEmpty);
    expect(errores, isNotEmpty);
    expect(errores.first, isA<ExcepcionApi>());
    expect((errores.first as ExcepcionApi).codigoHttp, 500);
  });

  test('error 5xx con caché muestra la caché sin error', () async {
    SharedPreferences.setMockInitialValues({
      _claveCache: jsonEncode([
        {'id': 'p1'},
      ]),
    });
    final base = _base(_api(() async => _json({'error': 'Fallo'}, 503)));

    final (datos, errores) = await _escuchar(_flujo(base));

    expect(datos, [
      [
        {'id': 'p1'},
      ],
    ]);
    expect(errores, isEmpty);
  });

  test('sin conexión y sin caché sigue mostrando lista vacía', () async {
    final base = _base(_api(() async => throw http.ClientException('sin red')));

    final (datos, errores) = await _escuchar(_flujo(base));

    expect(datos, [isEmpty]);
    expect(errores, isEmpty);
  });

  test('sin conexión con caché muestra la caché', () async {
    SharedPreferences.setMockInitialValues({
      _claveCache: jsonEncode([
        {'id': 'p1'},
      ]),
    });
    final base = _base(_api(() async => throw http.ClientException('sin red')));

    final (datos, errores) = await _escuchar(_flujo(base));

    expect(datos, [
      [
        {'id': 'p1'},
      ],
    ]);
    expect(errores, isEmpty);
  });

  test('tiempo agotado sin caché cuenta como sin conexión', () async {
    final api = ClienteApi(
      urlBase: 'http://localhost',
      obtenerToken: () => 'token',
      limite: const Duration(milliseconds: 5),
      cliente: MockClient((_) => Completer<http.Response>().future),
    );

    final (datos, errores) = await _escuchar(_flujo(_base(api)));

    expect(datos, [isEmpty]);
    expect(errores, isEmpty);
  });

  test('token vencido avisa el cierre de sesión y no muestra error', () async {
    var vencidas = 0;
    final api = _api(
      () async => _json({'error': 'Token inválido o vencido'}, 401),
    )..alSesionVencida = () => vencidas++;

    final (datos, errores) = await _escuchar(_flujo(_base(api)));

    expect(vencidas, greaterThan(0));
    expect(datos, [isEmpty]);
    expect(errores, isEmpty);
  });

  test(
    'tras un error 5xx vuelve a mostrar datos cuando el servidor responde',
    () async {
      var fallar = true;
      final base = _base(
        _api(
          () async => fallar
              ? _json({'error': 'Fallo'}, 500)
              : _json([
                  {'id': 'p2'},
                ], 200),
        ),
      );
      final datos = <dynamic>[];
      final errores = <Object>[];
      final sub = _flujo(base).listen(datos.add, onError: errores.add);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      fallar = false;
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await sub.cancel();

      expect(errores, isNotEmpty);
      expect(datos, [
        [
          {'id': 'p2'},
        ],
      ]);
      expect(
        SharedPreferences.getInstance().then((p) => p.getString(_claveCache)),
        completion(
          jsonEncode([
            {'id': 'p2'},
          ]),
        ),
      );
    },
  );
}
