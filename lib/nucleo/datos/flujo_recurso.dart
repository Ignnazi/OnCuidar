import 'dart:async';
import 'dart:convert';

import 'package:oncuidar/nucleo/sincronizacion/cola_escrituras.dart';

String rutaSinQuery(String ruta) {
  final i = ruta.indexOf('?');
  return i < 0 ? ruta : ruta.substring(0, i);
}

String _padre(String ruta) {
  final i = ruta.lastIndexOf('/');
  return i <= 0 ? '' : ruta.substring(0, i);
}

String _ultimo(String ruta) => ruta.substring(ruta.lastIndexOf('/') + 1);

Map<String, dynamic> fusionarCuerpo(
  Map<String, dynamic>? base,
  Map<String, dynamic> datos,
) {
  final resultado = <String, dynamic>{...?base};
  for (final e in datos.entries) {
    if (e.key == 'cifrados' && e.value is Map) {
      final cifrados = <String, dynamic>{
        ...?(resultado['cifrados'] as Map?)?.cast<String, dynamic>(),
      };
      for (final c in (e.value as Map).entries) {
        if (c.value == null) {
          cifrados.remove(c.key.toString());
        } else {
          cifrados[c.key.toString()] = c.value;
        }
      }
      resultado['cifrados'] = cifrados;
    } else {
      resultado[e.key] = e.value;
    }
  }
  return resultado;
}

dynamic aplicarEscrituraAJson(
  dynamic json,
  String rutaRecurso,
  String rutaEscritura,
  Map<String, dynamic> datos,
  OperacionPendiente operacion,
) {
  final recurso = rutaSinQuery(rutaRecurso);
  if (json is List) {
    if (_padre(rutaEscritura) != recurso) return json;
    final id = _ultimo(rutaEscritura);
    final lista = [for (final e in json) e];
    final indice = lista.indexWhere((e) => e is Map && e['id'] == id);
    if (operacion == OperacionPendiente.borrar) {
      if (indice >= 0) lista.removeAt(indice);
      return lista;
    }
    if (indice >= 0) {
      lista[indice] = fusionarCuerpo(
        (lista[indice] as Map).cast<String, dynamic>(),
        datos,
      );
    } else if (operacion != OperacionPendiente.fusionar) {
      lista.add(fusionarCuerpo({'id': id}, datos));
    }
    return lista;
  }
  if (json is Map && json['ids'] is List && _padre(rutaEscritura) == recurso) {
    final id = _ultimo(rutaEscritura);
    final ids = [for (final e in json['ids'] as List) e]..remove(id);
    if (operacion != OperacionPendiente.borrar) ids.add(id);
    return {...json, 'ids': ids};
  }
  if (json is Map && recurso == rutaEscritura) {
    if (operacion == OperacionPendiente.borrar) return json;
    return fusionarCuerpo(json.cast<String, dynamic>(), datos);
  }
  return json;
}

class FlujoRecurso<T> {
  FlujoRecurso({
    required this.consultar,
    required this.leerCache,
    required this.guardarCache,
    required this.aplicarPendientes,
    required this.cambios,
    required this.convertir,
    required this.vacio,
    this.intervalo = const Duration(seconds: 10),
  }) {
    _controlador = StreamController<T>(onListen: _iniciar, onCancel: _detener);
  }

  final Future<dynamic> Function() consultar;
  final Future<dynamic> Function() leerCache;
  final Future<void> Function(dynamic json) guardarCache;
  final Future<dynamic> Function(dynamic json) aplicarPendientes;
  final Stream<void> cambios;
  final Future<T> Function(dynamic json) convertir;

  final dynamic vacio;
  final Duration intervalo;

  late final StreamController<T> _controlador;
  StreamSubscription<void>? _suscripcionCambios;
  Timer? _temporizador;
  bool _cerrado = false;
  bool _ocupado = false;
  bool _repetir = false;
  String? _ultimaHuella;

  Stream<T> get stream => _controlador.stream;

  Future<void> _iniciar() async {
    _suscripcionCambios = cambios.listen((_) => _solicitar());
    try {
      final cache = await leerCache();
      if (cache != null && !_cerrado) {
        await _emitir(await aplicarPendientes(cache));
      }
    } catch (_) {
      // Si falla, se sigue igual.
    }
    if (_cerrado) return;
    unawaited(_solicitar());
    _temporizador = Timer.periodic(intervalo, (_) => _solicitar());
  }

  Future<void> _detener() async {
    _cerrado = true;
    _temporizador?.cancel();
    await _suscripcionCambios?.cancel();
  }

  Future<void> _solicitar() async {
    if (_cerrado) return;
    if (_ocupado) {
      _repetir = true;
      return;
    }
    _ocupado = true;
    try {
      do {
        _repetir = false;
        await _ciclo();
      } while (_repetir && !_cerrado);
    } finally {
      _ocupado = false;
    }
  }

  Future<void> _ciclo() async {
    dynamic json;
    try {
      json = await consultar();
      try {
        await guardarCache(json);
      } catch (_) {}
    } catch (_) {
      try {
        json = await leerCache();
      } catch (_) {}
      json ??= vacio;
    }
    if (_cerrado) return;
    await _emitir(await aplicarPendientes(json));
  }

  Future<void> _emitir(dynamic json) async {
    if (_cerrado) return;
    final huella = jsonEncode(json);
    if (huella == _ultimaHuella) return;
    try {
      final valor = await convertir(json);
      if (_cerrado) return;
      _ultimaHuella = huella;
      _controlador.add(valor);
    } catch (e, pila) {
      if (!_cerrado) _controlador.addError(e, pila);
    }
  }
}
