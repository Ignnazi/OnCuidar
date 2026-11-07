import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oncuidar/nucleo/red/cliente_api.dart';

void main() {
  test('delete puede llevar cuerpo en JSON', () async {
    late http.Request enviada;
    final api = ClienteApi(
      urlBase: 'http://servidor/api',
      obtenerToken: () => 't1',
      cliente: MockClient((peticion) async {
        enviada = peticion;
        return http.Response('{"ok":true}', 200);
      }),
    );

    await api.delete('/cuenta', cuerpo: {'contrasena': 'secreta1'});

    expect(enviada.method, 'DELETE');
    expect(enviada.headers['Content-Type'], startsWith('application/json'));
    expect(jsonDecode(enviada.body), {'contrasena': 'secreta1'});
  });

  test('delete sin cuerpo no manda cuerpo', () async {
    late http.Request enviada;
    final api = ClienteApi(
      urlBase: 'http://servidor/api',
      obtenerToken: () => 't1',
      cliente: MockClient((peticion) async {
        enviada = peticion;
        return http.Response('{"ok":true}', 200);
      }),
    );

    await api.delete('/pacientes/p1');

    expect(enviada.body, isEmpty);
    expect(enviada.headers.containsKey('Content-Type'), isFalse);
  });

  test('410 de un paciente borrado es permanente', () {
    expect(const ExcepcionApi(410, 'Paciente eliminado').esPermanente, isTrue);
  });

  test('500 sigue siendo transitorio', () {
    expect(const ExcepcionApi(500, 'Error').esPermanente, isFalse);
  });
}
