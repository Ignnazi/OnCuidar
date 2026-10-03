import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';
import 'package:oncuidar/nucleo/conectividad/servicio_conectividad.dart';
import 'package:oncuidar/nucleo/sincronizacion/cola_escrituras.dart';

class BaseDatosSegura {
  BaseDatosSegura({
    FirebaseFirestore? base,
    this.auth,
    this._uidPrueba,
    required this.cifrado,
    this.cola,
    this.conectividad,
    this.limiteEscritura = const Duration(seconds: 8),
  }) : firestore = base ?? FirebaseFirestore.instance;

  final FirebaseFirestore firestore;
  final FirebaseAuth? auth;
  final String? _uidPrueba;
  final ServicioCifrado cifrado;
  final ColaEscrituras? cola;
  final ServicioConectividad? conectividad;
  final Duration limiteEscritura;

  String get uid {
    if (_uidPrueba != null) return _uidPrueba;
    final auth = this.auth ?? (throw StateError('No auth configured'));
    final usuario = auth.currentUser;
    if (usuario == null) throw StateError('No user authenticated');
    return usuario.uid;
  }

  DocumentReference get docUsuario => firestore.collection('usuarios').doc(uid);

  bool tieneIdentidad() {
    if (_uidPrueba != null) return true;
    final auth = this.auth;
    if (auth == null) return false;
    return auth.currentUser != null;
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
    DocumentReference ref,
    Map<String, dynamic> datos,
    OperacionPendiente operacion,
  ) async {
    switch (operacion) {
      case OperacionPendiente.crear:
        await ref.set(datos);
      case OperacionPendiente.guardar:
        await ref.set(datos, SetOptions(merge: true));
      case OperacionPendiente.borrar:
        await ref.delete();
      case OperacionPendiente.fusionar:
        try {
          await ref.update(datos);
        } on FirebaseException catch (e) {
          if (e.code != 'not-found') rethrow;
        }
    }
  }

  Future<void> sinEsperarSinRed(Future<void> Function() operacion) async {
    final conectividad = this.conectividad;
    final enLinea = conectividad == null || await conectividad.estaEnLinea();
    final pendiente = operacion();
    if (enLinea) return pendiente;
    unawaited(pendiente.catchError((_) {}));
  }

  void reflejarEnCache(
    DocumentReference ref,
    Map<String, dynamic> datos,
    OperacionPendiente operacion,
  ) {
    unawaited(aplicar(ref, datos, operacion).catchError((_) {}));
  }

  Future<void> encolar(
    DocumentReference ref,
    Map<String, dynamic> datos,
    OperacionPendiente operacion,
    String idPaciente,
  ) {
    final ahora = DateTime.now();
    return cola!.encolar(
      uid,
      EscrituraPendiente(
        id: '${ahora.microsecondsSinceEpoch}_${ref.id}',
        ruta: ref.path,
        operacion: operacion,
        datos: Map<String, dynamic>.from(CodecPayload.codificar(datos) as Map),
        pacienteId: idPaciente,
        encoladoEn: ahora.millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> escribir(
    DocumentReference ref,
    Map<String, dynamic> datos, {
    required OperacionPendiente operacion,
    required String idPaciente,
  }) async {
    if (!_conCola) {
      await aplicar(ref, datos, operacion);
      return;
    }
    if (!await conectividad!.estaEnLinea() ||
        await cola!.hayPendientesPara(uid, ref.path)) {
      await encolar(ref, datos, operacion, idPaciente);
      reflejarEnCache(ref, datos, operacion);
      return;
    }
    try {
      await aplicar(ref, datos, operacion).timeout(limiteEscritura);
    } on TimeoutException {
      await encolar(ref, datos, operacion, idPaciente);
    } on FirebaseException catch (e) {
      if (e.code != 'unavailable' && e.code != 'deadline-exceeded') rethrow;
      await encolar(ref, datos, operacion, idPaciente);
    }
  }

  Future<void> borrar(DocumentReference ref, String idPaciente) => escribir(
    ref,
    const {},
    operacion: OperacionPendiente.borrar,
    idPaciente: idPaciente,
  );

  Future<void> aplicarEscrituraPendiente(EscrituraPendiente escritura) async {
    final prefijo = 'usuarios/$uid/pacientes/${escritura.pacienteId}/';
    if (!escritura.ruta.startsWith(prefijo)) {
      throw ArgumentError(
        'La escritura pendiente no corresponde al paciente indicado',
      );
    }
    final ref = firestore.doc(escritura.ruta);
    final datos = Map<String, dynamic>.from(
      CodecPayload.decodificar(escritura.datos) as Map,
    );
    await aplicar(ref, datos, escritura.operacion).timeout(limiteEscritura);
  }

  Future<void> borrarColeccionEnLotes(CollectionReference coleccion) async {
    while (true) {
      final snap = await coleccion.limit(400).get();
      if (snap.docs.isEmpty) return;
      final lote = firestore.batch();
      for (final doc in snap.docs) {
        lote.delete(doc.reference);
      }
      await confirmarBorrado(lote.commit());
      if (snap.docs.length < 400) return;
    }
  }

  Future<void> confirmarBorrado(Future<void> operacion) async {
    try {
      await operacion.timeout(limiteEscritura);
    } on TimeoutException {
      // Si falla, se sigue igual.
    }
  }

  Future<void> reemplazarPorCifrado(
    Map<String, dynamic> data, {
    required String? plano,
    required String cifrado,
  }) async {
    if (plano == null || plano.isEmpty) {
      data[cifrado] = FieldValue.delete();
    } else {
      data[cifrado] = await this.cifrado.cifrar(uid, plano);
    }
  }

  Future<String?> descifrarCampo(
    Map<String, dynamic> datos,
    String campo,
  ) async {
    final cifrado = datos[campo] as String?;
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
    if (valor is Timestamp) return valor.toDate();
    if (valor is String) return DateTime.tryParse(valor) ?? DateTime.now();
    return DateTime.now();
  }
}
