import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:oncuidar/caracteristicas/chat/dominio/conversacion.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';

class RepositorioConversaciones {
  RepositorioConversaciones(this.bd);

  final BaseDatosSegura bd;

  CollectionReference _conversaciones() =>
      bd.docUsuario.collection('conversaciones');

  Stream<List<Conversacion>> conversacionesEnTiempoReal() {
    if (!bd.tieneIdentidad()) return Stream.value(const []);
    return _conversaciones()
        .orderBy('ultimaActividad', descending: true)
        .limit(50)
        .snapshots()
        .asyncMap(
          (snap) => Future.wait(
            snap.docs.map(
              (d) => _descifrarConversacion(
                d.id,
                d.data() as Map<String, dynamic>,
              ),
            ),
          ),
        );
  }

  Future<String> crearConversacion({
    required String titulo,
    required List<MensajeConversacion> mensajes,
  }) async {
    final datos = <String, dynamic>{
      'mensajes_cifrado': await bd.cifrado.cifrar(
        bd.uid,
        jsonEncode([for (final mensaje in mensajes) mensaje.aMapa()]),
      ),
      'ultimaActividad': DateTime.now(),
      'creadoEn': DateTime.now(),
      'version_encriptacion': 3,
    };
    await bd.reemplazarPorCifrado(
      datos,
      plano: titulo,
      cifrado: 'titulo_cifrado',
    );
    final ref = _conversaciones().doc();
    await bd.sinEsperarSinRed(() => ref.set(datos));
    return ref.id;
  }

  Future<void> actualizarConversacion(
    String id, {
    String? titulo,
    required List<MensajeConversacion> mensajes,
  }) async {
    final datos = <String, dynamic>{
      'mensajes_cifrado': await bd.cifrado.cifrar(
        bd.uid,
        jsonEncode([for (final mensaje in mensajes) mensaje.aMapa()]),
      ),
      'ultimaActividad': DateTime.now(),
    };
    if (titulo != null) {
      await bd.reemplazarPorCifrado(
        datos,
        plano: titulo,
        cifrado: 'titulo_cifrado',
      );
    }
    await bd.sinEsperarSinRed(
      () => _conversaciones().doc(id).set(datos, SetOptions(merge: true)),
    );
  }

  Future<void> renombrarConversacion(String id, String titulo) async {
    final datos = <String, dynamic>{};
    await bd.reemplazarPorCifrado(
      datos,
      plano: titulo,
      cifrado: 'titulo_cifrado',
    );
    await bd.sinEsperarSinRed(
      () => _conversaciones().doc(id).set(datos, SetOptions(merge: true)),
    );
  }

  /// Elimina definitivamente una conversación.
  Future<void> eliminarConversacion(String id) async {
    await bd.sinEsperarSinRed(() => _conversaciones().doc(id).delete());
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
    final cifrado = datos['mensajes_cifrado'] as String?;
    if (cifrado != null && cifrado.isNotEmpty) {
      try {
        final texto = await bd.cifrado.descifrar(bd.uid, cifrado);
        final lista = jsonDecode(texto) as List<dynamic>;
        return [
          for (final item in lista.cast<Map<String, dynamic>>())
            MensajeConversacion.desdeMapa(item),
        ];
      } catch (e, pila) {
        debugPrint('No se pudo descifrar mensajes_cifrado: $e\n$pila');
      }
    }
    final mensajesRaw = datos['mensajes'];
    if (mensajesRaw is List) {
      return [
        for (final item in mensajesRaw.cast<Map<String, dynamic>>())
          MensajeConversacion.desdeMapa(item),
      ];
    }
    return const [];
  }
}
