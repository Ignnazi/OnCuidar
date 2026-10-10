import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:oncuidar/caracteristicas/chat/dominio/conversacion.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
import 'package:oncuidar/nucleo/datos/rutas_api.dart';
import 'package:oncuidar/nucleo/sincronizacion/cola_escrituras.dart';
import 'package:uuid/uuid.dart';

class RepositorioConversaciones {
  RepositorioConversaciones(this.bd);

  final BaseDatosSegura bd;

  Stream<List<Conversacion>> conversacionesEnTiempoReal() {
    if (!bd.tieneIdentidad()) return Stream.value(const []);
    return bd.flujo<List<Conversacion>>(
      '${RutasApi.conversaciones}?limite=50',
      convertir: (json) async {
        final lista = await Future.wait([
          for (final e in json as List)
            _descifrarConversacion(
              (e as Map)['id'] as String,
              e.cast<String, dynamic>(),
            ),
        ]);
        return lista
          ..sort((a, b) => b.ultimaActividad.compareTo(a.ultimaActividad));
      },
    );
  }

  Future<String> crearConversacion({
    required String titulo,
    required List<MensajeConversacion> mensajes,
  }) async {
    final ahora = DateTime.now().toUtc().toIso8601String();
    final datos = <String, dynamic>{
      'ultimaActividad': ahora,
      'creadoEn': ahora,
      'versionEncriptacion': 3,
    };
    bd.ponerCifrado(datos, 'mensajes_cifrado', await _cifrarMensajes(mensajes));
    await bd.reemplazarPorCifrado(
      datos,
      plano: titulo,
      cifrado: 'titulo_cifrado',
    );
    final id = const Uuid().v4();
    await bd.escribir(
      RutasApi.conversacion(id),
      datos,
      operacion: OperacionPendiente.crear,
    );
    return id;
  }

  Future<void> actualizarConversacion(
    String id, {
    String? titulo,
    required List<MensajeConversacion> mensajes,
  }) async {
    final datos = <String, dynamic>{
      'ultimaActividad': DateTime.now().toUtc().toIso8601String(),
    };
    bd.ponerCifrado(datos, 'mensajes_cifrado', await _cifrarMensajes(mensajes));
    if (titulo != null) {
      await bd.reemplazarPorCifrado(
        datos,
        plano: titulo,
        cifrado: 'titulo_cifrado',
      );
    }
    await bd.escribir(
      RutasApi.conversacion(id),
      datos,
      operacion: OperacionPendiente.guardar,
    );
  }

  Future<void> renombrarConversacion(String id, String titulo) async {
    final datos = <String, dynamic>{};
    await bd.reemplazarPorCifrado(
      datos,
      plano: titulo,
      cifrado: 'titulo_cifrado',
    );
    await bd.escribir(
      RutasApi.conversacion(id),
      datos,
      operacion: OperacionPendiente.fusionar,
    );
  }

  /// Elimina definitivamente una conversación.
  Future<void> eliminarConversacion(String id) =>
      bd.borrar(RutasApi.conversacion(id), null);

  Future<String> _cifrarMensajes(List<MensajeConversacion> mensajes) {
    return bd.cifrado.cifrar(
      bd.uid,
      jsonEncode([for (final mensaje in mensajes) mensaje.aMapa()]),
    );
  }

  Future<Conversacion> _descifrarConversacion(
    String id,
    Map<String, dynamic> datos,
  ) async {
    return Conversacion(
      id: id,
      titulo: (await bd.descifrarCampo(datos, 'titulo_cifrado')) ?? '',
      ultimaActividad: bd.fechaTolerante(datos['ultimaActividad']),
      creadoEn: bd.fechaTolerante(datos['creadoEn']),
      mensajes: await _descifrarMensajesConversacion(datos),
    );
  }

  Future<List<MensajeConversacion>> _descifrarMensajesConversacion(
    Map<String, dynamic> datos,
  ) async {
    final cifrado = bd.textoCifrado(datos, 'mensajes_cifrado');
    if (cifrado == null || cifrado.isEmpty) return const [];
    try {
      final texto = await bd.cifrado.descifrar(bd.uid, cifrado);
      final lista = jsonDecode(texto) as List<dynamic>;
      return [
        for (final item in lista.cast<Map<String, dynamic>>())
          MensajeConversacion.desdeMapa(item),
      ];
    } catch (e, pila) {
      debugPrint('No se pudo descifrar mensajes_cifrado: $e\n$pila');
      return const [];
    }
  }
}
