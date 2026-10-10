import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:oncuidar/caracteristicas/recordatorios/dominio/recordatorio.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
import 'package:oncuidar/nucleo/datos/rutas_api.dart';
import 'package:oncuidar/nucleo/notificaciones/servicio_notificaciones.dart';
import 'package:oncuidar/nucleo/sincronizacion/cola_escrituras.dart';
import 'package:uuid/uuid.dart';

class RepositorioRecordatorios {
  RepositorioRecordatorios(this.bd);

  final BaseDatosSegura bd;

  String _rutaLista(String idPaciente) =>
      '${RutasApi.recordatorios(idPaciente)}?limite=100';

  Stream<List<Recordatorio>> recordatoriosEnTiempoReal(String idPaciente) {
    if (!bd.tieneIdentidad()) return Stream.value(const []);
    return bd.flujo<List<Recordatorio>>(
      _rutaLista(idPaciente),
      convertir: (json) async {
        final lista = await Future.wait([
          for (final e in json as List)
            _descifrarRecordatorio(
              (e as Map)['id'] as String,
              e.cast<String, dynamic>(),
            ),
        ]);
        return lista..sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
      },
    );
  }

  Future<String> agregarRecordatorio(String idPaciente, Recordatorio r) async {
    if (r.pacienteId != idPaciente) {
      throw ArgumentError(
        'El recordatorio pertenece a "${r.pacienteId}", no a "$idPaciente"',
      );
    }
    await bd.verificarEscrituraDisponible();
    final datos = <String, dynamic>{
      'pacienteId': r.pacienteId,
      'activo': r.activo,
      'creadoEn': r.creadoEn.toUtc().toIso8601String(),
      'versionEncriptacion': 3,
    };
    bd.ponerCifrado(
      datos,
      'datos_cifrados',
      await _cifrarPayloadRecordatorio(r),
    );
    await bd.reemplazarPorCifrado(
      datos,
      plano: r.titulo,
      cifrado: 'titulo_cifrado',
    );
    if (r.descripcion != null && r.descripcion!.isNotEmpty) {
      await bd.reemplazarPorCifrado(
        datos,
        plano: r.descripcion,
        cifrado: 'descripcion_cifrada',
      );
    }
    final id = const Uuid().v4();
    await bd.escribir(
      RutasApi.recordatorio(idPaciente, id),
      datos,
      operacion: OperacionPendiente.crear,
      idPaciente: idPaciente,
    );
    return id;
  }

  Future<void> actualizarRecordatorio(
    String idPaciente,
    String idRecordatorio, {
    String? tipo,
    String? titulo,
    String? descripcion,
    DateTime? fechaHora,
    List<String>? diasRepeticion,
    String? recurrencia,
    String? asignadoA,
    bool? activo,
  }) async {
    final cifraAlgo =
        titulo != null ||
        descripcion != null ||
        tipo != null ||
        fechaHora != null ||
        diasRepeticion != null ||
        recurrencia != null ||
        asignadoA != null;
    if (cifraAlgo) await bd.verificarEscrituraDisponible();
    final datos = <String, dynamic>{};
    if (titulo != null) {
      await bd.reemplazarPorCifrado(
        datos,
        plano: titulo,
        cifrado: 'titulo_cifrado',
      );
    }
    if (descripcion != null) {
      await bd.reemplazarPorCifrado(
        datos,
        plano: descripcion,
        cifrado: 'descripcion_cifrada',
      );
    }
    final tocaPayload =
        tipo != null ||
        fechaHora != null ||
        diasRepeticion != null ||
        recurrencia != null ||
        asignadoA != null;
    if (tocaPayload) {
      final sensibles = await _datosSensiblesActuales(
        idPaciente,
        idRecordatorio,
      );
      if (tipo != null) sensibles['tipo'] = tipo;
      if (fechaHora != null) {
        sensibles['fechaHora'] = fechaHora.toIso8601String();
      }
      if (diasRepeticion != null) {
        sensibles['diasRepeticion'] = diasRepeticion;
      }
      if (recurrencia != null) {
        if (recurrencia.isEmpty) {
          sensibles.remove('recurrencia');
        } else {
          sensibles['recurrencia'] = recurrencia;
        }
      }
      if (asignadoA != null) sensibles['asignadoA'] = asignadoA;
      sensibles.remove('completadoEn');
      bd.ponerCifrado(
        datos,
        'datos_cifrados',
        await bd.cifrado.cifrar(bd.uid, jsonEncode(sensibles)),
      );
    }
    if (activo != null) datos['activo'] = activo;
    if (datos.isEmpty) return;
    datos['pacienteId'] = idPaciente;
    await bd.escribir(
      RutasApi.recordatorio(idPaciente, idRecordatorio),
      datos,
      operacion: OperacionPendiente.fusionar,
      idPaciente: idPaciente,
    );
  }

