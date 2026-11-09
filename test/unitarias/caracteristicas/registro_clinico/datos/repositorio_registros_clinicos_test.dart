import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/datos/repositorio_registros_clinicos.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';
import 'package:oncuidar/nucleo/almacen/almacen_secreto.dart';
import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
import 'package:oncuidar/nucleo/red/cliente_api.dart';
import 'package:oncuidar/nucleo/sincronizacion/cola_escrituras.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../ayudas/offline.dart';

class ApiFalsa extends ClienteApi {
  ApiFalsa() : super(urlBase: 'http://localhost', obtenerToken: () => null);

  Map<String, dynamic>? enviado;
  List<dynamic> respuesta = const [];

  @override
  Future<dynamic> put(String ruta, Object? cuerpo, {Duration? limite}) async {
    enviado = jsonDecode(jsonEncode(cuerpo)) as Map<String, dynamic>;
    return enviado;
  }

  @override
  Future<dynamic> get(String ruta, {Duration? limite}) async => respuesta;
}

void main() {
  late ApiFalsa api;
  late BaseDatosSegura bd;
  late RepositorioRegistrosClinicos repo;

  setUp(() async {
    api = ApiFalsa();
    bd = BaseDatosSegura(
      api: api,
      uidPrueba: 'u1',
      cifrado: ServicioCifrado(
        api: api,
        almacen: AlmacenSecretoMemoria(),
        clavePrueba: base64.encode(List<int>.filled(32, 3)),
      ),
    );
    await bd.cifrado.restaurarClave('u1');
    repo = RepositorioRegistrosClinicos(bd);
  });

  final registro = RegistroClinico(
    id: 'r1',
    pacienteId: 'p1',
    fecha: DateTime.utc(2026, 11, 7, 10),
    creadoEn: DateTime.utc(2026, 11, 7, 10),
    tipoRegistro: 'programado',
    nivelAlerta: NivelAlerta.critico,
  );

  Future<NivelAlerta> leerNivel(Map<String, dynamic> fila) async {
    api.respuesta = [fila];
    final lista = await repo.registrosClinicosEnRango('p1');
    return lista.single.nivelAlerta;
  }

  test('el nivel de alerta se envía cifrado y no en claro', () async {
    await repo.guardarRegistroClinico('p1', registro);
    final cuerpo = api.enviado!;
    expect(cuerpo['nivelAlerta'], isNull);
    final cifrado = (cuerpo['cifrados'] as Map)['nivel_alerta_cifrado'];
    expect(cifrado, isA<String>());
    expect(cifrado, isNot(contains('critico')));
    expect(await bd.cifrado.descifrar('u1', cifrado as String), 'critico');
  });

  test('la fecha sigue en claro para filtrar por rango', () async {
    await repo.guardarRegistroClinico('p1', registro);
    expect(api.enviado!['fecha'], '2026-11-07T10:00:00.000Z');
  });

  test('un registro nuevo se lee con su nivel de alerta', () async {
    await repo.guardarRegistroClinico('p1', registro);
    expect(await leerNivel({...api.enviado!, 'id': 'r1'}), NivelAlerta.critico);
  });

  test('un registro antiguo con el nivel en claro se sigue leyendo', () async {
    final antiguo = {
      'id': 'r0',
      'pacienteId': 'p1',
      'fecha': '2026-01-01T10:00:00.000Z',
      'creadoEn': '2026-01-01T10:00:00.000Z',
      'tipoRegistro': 'programado',
      'nivelAlerta': 'alerta',
      'cifrados': <String, dynamic>{},
    };
    expect(await leerNivel(antiguo), NivelAlerta.alerta);
  });

  test('el rango para exportar incluye lo que sigue en la cola', () async {
    SharedPreferences.setMockInitialValues({});
    final red = ConectividadFalsa(enLinea: false);
    final conCola = BaseDatosSegura(
      api: api,
      uidPrueba: 'u1',
      cifrado: bd.cifrado,
      cola: ColaEscrituras(),
      conectividad: red,
    );
    final repoConCola = RepositorioRegistrosClinicos(conCola);
    await repoConCola.guardarRegistroClinico('p1', registro);
    red.fijar(true);
    api.respuesta = [
      {
        'id': 'r0',
        'pacienteId': 'p1',
        'fecha': '2026-11-01T10:00:00.000Z',
        'creadoEn': '2026-11-01T10:00:00.000Z',
        'tipoRegistro': 'programado',
        'cifrados': <String, dynamic>{},
      },
    ];

    final lista = await repoConCola.registrosClinicosEnRango('p1');

    expect(lista.map((r) => r.id), ['r0', 'r1']);
    expect(lista.last.nivelAlerta, NivelAlerta.critico);
  });
}
