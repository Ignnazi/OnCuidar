import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const camposClinicosEnClaro = {
  'titulo',
  'descripcion',
  'observaciones',
  'mensajeAlerta',
  'sintomas',
  'signosVitales',
  'generalNotes',
  'alertMessage',
  'tipo',
  'fechaHora',
  'diasRepeticion',
  'recurrencia',
  'completadoEn',
};

enum OperacionPendiente { crear, fusionar, guardar, borrar }

class EscrituraPendiente {
  const EscrituraPendiente({
    required this.id,
    required this.ruta,
    required this.operacion,
    required this.datos,
    required this.pacienteId,
    required this.encoladoEn,
    this.intentos = 0,
  });

  final String id;

  final String ruta;
  final OperacionPendiente operacion;

  final Map<String, dynamic> datos;

  final String? pacienteId;
  final int encoladoEn;
  final int intentos;

  EscrituraPendiente conIntento() => EscrituraPendiente(
    id: id,
    ruta: ruta,
    operacion: operacion,
    datos: datos,
    pacienteId: pacienteId,
    encoladoEn: encoladoEn,
    intentos: intentos + 1,
  );

  EscrituraPendiente reiniciada() => EscrituraPendiente(
    id: id,
    ruta: ruta,
    operacion: operacion,
    datos: datos,
    pacienteId: pacienteId,
    encoladoEn: encoladoEn,
  );

  Map<String, dynamic> aMapa() => {
    'id': id,
    'ruta': ruta,
    'operacion': operacion.name,
    'datos': datos,
    'paciente_id': pacienteId,
    'encoladoEn': encoladoEn,
    'intentos': intentos,
  };

  factory EscrituraPendiente.desdeMapa(Map<String, dynamic> mapa) {
    return EscrituraPendiente(
      id: mapa['id'] as String,
      ruta: mapa['ruta'] as String,
      operacion: OperacionPendiente.values.byName(mapa['operacion'] as String),
      datos: Map<String, dynamic>.from(mapa['datos'] as Map),
      pacienteId: mapa['paciente_id'] as String?,
      encoladoEn: mapa['encoladoEn'] as int,
      intentos: (mapa['intentos'] as int?) ?? 0,
    );
  }
}

class CodecPayload {
  static dynamic codificar(dynamic valor) {
    if (valor is DateTime) return valor.toUtc().toIso8601String();
    if (valor is Map) {
      return {
        for (final e in valor.entries) e.key.toString(): codificar(e.value),
      };
    }
    if (valor is Iterable) return [for (final e in valor) codificar(e)];
    return valor;
  }
}

class ResumenCola {
  const ResumenCola({this.pendientes = 0, this.fallidas = 0});

  static const vacio = ResumenCola();

  final int pendientes;
  final int fallidas;

  @override
  bool operator ==(Object other) =>
      other is ResumenCola &&
      other.pendientes == pendientes &&
      other.fallidas == fallidas;

  @override
  int get hashCode => Object.hash(pendientes, fallidas);
}

class ColaEscrituras {
  ColaEscrituras();

  Future<void> _cerrojo = Future.value();
  final _cambios = StreamController<String>.broadcast();
  final _encolados = StreamController<void>.broadcast();

  String _clavePendientes(String uid) => 'oncuidar.cola_escrituras.$uid';
  String _claveFallidas(String uid) => 'oncuidar.cola_fallidas.$uid';

  /// Emite el uid cuyo contenido cambió.
  Stream<String> get cambios => _cambios.stream;

  /// Emite al encolar una escritura nueva.
  Stream<void> get encolados => _encolados.stream;

  Future<T> _serializar<T>(Future<T> Function() accion) {
    final resultado = _cerrojo.then((_) => accion());
    _cerrojo = resultado.then<void>((_) {}, onError: (_) {});
    return resultado;
  }