  /// Elimina definitivamente un recordatorio.
  Future<void> eliminarRecordatorio(
    String idPaciente,
    String idRecordatorio,
  ) async {
    await bd.borrar(
      RutasApi.recordatorio(idPaciente, idRecordatorio),
      idPaciente,
    );
  }

  Future<Recordatorio> _descifrarRecordatorio(
    String id,
    Map<String, dynamic> datos,
  ) async {
    final sensibles = await _datosSensiblesRecordatorio(datos);
    return Recordatorio(
      id: id,
      pacienteId: (datos['pacienteId'] as String?) ?? '',
      tipo: (sensibles['tipo'] as String?) ?? 'otro',
      titulo: (await bd.descifrarCampo(datos, 'titulo_cifrado')) ?? '',
      descripcion: await bd.descifrarCampo(datos, 'descripcion_cifrada'),
      fechaHora: bd.fechaTolerante(sensibles['fechaHora']),
      diasRepeticion:
          (sensibles['diasRepeticion'] as List<dynamic>?)
              ?.map((d) => d.toString())
              .toList() ??
          const [],
      activo: (datos['activo'] as bool?) ?? true,
      recurrencia: sensibles['recurrencia'] as String?,
      asignadoA:
          (sensibles['asignadoA'] as String?) ?? Recordatorio.asignadoAPaciente,
      creadoEn: bd.fechaTolerante(datos['creadoEn']),
    );
  }

  Future<String> _cifrarPayloadRecordatorio(Recordatorio r) {
    return bd.cifrado.cifrar(
      bd.uid,
      jsonEncode(<String, dynamic>{
        'tipo': r.tipo,
        'fechaHora': r.fechaHora.toIso8601String(),
        'diasRepeticion': r.diasRepeticion,
        if (r.recurrencia != null) 'recurrencia': r.recurrencia,
        'asignadoA': r.asignadoA,
      }),
    );
  }

  Future<Map<String, dynamic>> _datosSensiblesRecordatorio(
    Map<String, dynamic> datos, {
    bool estricto = false,
  }) async {
    final cifrado = bd.textoCifrado(datos, 'datos_cifrados');
    if (cifrado == null || cifrado.isEmpty) return <String, dynamic>{};
    try {
      final texto = await bd.cifrado.descifrar(bd.uid, cifrado);
      return jsonDecode(texto) as Map<String, dynamic>;
    } catch (e, pila) {
      if (estricto) rethrow;
      debugPrint('No se pudo descifrar datos_cifrados: $e\n$pila');
      return <String, dynamic>{};
    }
  }

  Future<Map<String, dynamic>> _datosSensiblesActuales(
    String idPaciente,
    String idRecordatorio,
  ) async {
    final local = await _payloadEncolado(idPaciente, idRecordatorio);
    if (local != null) return local;
    final lista = await bd.leerConCache(_rutaLista(idPaciente)) as List;
    for (final e in lista) {
      if (e is Map && e['id'] == idRecordatorio) {
        return _datosSensiblesRecordatorio(
          e.cast<String, dynamic>(),
          estricto: true,
        );
      }
    }
    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>?> _payloadEncolado(
    String idPaciente,
    String idRecordatorio,
  ) async {
    final cola = bd.cola;
    if (cola == null) return null;
    final ruta = RutasApi.recordatorio(idPaciente, idRecordatorio);
    final pendientes = await cola.pendientes(bd.uid);
    final propias = <EscrituraPendiente>[
      for (final e in pendientes)
        if (e.ruta == ruta) e,
    ]..sort((a, b) => a.encoladoEn.compareTo(b.encoladoEn));
    for (final e in propias.reversed) {
      final cifrado = bd.textoCifrado(e.datos, 'datos_cifrados');
      if (cifrado == null || cifrado.isEmpty) continue;
      final texto = await bd.cifrado.descifrar(bd.uid, cifrado);
      return jsonDecode(texto) as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> cancelarNotificacionesPaciente(
    String idPaciente,
    ServicioNotificaciones notif,
  ) async {
    try {
      final lista = await bd.leerConCache(_rutaLista(idPaciente)) as List;
      for (final e in lista) {
        await notif.cancelar(
          ServicioNotificaciones.idSeguro((e as Map)['id'] as String),
        );
      }
    } catch (_) {
      // Si falla, se sigue igual.
    }
  }
}
