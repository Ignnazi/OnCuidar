import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';
import 'package:oncuidar/nucleo/conectividad/servicio_conectividad.dart';
import 'package:oncuidar/nucleo/datos/flujo_recurso.dart';
import 'package:oncuidar/nucleo/red/cliente_api.dart';
import 'package:oncuidar/nucleo/sesion/servicio_sesion.dart';
import 'package:oncuidar/nucleo/sincronizacion/cola_escrituras.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BaseDatosSegura {
  BaseDatosSegura({
    required this.api,
    this.sesion,
    this._uidPrueba,
    required this.cifrado,
    this.cola,
    this.conectividad,
    this.limiteEscritura = const Duration(seconds: 8),
    this.intervaloConsulta = const Duration(seconds: 10),
  });

  final ClienteApi api;
  final ServicioSesion? sesion;
  final String? _uidPrueba;
  final ServicioCifrado cifrado;
  final ColaEscrituras? cola;
  final ServicioConectividad? conectividad;
  final Duration limiteEscritura;
  final Duration intervaloConsulta;

  final _cambios = StreamController<void>.broadcast();

  Stream<void> get cambios => _cambios.stream;

  void notificarCambio() {
    if (!_cambios.isClosed) _cambios.add(null);
  }

  String get uid {
    if (_uidPrueba != null) return _uidPrueba;
    final actual = sesion?.actual;
    if (actual == null) throw StateError('No user authenticated');
    return actual.uid;
  }

  bool tieneIdentidad() => _uidPrueba != null || sesion?.actual != null;

  Future<dynamic> leer(String ruta) => api.get(ruta);

  String _prefijoCache(String uid) => 'oncuidar.flujo.$uid.';

  Stream<T> flujo<T>(
    String ruta, {
    required Future<T> Function(dynamic json) convertir,
    dynamic vacio = const <dynamic>[],
  }) {
    if (!tieneIdentidad()) {
      return Stream.fromFuture(convertir(vacio));
    }
    final dueno = uid;
    final claveCache = '${_prefijoCache(dueno)}$ruta';
    return FlujoRecurso<T>(
      consultar: () => api.get(ruta),
      leerCache: () async {
        final prefs = await SharedPreferences.getInstance();
        final texto = prefs.getString(claveCache);
        return texto == null ? null : jsonDecode(texto);
      },
      guardarCache: (json) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(claveCache, jsonEncode(json));
      },
      aplicarPendientes: (json) => _aplicarPendientes(dueno, ruta, json),
      cambios: cambios,
      convertir: convertir,
      vacio: vacio,
      intervalo: intervaloConsulta,
    ).stream;
  }

  Future<dynamic> _aplicarPendientes(
    String dueno,
    String ruta,
    dynamic json,
  ) async {
    final cola = this.cola;
    if (cola == null) return json;
    final pendientes = [...await cola.pendientes(dueno)]
      ..sort((a, b) => a.encoladoEn.compareTo(b.encoladoEn));
    var resultado = json;
    for (final e in pendientes) {
      resultado = aplicarEscrituraAJson(
        resultado,
        ruta,
        e.ruta,
        e.datos,
        e.operacion,
      );
    }
    return resultado;
  }

  Future<dynamic> leerConCache(String ruta) async {
    final dueno = uid;
    final clave = '${_prefijoCache(dueno)}$ruta';
    dynamic json;
    try {
      json = await api.get(ruta);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(clave, jsonEncode(json));
      } catch (_) {}
    } on ExcepcionApi catch (e) {
      if (!e.esDeRed) rethrow;
      final prefs = await SharedPreferences.getInstance();
      final texto = prefs.getString(clave);
      if (texto == null) rethrow;
      json = jsonDecode(texto);
    }
    return _aplicarPendientes(dueno, ruta, json);
  }

  bool get _conCola => cola != null && conectividad != null;

  Future<void> verificarEscrituraDisponible() async {
    if (!_conCola) return;
    if (await conectividad!.estaEnLinea()) return;
    if (cifrado.tieneClave(uid)) return;
    if (await cifrado.restaurarClave(uid)) return;
    throw const ClaveNoDisponibleSinConexion();
  }

  Future<void> aplicar(
    String ruta,
    Map<String, dynamic> datos,
    OperacionPendiente operacion,
  ) async {
    if (operacion == OperacionPendiente.borrar) {
      await api.delete(ruta);
    } else {
      await api.put(ruta, datos);
    }
  }

  Future<void> sinEsperarSinRed(Future<void> Function() operacion) async {
    final conectividad = this.conectividad;
    final enLinea = conectividad == null || await conectividad.estaEnLinea();
    final pendiente = operacion();
    if (enLinea) return pendiente;
    unawaited(pendiente.catchError((_) {}));
  }

  Future<void> reflejarEnCache(
    String ruta,
    Map<String, dynamic> datos,
    OperacionPendiente operacion,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefijo = _prefijoCache(uid);
      final cuerpo = Map<String, dynamic>.from(
        CodecPayload.codificar(datos) as Map,
      );
      for (final clave in prefs.getKeys()) {
        if (!clave.startsWith(prefijo)) continue;
        final texto = prefs.getString(clave);
        if (texto == null) continue;
        final nuevo = aplicarEscrituraAJson(
          jsonDecode(texto),
          clave.substring(prefijo.length),
          ruta,
          cuerpo,
          operacion,
        );
        final nuevoTexto = jsonEncode(nuevo);
        if (nuevoTexto != texto) await prefs.setString(clave, nuevoTexto);
      }
    } catch (e) {
      debugPrint('No se pudo reflejar el cambio en la caché: $e');
    }
    notificarCambio();
  }

  Future<void> encolar(
    String ruta,
    Map<String, dynamic> datos,
    OperacionPendiente operacion,
    String? idPaciente,
  ) {
    final ahora = DateTime.now();
    return cola!.encolar(
      uid,
      EscrituraPendiente(
        id: '${ahora.microsecondsSinceEpoch}_${ruta.split('/').last}',
        ruta: ruta,
        operacion: operacion,
        datos: Map<String, dynamic>.from(CodecPayload.codificar(datos) as Map),
        pacienteId: idPaciente,
        encoladoEn: ahora.millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> escribir(
    String ruta,
    Map<String, dynamic> datos, {
    required OperacionPendiente operacion,
    String? idPaciente,
  }) async {
    if (!_conCola) {
      await aplicar(ruta, datos, operacion);
      notificarCambio();
      return;
    }
    if (!await conectividad!.estaEnLinea() ||
        (await cola!.pendientes(uid)).isNotEmpty) {
      await encolar(ruta, datos, operacion, idPaciente);
      await reflejarEnCache(ruta, datos, operacion);
      return;
    }
    try {
      await aplicar(ruta, datos, operacion).timeout(limiteEscritura);
      notificarCambio();
    } on TimeoutException {
      await encolar(ruta, datos, operacion, idPaciente);
      await reflejarEnCache(ruta, datos, operacion);
    } on ExcepcionApi catch (e) {
      if (!e.esDeRed) rethrow;
      await encolar(ruta, datos, operacion, idPaciente);
      await reflejarEnCache(ruta, datos, operacion);
    }
  }

  Future<void> borrar(String ruta, String? idPaciente) => escribir(
    ruta,
    const {},
    operacion: OperacionPendiente.borrar,
    idPaciente: idPaciente,
  );

  Future<void> aplicarEscrituraPendiente(EscrituraPendiente escritura) async {
    final pid = escritura.pacienteId;
    if (pid != null) {
      final raiz = '/pacientes/$pid';
      if (escritura.ruta != raiz && !escritura.ruta.startsWith('$raiz/')) {
        throw ArgumentError(
          'La escritura pendiente no corresponde al paciente indicado',
        );
      }
    }
    try {
      await aplicar(
        escritura.ruta,
        escritura.datos,
        escritura.operacion,
      ).timeout(limiteEscritura);
    } on ExcepcionApi catch (e) {
      final yaBorrado =
          escritura.operacion == OperacionPendiente.borrar &&
          e.codigoHttp == 404;
      if (!yaBorrado) rethrow;
    }
    notificarCambio();
  }

  void ponerCifrado(Map<String, dynamic> data, String clave, String? valor) {
    final cifrados = (data['cifrados'] ??= <String, dynamic>{}) as Map;
    cifrados[clave] = valor;
  }

  Future<void> reemplazarPorCifrado(
    Map<String, dynamic> data, {
    required String? plano,
    required String cifrado,
  }) async {
    if (plano == null || plano.isEmpty) {
      ponerCifrado(data, cifrado, null);
    } else {
      ponerCifrado(data, cifrado, await this.cifrado.cifrar(uid, plano));
    }
  }

  String? textoCifrado(Map<String, dynamic> datos, String clave) {
    final cifrados = datos['cifrados'];
    if (cifrados is! Map) return null;
    final valor = cifrados[clave];
    return valor is String ? valor : null;
  }

  Future<String?> descifrarCampo(
    Map<String, dynamic> datos,
    String campo,
  ) async {
    final cifrado = textoCifrado(datos, campo);
    if (cifrado == null || cifrado.isEmpty) return null;
    try {
      return await this.cifrado.descifrar(uid, cifrado);
    } catch (e, pila) {
      debugPrint('No se pudo descifrar $campo: $e\n$pila');
      return null;
    }
  }

  DateTime fechaTolerante(Object? valor) {
    if (valor is DateTime) return valor;
    if (valor is String) {
      return DateTime.tryParse(valor)?.toLocal() ?? DateTime.now();
    }
    return DateTime.now();
  }
}