  Future<List<EscrituraPendiente>> _leer(String clave) async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(clave);
    if (texto == null || texto.isEmpty) return [];
    try {
      final lista = jsonDecode(texto) as List<dynamic>;
      return [
        for (final e in lista)
          EscrituraPendiente.desdeMapa(Map<String, dynamic>.from(e as Map)),
      ];
    } catch (e) {
      debugPrint('Cola de escrituras ilegible en $clave: $e');
      return [];
    }
  }

  Future<void> _guardar(String clave, List<EscrituraPendiente> lista) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      clave,
      jsonEncode([for (final e in lista) e.aMapa()]),
    );
  }

  Future<List<EscrituraPendiente>> pendientes(String uid) =>
      _serializar(() => _leer(_clavePendientes(uid)));

  Future<List<EscrituraPendiente>> fallidas(String uid) =>
      _serializar(() => _leer(_claveFallidas(uid)));

  Future<ResumenCola> resumen(String uid) async => ResumenCola(
    pendientes: (await pendientes(uid)).length,
    fallidas: (await fallidas(uid)).length,
  );

  Future<void> encolar(String uid, EscrituraPendiente escritura) async {
    final prohibidos = {
      for (final e in escritura.datos.entries)
        if (camposClinicosEnClaro.contains(e.key) && e.value != null) e.key,
    };
    if (prohibidos.isNotEmpty) {
      throw ArgumentError('Campos clínicos sin cifrar en la cola: $prohibidos');
    }
    await _serializar(() async {
      final lista = await _leer(_clavePendientes(uid));
      lista.add(escritura);
      await _guardar(_clavePendientes(uid), lista);
    });
    _cambios.add(uid);
    _encolados.add(null);
  }

  Future<void> quitar(String uid, String id) async {
    await _serializar(() async {
      final lista = await _leer(_clavePendientes(uid));
      lista.removeWhere((e) => e.id == id);
      await _guardar(_clavePendientes(uid), lista);
    });
    _cambios.add(uid);
  }

  Future<int> registrarIntento(String uid, String id) async {
    final total = await _serializar(() async {
      final lista = await _leer(_clavePendientes(uid));
      var intentos = 0;
      for (var i = 0; i < lista.length; i++) {
        if (lista[i].id == id) {
          lista[i] = lista[i].conIntento();
          intentos = lista[i].intentos;
        }
      }
      await _guardar(_clavePendientes(uid), lista);
      return intentos;
    });
    return total;
  }

  Future<void> moverAFallidas(String uid, String id) async {
    await _serializar(() async {
      final pendientes = await _leer(_clavePendientes(uid));
      final fallidas = await _leer(_claveFallidas(uid));
      final elemento = pendientes.where((e) => e.id == id).toList();
      if (elemento.isEmpty) return;
      fallidas.add(elemento.first);
      pendientes.removeWhere((e) => e.id == id);
      await _guardar(_clavePendientes(uid), pendientes);
      await _guardar(_claveFallidas(uid), fallidas);
    });
    _cambios.add(uid);
  }

  Future<void> quitarDePaciente(String uid, String pacienteId) async {
    await _serializar(() async {
      for (final clave in [_clavePendientes(uid), _claveFallidas(uid)]) {
        final lista = await _leer(clave);
        lista.removeWhere((e) => e.pacienteId == pacienteId);
        await _guardar(clave, lista);
      }
    });
    _cambios.add(uid);
  }

  Future<void> descartarFallidas(String uid) async {
    await _serializar(() => _guardar(_claveFallidas(uid), const []));
    _cambios.add(uid);
  }

  Future<void> reintentarFallidas(String uid) async {
    final movidas = await _serializar(() async {
      final fallidas = await _leer(_claveFallidas(uid));
      if (fallidas.isEmpty) return false;
      final pendientes = await _leer(_clavePendientes(uid));
      pendientes.addAll([for (final e in fallidas) e.reiniciada()]);
      await _guardar(_clavePendientes(uid), pendientes);
      await _guardar(_claveFallidas(uid), const []);
      return true;
    });
    _cambios.add(uid);
    if (movidas) _encolados.add(null);
  }
}
