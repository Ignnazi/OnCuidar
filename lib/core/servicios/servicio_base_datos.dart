import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../modelos/conversacion.dart';
import '../../modelos/material_educativo.dart';
import '../../modelos/paciente.dart';
import '../../modelos/recordatorio.dart';
import '../../modelos/registro_clinico.dart';
import 'cola_escrituras.dart';
import 'servicio_cifrado.dart';
import 'servicio_conectividad.dart';
import 'servicio_notificaciones.dart';

class ServicioBaseDatos {
  ServicioBaseDatos({
    FirebaseFirestore? base,
    this._auth,
    this._uidPrueba,
    required this._cifrado,
    this._cola,
    this._conectividad,
    this._limiteEscritura = const Duration(seconds: 8),
  }) : _base = base ?? FirebaseFirestore.instance;

  final FirebaseFirestore _base;
  final FirebaseAuth? _auth;
  final String? _uidPrueba;
  final ServicioCifrado _cifrado;
  final ColaEscrituras? _cola;
  final ServicioConectividad? _conectividad;
  final Duration _limiteEscritura;

  String get _uid {
    if (_uidPrueba != null) return _uidPrueba;
    final auth = _auth ?? (throw StateError('No auth configured'));
    final usuario = auth.currentUser;
    if (usuario == null) throw StateError('No user authenticated');
    return usuario.uid;
  }

  DocumentReference get _docUsuario => _base.collection('users').doc(_uid);

  bool get _conCola => _cola != null && _conectividad != null;

  Future<void> verificarEscrituraDisponible() async {
    if (!_conCola) return;
    if (await _conectividad!.estaEnLinea()) return;
    if (_cifrado.tieneClave(_uid)) return;
    if (await _cifrado.restaurarClave(_uid)) return;
    throw const ClaveNoDisponibleSinConexion();
  }

  Future<void> _aplicar(
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

  Future<void> _sinEsperarSinRed(Future<void> Function() operacion) async {
    final enLinea = _conectividad == null || await _conectividad.estaEnLinea();
    final pendiente = operacion();
    if (enLinea) return pendiente;
    unawaited(pendiente.catchError((_) {}));
  }

  void _reflejarEnCache(
    DocumentReference ref,
    Map<String, dynamic> datos,
    OperacionPendiente operacion,
  ) {
    unawaited(_aplicar(ref, datos, operacion).catchError((_) {}));
  }

  Future<void> _encolar(
    DocumentReference ref,
    Map<String, dynamic> datos,
    OperacionPendiente operacion,
    String idPaciente,
  ) {
    final ahora = DateTime.now();
    return _cola!.encolar(
      _uid,
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

  Future<void> _escribir(
    DocumentReference ref,
    Map<String, dynamic> datos, {
    required OperacionPendiente operacion,
    required String idPaciente,
  }) async {
    if (!_conCola) {
      await _aplicar(ref, datos, operacion);
      return;
    }
    if (!await _conectividad!.estaEnLinea() ||
        await _cola!.hayPendientesPara(_uid, ref.path)) {
      await _encolar(ref, datos, operacion, idPaciente);
      _reflejarEnCache(ref, datos, operacion);
      return;
    }
    try {
      await _aplicar(ref, datos, operacion).timeout(_limiteEscritura);
    } on TimeoutException {
      await _encolar(ref, datos, operacion, idPaciente);
    } on FirebaseException catch (e) {
      if (e.code != 'unavailable' && e.code != 'deadline-exceeded') rethrow;
      await _encolar(ref, datos, operacion, idPaciente);
    }
  }

  Future<void> _borrar(DocumentReference ref, String idPaciente) => _escribir(
    ref,
    const {},
    operacion: OperacionPendiente.borrar,
    idPaciente: idPaciente,
  );

  Future<void> aplicarEscrituraPendiente(EscrituraPendiente escritura) async {
    final prefijo = 'users/$_uid/patients/${escritura.pacienteId}/';
    if (!escritura.ruta.startsWith(prefijo)) {
      throw ArgumentError(
        'La escritura pendiente no corresponde al paciente indicado',
      );
    }
    final ref = _base.doc(escritura.ruta);
    final datos = Map<String, dynamic>.from(
      CodecPayload.decodificar(escritura.datos) as Map,
    );
    await _aplicar(ref, datos, escritura.operacion).timeout(_limiteEscritura);
  }

  Future<void> crearCuidador(Map<String, dynamic> datos) async {
    final plano = <String, dynamic>{};
    if (datos['email'] != null) plano['email'] = datos['email'];
    final correoRespaldo = datos['correo_respaldo'] as String?;
    if (correoRespaldo != null && correoRespaldo.isNotEmpty) {
      plano['correo_respaldo_cifrado'] = await _cifrado.cifrar(
        _uid,
        correoRespaldo.trim().toLowerCase(),
      );
    }
    if (datos['createdAt'] != null) plano['createdAt'] = datos['createdAt'];
    await _reemplazarPorCifrado(
      plano,
      plano: datos['displayName'] as String?,
      cifrado: 'nombre_cifrado',
    );
    await _reemplazarPorCifrado(
      plano,
      plano: datos['phone'] as String?,
      cifrado: 'telefono_cifrado',
    );
    await _reemplazarPorCifrado(
      plano,
      plano: datos['relationship'] as String?,
      cifrado: 'relacion_cifrada',
    );
    await _reemplazarPorCifrado(
      plano,
      plano: datos['address'] as String?,
      cifrado: 'direccion_cifrada',
    );
    plano['version_encriptacion'] = 2;
    await _docUsuario.set(plano, SetOptions(merge: true));
  }

  Future<void> limpiarRegistro(String uid) async {
    try {
      await _base.collection('users').doc(uid).delete();
    } catch (_) {}
  }

  Future<Map<String, dynamic>> obtenerCuidador() async {
    final doc = await _docUsuario.get();
    return _mapearCuidador((doc.data() as Map<String, dynamic>?) ?? {});
  }

  Stream<Map<String, dynamic>?> cuidadorEnTiempoReal() {
    if (!_tieneIdentidad()) return Stream.value(null);
    return _docUsuario.snapshots().asyncMap((doc) async {
      if (!doc.exists) return null;
      try {
        return await _mapearCuidador(
          (doc.data() as Map<String, dynamic>?) ?? {},
        );
      } catch (_) {
        return null;
      }
    });
  }

  Future<Map<String, dynamic>> _mapearCuidador(
    Map<String, dynamic> datos,
  ) async {
    final correoPendiente = datos['pendiente_correo'] as String?;
    return {
      'email': datos['email'] as String?,
      'nombre': await _descifrarCampo(datos, 'nombre_cifrado'),
      'telefono': await _descifrarCampo(datos, 'telefono_cifrado'),
      'relacion': await _descifrarCampo(datos, 'relacion_cifrada'),
      'direccion': await _descifrarCampo(datos, 'direccion_cifrada'),
      'correoRespaldo': await _descifrarCampo(datos, 'correo_respaldo_cifrado'),
      'respaldoPendienteServidor': datos['respaldo_pendiente_servidor'] == true,
      'pendienteCorreo': (correoPendiente == null || correoPendiente.isEmpty)
          ? null
          : {
              'correo': correoPendiente,
              'tipo':
                  (datos['pendiente_correo_tipo'] as String?) ?? 'principal',
            },
    };
  }

  Future<void> actualizarCuidador({
    String? nombre,
    String? telefono,
    String? relacion,
    String? direccion,
  }) async {
    final plano = <String, dynamic>{};
    if (nombre != null) {
      await _reemplazarPorCifrado(
        plano,
        plano: nombre,
        cifrado: 'nombre_cifrado',
      );
    }
    if (telefono != null) {
      await _reemplazarPorCifrado(
        plano,
        plano: telefono,
        cifrado: 'telefono_cifrado',
      );
    }
    if (relacion != null) {
      await _reemplazarPorCifrado(
        plano,
        plano: relacion,
        cifrado: 'relacion_cifrada',
      );
    }
    if (direccion != null) {
      await _reemplazarPorCifrado(
        plano,
        plano: direccion,
        cifrado: 'direccion_cifrada',
      );
    }
    if (plano.isEmpty) return;
    await _sinEsperarSinRed(
      () => _docUsuario.set(plano, SetOptions(merge: true)),
    );
  }

  Future<String> crearPaciente(Paciente paciente) async {
    final ref = _docUsuario.collection('patients').doc();
    final datos = await _cifrarPaciente(paciente);
    await _sinEsperarSinRed(() => ref.set(datos, SetOptions(merge: true)));
    return ref.id;
  }

  Future<void> actualizarPaciente(
    String idPaciente,
    Map<String, dynamic> datos,
  ) async {
    final plano = <String, dynamic>{};

    Future<void> campo({
      required String claveFormulario,
      required dynamic valor,
      required String clave,
    }) async {
      if (!datos.containsKey(claveFormulario)) return;
      final texto = valor?.toString();
      await _reemplazarPorCifrado(plano, plano: texto, cifrado: clave);
    }

    await campo(
      claveFormulario: 'fullName',
      valor: datos['fullName'],
      clave: 'nombre_cifrado',
    );
    await campo(
      claveFormulario: 'rut',
      valor: datos['rut'],
      clave: 'rut_cifrado',
    );
    await campo(
      claveFormulario: 'age',
      valor: datos['age'],
      clave: 'edad_cifrada',
    );
    await campo(
      claveFormulario: 'diagnosis',
      valor: datos['diagnosis'],
      clave: 'diagnostico_cifrado',
    );
    await campo(
      claveFormulario: 'tratamientoFase',
      valor: datos['tratamientoFase'],
      clave: 'fase_tratamiento_cifrado',
    );
    await campo(
      claveFormulario: 'centroSaludNombre',
      valor: datos['centroSaludNombre'],
      clave: 'centro_salud_nombre_cifrado',
    );
    await campo(
      claveFormulario: 'centroSaludDireccion',
      valor: datos['centroSaludDireccion'],
      clave: 'centro_salud_direccion_cifrado',
    );
    await campo(
      claveFormulario: 'centroSaludTelefono',
      valor: datos['centroSaludTelefono'],
      clave: 'centro_salud_telefono_cifrado',
    );
    await campo(
      claveFormulario: 'contactoEmergenciaNombre',
      valor: datos['contactoEmergenciaNombre'],
      clave: 'contacto_emergencia_nombre_cifrado',
    );
    await campo(
      claveFormulario: 'contactoEmergenciaTelefono',
      valor: datos['contactoEmergenciaTelefono'],
      clave: 'contacto_emergencia_telefono_cifrado',
    );
    if (datos['maximo_registros_dia'] is int) {
      plano['maximo_registros_dia'] = datos['maximo_registros_dia'];
    }
    if (plano.isEmpty) return;
    await _docUsuario
        .collection('patients')
        .doc(idPaciente)
        .set(plano, SetOptions(merge: true));
  }

  Future<void> archivarPaciente(
    String idPaciente, {
    ServicioNotificaciones? notif,
  }) async {
    await _sinEsperarSinRed(
      () => _docUsuario.collection('patients').doc(idPaciente).set({
        'archivado': true,
      }, SetOptions(merge: true)),
    );
    if (notif != null) await cancelarNotificacionesPaciente(idPaciente, notif);
  }

  Future<void> desarchivarPaciente(
    String idPaciente, {
    ServicioNotificaciones? notif,
  }) async {
    await _sinEsperarSinRed(
      () => _docUsuario.collection('patients').doc(idPaciente).set({
        'archivado': false,
      }, SetOptions(merge: true)),
    );
    if (notif != null) await reagendarNotificaciones(notif);
  }

  Future<void> eliminarPaciente(
    String idPaciente, {
    ServicioNotificaciones? notif,
  }) async {
    if (notif != null) await cancelarNotificacionesPaciente(idPaciente, notif);
    if (_cola != null) await _cola.quitarDePaciente(_uid, idPaciente);
    final docPaciente = _docUsuario.collection('patients').doc(idPaciente);
    for (final sub in subcoleccionesPaciente) {
      await _borrarColeccionEnLotes(docPaciente.collection(sub));
    }
    await _confirmarBorrado(docPaciente.delete());
  }

  static const subcoleccionesPaciente = ['clinicalRecords', 'recordatorios'];

  Future<void> _borrarColeccionEnLotes(CollectionReference coleccion) async {
    while (true) {
      final snap = await coleccion.limit(400).get();
      if (snap.docs.isEmpty) return;
      final lote = _base.batch();
      for (final doc in snap.docs) {
        lote.delete(doc.reference);
      }
      await _confirmarBorrado(lote.commit());
      if (snap.docs.length < 400) return;
    }
  }

  Future<void> _confirmarBorrado(Future<void> operacion) async {
    try {
      await operacion.timeout(_limiteEscritura);
    } on TimeoutException {
      // Si falla, se sigue igual.
    }
  }

  Future<void> cancelarNotificacionesPaciente(
    String idPaciente,
    ServicioNotificaciones notif,
  ) async {
    try {
      final snap = await _recordatorios(idPaciente).get();
      for (final doc in snap.docs) {
        await notif.cancelar(ServicioNotificaciones.idSeguro(doc.id));
      }
    } catch (_) {
      // Si falla, se sigue igual.
    }
  }

  Stream<List<Paciente>> pacientesArchivadosEnTiempoReal() {
    return _docUsuario
        .collection('patients')
        .snapshots()
        .asyncMap(
          (snap) => Future.wait(
            snap.docs
                .where((d) => d.data()['archivado'] == true)
                .map((d) => _descifrarPaciente(d.id, d.data())),
          ),
        );
  }

  Stream<List<Paciente>> pacientesEnTiempoReal() {
    return _docUsuario
        .collection('patients')
        .snapshots()
        .asyncMap(
          (snap) => Future.wait(
            snap.docs
                .where((d) => d.data()['archivado'] != true)
                .map((d) => _descifrarPaciente(d.id, d.data())),
          ),
        );
  }

  CollectionReference _registrosClinicos(String idPaciente) => _docUsuario
      .collection('patients')
      .doc(idPaciente)
      .collection('clinicalRecords');

  Future<void> guardarRegistroClinico(
    String idPaciente,
    RegistroClinico registro,
  ) async {
    if (registro.pacienteId != idPaciente) {
      throw ArgumentError(
        'El registro pertenece a "${registro.pacienteId}", no a "$idPaciente"',
      );
    }
    await verificarEscrituraDisponible();
    final signos = registro.signosVitales;
    final datos = <String, dynamic>{
      'id': registro.id,
      'paciente_id': registro.pacienteId,
      'fecha': registro.fecha,
      'creadoEn': registro.creadoEn,
      'tipoRegistro': registro.tipoRegistro,
      'nivelAlerta': registro.nivelAlerta.name,
      if (signos != null)
        'signos_vitales_cifrado': await _cifrado.cifrar(
          _uid,
          jsonEncode({
            'temperature': signos.temperature,
            'heartRate': signos.heartRate,
            'oxygenSaturation': signos.oxygenSaturation,
            'respiratoryRate': signos.respiratoryRate,
          }),
        )
      else
        'signos_vitales_cifrado': FieldValue.delete(),
      'sintomas_cifrado': await _cifrado.cifrar(
        _uid,
        jsonEncode([
          for (final sintoma in registro.sintomas)
            {
              'name': sintoma.name,
              'intensity': sintoma.intensity,
              if (sintoma.notes != null && sintoma.notes!.isNotEmpty)
                'notes': sintoma.notes,
            },
        ]),
      ),
    };
    await _reemplazarPorCifrado(
      datos,
      plano: registro.observaciones,
      cifrado: 'contenido_registro_cifrado',
    );
    await _reemplazarPorCifrado(
      datos,
      plano: registro.mensajeAlerta,
      cifrado: 'mensaje_alerta_cifrado',
    );
    datos['version_encriptacion'] = 3;
    await _escribir(
      _registrosClinicos(idPaciente).doc(registro.id),
      datos,
      operacion: OperacionPendiente.guardar,
      idPaciente: idPaciente,
    );
  }

  /// Elimina un registro clínico del paciente.
  Future<void> eliminarRegistroClinico(
    String idPaciente,
    String idRegistro,
  ) async {
    await _borrar(_registrosClinicos(idPaciente).doc(idRegistro), idPaciente);
  }

  Stream<List<RegistroClinico>> registrosClinicosEnTiempoReal(
    String idPaciente,
  ) {
    if (!_tieneIdentidad()) return Stream.value(const []);
    return _registrosClinicos(idPaciente)
        .orderBy('creadoEn', descending: true)
        .limit(50)
        .snapshots()
        .asyncMap(
          (snap) => Future.wait(
            snap.docs.map(
              (d) => _descifrarRegistroClinico(
                d.id,
                d.data() as Map<String, dynamic>,
              ),
            ),
          ),
        );
  }

  Future<List<RegistroClinico>> cargarMasRegistrosClinicos(
    String idPaciente,
    DateTime ultimoCreadoEn,
  ) async {
    if (!_tieneIdentidad()) return const [];
    final snap = await _registrosClinicos(idPaciente)
        .orderBy('creadoEn', descending: true)
        .startAfter([Timestamp.fromDate(ultimoCreadoEn)])
        .limit(50)
        .get();
    final lista = <RegistroClinico>[];
    for (final doc in snap.docs) {
      lista.add(
        await _descifrarRegistroClinico(
          doc.id,
          doc.data() as Map<String, dynamic>,
        ),
      );
    }
    return lista;
  }

  Future<List<RegistroClinico>> registrosClinicosEnRango(
    String idPaciente, {
    DateTime? desde,
    DateTime? hasta,
  }) async {
    if (!_tieneIdentidad()) return const [];
    Query consulta = _registrosClinicos(idPaciente);
    if (desde != null) {
      consulta = consulta.where(
        'fecha',
        isGreaterThanOrEqualTo: Timestamp.fromDate(desde),
      );
    }
    if (hasta != null) {
      consulta = consulta.where('fecha', isLessThan: Timestamp.fromDate(hasta));
    }
    final snap = await consulta.orderBy('fecha').get();
    final lista = <RegistroClinico>[];
    for (final doc in snap.docs) {
      final registro = await _descifrarRegistroClinico(
        doc.id,
        doc.data() as Map<String, dynamic>,
      );
      if (registro.pacienteId.isEmpty || registro.pacienteId == idPaciente) {
        lista.add(registro);
      }
    }
    return lista;
  }

  CollectionReference _contenidoEducativo() =>
      _base.collection('educationalContent');

  Stream<List<MaterialEducativo>> contenidoEducativoEnTiempoReal() {
    return _contenidoEducativo().snapshots().map(
      (snap) => [
        for (final doc in snap.docs)
          MaterialEducativo.fromMap(doc.id, doc.data() as Map<String, dynamic>),
      ],
    );
  }

  Future<MaterialEducativo?> obtenerContenidoEducativo(String id) async {
    final doc = await _contenidoEducativo().doc(id).get();
    if (!doc.exists) return null;
    return MaterialEducativo.fromMap(
      doc.id,
      doc.data() as Map<String, dynamic>,
    );
  }

  Stream<List<String>> idsFavoritosEnTiempoReal() {
    if (!_tieneIdentidad()) return Stream.value(const []);
    return _docUsuario.snapshots().map((snap) {
      final datos = snap.data() as Map<String, dynamic>?;
      return List<String>.from(datos?['favoriteArticleIds'] ?? const []);
    });
  }

  Future<void> alternarFavorito(String materialId) async {
    var favoritos = <String>[];
    try {
      final doc = await _docUsuario.get(const GetOptions(source: Source.cache));
      final datos = doc.data() as Map<String, dynamic>?;
      favoritos = List<String>.from(datos?['favoriteArticleIds'] ?? const []);
    } catch (_) {
      try {
        final doc = await _docUsuario.get();
        final datos = doc.data() as Map<String, dynamic>?;
        favoritos = List<String>.from(datos?['favoriteArticleIds'] ?? const []);
      } catch (_) {
        favoritos = const [];
      }
    }
    if (favoritos.contains(materialId)) {
      favoritos.remove(materialId);
    } else {
      favoritos.add(materialId);
    }
    await _sinEsperarSinRed(
      () => _docUsuario.set({
        'favoriteArticleIds': favoritos,
      }, SetOptions(merge: true)),
    );
  }

  CollectionReference _conversaciones() =>
      _docUsuario.collection('conversations');

  Stream<List<Conversacion>> conversacionesEnTiempoReal() {
    if (!_tieneIdentidad()) return Stream.value(const []);
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
      'mensajes_cifrado': await _cifrado.cifrar(
        _uid,
        jsonEncode([for (final mensaje in mensajes) mensaje.aMapa()]),
      ),
      'ultimaActividad': DateTime.now(),
      'creadoEn': DateTime.now(),
      'version_encriptacion': 3,
    };
    await _reemplazarPorCifrado(
      datos,
      plano: titulo,
      cifrado: 'titulo_cifrado',
    );
    final ref = _conversaciones().doc();
    await _sinEsperarSinRed(() => ref.set(datos));
    return ref.id;
  }

  Future<void> actualizarConversacion(
    String id, {
    String? titulo,
    required List<MensajeConversacion> mensajes,
  }) async {
    final datos = <String, dynamic>{
      'mensajes_cifrado': await _cifrado.cifrar(
        _uid,
        jsonEncode([for (final mensaje in mensajes) mensaje.aMapa()]),
      ),
      'ultimaActividad': DateTime.now(),
    };
    if (titulo != null) {
      await _reemplazarPorCifrado(
        datos,
        plano: titulo,
        cifrado: 'titulo_cifrado',
      );
    }
    await _sinEsperarSinRed(
      () => _conversaciones().doc(id).set(datos, SetOptions(merge: true)),
    );
  }

  Future<void> renombrarConversacion(String id, String titulo) async {
    final datos = <String, dynamic>{};
    await _reemplazarPorCifrado(
      datos,
      plano: titulo,
      cifrado: 'titulo_cifrado',
    );
    await _sinEsperarSinRed(
      () => _conversaciones().doc(id).set(datos, SetOptions(merge: true)),
    );
  }

  /// Elimina definitivamente una conversación.
  Future<void> eliminarConversacion(String id) async {
    await _sinEsperarSinRed(() => _conversaciones().doc(id).delete());
  }

  Future<Conversacion> _descifrarConversacion(
    String id,
    Map<String, dynamic> datos,
  ) async {
    return Conversacion(
      id: id,
      titulo: (await _descifrarCampo(datos, 'titulo_cifrado')) ?? '',
      ultimaActividad: _fechaTolerante(datos['ultimaActividad']),
      creadoEn: _fechaTolerante(datos['creadoEn']),
      mensajes: await _descifrarMensajesConversacion(datos),
    );
  }

  Future<List<MensajeConversacion>> _descifrarMensajesConversacion(
    Map<String, dynamic> datos,
  ) async {
    final cifrado = datos['mensajes_cifrado'] as String?;
    if (cifrado != null && cifrado.isNotEmpty) {
      try {
        final texto = await _cifrado.descifrar(_uid, cifrado);
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

  CollectionReference _recordatorios(String idPaciente) => _docUsuario
      .collection('patients')
      .doc(idPaciente)
      .collection('recordatorios');

  Stream<List<Recordatorio>> recordatoriosEnTiempoReal(String idPaciente) {
    if (!_tieneIdentidad()) return Stream.value(const []);
    return _recordatorios(idPaciente)
        .orderBy('creadoEn', descending: true)
        .limit(100)
        .snapshots()
        .asyncMap(
          (snap) => Future.wait(
            snap.docs.map(
              (d) => _descifrarRecordatorio(
                d.id,
                d.data() as Map<String, dynamic>,
              ),
            ),
          ),
        );
  }

  Future<String> agregarRecordatorio(String idPaciente, Recordatorio r) async {
    if (r.pacienteId != idPaciente) {
      throw ArgumentError(
        'El recordatorio pertenece a "${r.pacienteId}", no a "$idPaciente"',
      );
    }
    await verificarEscrituraDisponible();
    final datos = <String, dynamic>{
      'pacienteId': r.pacienteId,
      'activo': r.activo,
      'creadoEn': r.creadoEn.toIso8601String(),
      'version_encriptacion': 3,
    };
    datos['datos_cifrados'] = await _cifrarPayloadRecordatorio(r);
    await _reemplazarPorCifrado(
      datos,
      plano: r.titulo,
      cifrado: 'titulo_cifrado',
    );
    if (r.descripcion != null && r.descripcion!.isNotEmpty) {
      await _reemplazarPorCifrado(
        datos,
        plano: r.descripcion,
        cifrado: 'descripcion_cifrada',
      );
    }
    final ref = _recordatorios(idPaciente).doc();
    await _escribir(
      ref,
      datos,
      operacion: OperacionPendiente.crear,
      idPaciente: idPaciente,
    );
    return ref.id;
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
    if (cifraAlgo) await verificarEscrituraDisponible();
    final datos = <String, dynamic>{};
    if (titulo != null) {
      await _reemplazarPorCifrado(
        datos,
        plano: titulo,
        cifrado: 'titulo_cifrado',
      );
    }
    if (descripcion != null) {
      if (descripcion.isEmpty) {
        datos['descripcion_cifrada'] = FieldValue.delete();
      } else {
        await _reemplazarPorCifrado(
          datos,
          plano: descripcion,
          cifrado: 'descripcion_cifrada',
        );
      }
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
      datos['datos_cifrados'] = await _cifrado.cifrar(
        _uid,
        jsonEncode(sensibles),
      );
      datos['tipo'] = FieldValue.delete();
      datos['fechaHora'] = FieldValue.delete();
      datos['diasRepeticion'] = FieldValue.delete();
      datos['recurrencia'] = FieldValue.delete();
      datos['completadoEn'] = FieldValue.delete();
    }
    if (activo != null) datos['activo'] = activo;
    if (datos.isEmpty) return;
    datos['pacienteId'] = idPaciente;
    await _escribir(
      _recordatorios(idPaciente).doc(idRecordatorio),
      datos,
      operacion: OperacionPendiente.fusionar,
      idPaciente: idPaciente,
    );
  }

  Future<void> eliminarRecordatorio(
    String idPaciente,
    String idRecordatorio,
  ) async {
    await _borrar(_recordatorios(idPaciente).doc(idRecordatorio), idPaciente);
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
      titulo: (await _descifrarCampo(datos, 'titulo_cifrado')) ?? '',
      descripcion: await _descifrarCampo(datos, 'descripcion_cifrada'),
      fechaHora: _fechaTolerante(sensibles['fechaHora']),
      diasRepeticion:
          (sensibles['diasRepeticion'] as List<dynamic>?)
              ?.map((d) => d.toString())
              .toList() ??
          const [],
      activo: (datos['activo'] as bool?) ?? true,
      recurrencia: sensibles['recurrencia'] as String?,
      asignadoA:
          (sensibles['asignadoA'] as String?) ?? Recordatorio.asignadoAPaciente,
      creadoEn: _fechaTolerante(datos['creadoEn']),
    );
  }

  Future<String> _cifrarPayloadRecordatorio(Recordatorio r) {
    return _cifrado.cifrar(
      _uid,
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
    final cifrado = datos['datos_cifrados'] as String?;
    if (cifrado != null && cifrado.isNotEmpty) {
      try {
        final texto = await _cifrado.descifrar(_uid, cifrado);
        return jsonDecode(texto) as Map<String, dynamic>;
      } catch (e, pila) {
        if (estricto) rethrow;
        debugPrint('No se pudo descifrar datos_cifrados: $e\n$pila');
        return <String, dynamic>{};
      }
    }
    return <String, dynamic>{
      if (datos['tipo'] != null) 'tipo': datos['tipo'],
      if (datos['fechaHora'] != null) 'fechaHora': datos['fechaHora'],
      if (datos['diasRepeticion'] != null)
        'diasRepeticion': datos['diasRepeticion'],
      if (datos['recurrencia'] != null) 'recurrencia': datos['recurrencia'],
    };
  }

  Future<Map<String, dynamic>> _datosSensiblesActuales(
    String idPaciente,
    String idRecordatorio,
  ) async {
    final local = await _payloadEncolado(idPaciente, idRecordatorio);
    if (local != null) return local;
    final snap = await _recordatorios(idPaciente).doc(idRecordatorio).get();
    final datos = snap.data();
    if (datos == null) return <String, dynamic>{};
    return _datosSensiblesRecordatorio(
      datos is Map<String, dynamic>
          ? datos
          : Map<String, dynamic>.from(datos as Map),
      estricto: true,
    );
  }

  Future<Map<String, dynamic>?> _payloadEncolado(
    String idPaciente,
    String idRecordatorio,
  ) async {
    final cola = _cola;
    if (cola == null) return null;
    final ruta = _recordatorios(idPaciente).doc(idRecordatorio).path;
    final pendientes = await cola.pendientes(_uid);
    final propias = <EscrituraPendiente>[
      for (final e in pendientes)
        if (e.ruta == ruta) e,
    ]..sort((a, b) => a.encoladoEn.compareTo(b.encoladoEn));
    for (final e in propias.reversed) {
      final cifrado = e.datos['datos_cifrados'];
      if (cifrado is! String || cifrado.isEmpty) continue;
      final texto = await _cifrado.descifrar(_uid, cifrado);
      return jsonDecode(texto) as Map<String, dynamic>;
    }
    return null;
  }

  String _etiquetaTipoRecordatorio(String tipo) => switch (tipo) {
    'medicamento' => 'Medicamento',
    'medicion' => 'Medición',
    'cita' => 'Cita médica',
    _ => 'Recordatorio',
  };

  Future<void> reagendarNotificaciones(ServicioNotificaciones notif) async {
    try {
      if (!_tieneIdentidad()) return;
      await notif.cancelarTodas();
      final pacientes = await pacientesEnTiempoReal().first;
      final ahora = DateTime.now();
      for (final paciente in pacientes) {
        try {
          final recordatorios = await recordatoriosEnTiempoReal(
            paciente.id,
          ).first;
          for (final r in recordatorios) {
            if (!r.activo) continue;
            if (r.titulo.isEmpty) continue;
            if (!r.esRecurrente && r.fechaHora.isBefore(ahora)) continue;
            await notif.programar(
              id: ServicioNotificaciones.idSeguro(r.id),
              titulo: r.tituloAviso(
                paciente.fullName,
                _etiquetaTipoRecordatorio(r.tipo),
              ),
              cuerpo: r.cuerpoAviso,
              fechaHora: r.fechaHora,
              diasRepeticion: r.diasRepeticion,
              mensual: r.esMensual,
            );
          }
        } catch (_) {
          // Si falla, se sigue igual.
        }
      }
    } catch (_) {
      // Si falla, se sigue igual.
    }
  }

  Future<void> _reautenticar(String contrasena) async {
    final usuario = _usuarioAutenticado;
    final email = usuario.email;
    if (email == null || email.isEmpty) {
      throw FirebaseAuthException(code: 'requires-recent-login');
    }
    final credencial = EmailAuthProvider.credential(
      email: email,
      password: contrasena,
    );
    await usuario
        .reauthenticateWithCredential(credencial)
        .timeout(const Duration(seconds: 5));
  }

  User get _usuarioAutenticado {
    final auth = _auth ?? FirebaseAuth.instance;
    final usuario = auth.currentUser;
    if (usuario == null) throw StateError('No user authenticated');
    return usuario;
  }

  Future<void> cambiarCorreoPrincipal({
    required String contrasena,
    required String nuevoCorreo,
  }) async {
    await _reautenticar(contrasena);
    final normalizado = nuevoCorreo.trim().toLowerCase();
    await _usuarioAutenticado
        .verifyBeforeUpdateEmail(normalizado)
        .timeout(const Duration(seconds: 5));
    await _docUsuario.set({
      'pendiente_correo': normalizado,
      'pendiente_correo_tipo': 'principal',
      'pendiente_correo_solicitado_en': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<bool> cambiarCorreoRespaldo({
    required String contrasena,
    required String nuevoCorreo,
  }) async {
    await _reautenticar(contrasena);
    final normalizado = nuevoCorreo.trim().toLowerCase();
    await _docUsuario.set({
      'correo_respaldo_cifrado': await _cifrado.cifrar(_uid, normalizado),
      'respaldo_pendiente_servidor': true,
    }, SetOptions(merge: true));
    return _registrarRespaldoEnServidor(normalizado);
  }

  @visibleForTesting
  Future<void> Function(String correo) registrarCorreoRespaldoServidor =
      (correo) => FirebaseFunctions.instanceFor(region: 'southamerica-west1')
          .httpsCallable('registerRecoveryEmail')
          .call({'email': correo})
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw FirebaseFunctionsException(
              code: 'unavailable',
              message: 'Sin conexión',
            ),
          );

  Future<bool> _registrarRespaldoEnServidor(String correo) async {
    try {
      await registrarCorreoRespaldoServidor(correo);
    } catch (e) {
      debugPrint('Registro del correo de respaldo pendiente: $e');
      return false;
    }
    await _docUsuario.set({
      'respaldo_pendiente_servidor': FieldValue.delete(),
    }, SetOptions(merge: true));
    return true;
  }

  Future<bool> reintentarRegistroRespaldo() async {
    final datos =
        ((await _docUsuario.get()).data() as Map<String, dynamic>?) ?? {};
    if (datos['respaldo_pendiente_servidor'] != true) return true;
    final correo = await _descifrarCampo(datos, 'correo_respaldo_cifrado');
    if (correo == null || correo.isEmpty) return false;
    return _registrarRespaldoEnServidor(correo);
  }

  Future<void> limpiarCambioCorreoPendiente() async {
    await _docUsuario.set({
      'pendiente_correo': FieldValue.delete(),
      'pendiente_correo_tipo': FieldValue.delete(),
      'pendiente_correo_solicitado_en': FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  Future<void> sincronizarCorreoPrincipal(String email) async {
    await _docUsuario.set({
      'email': email.trim().toLowerCase(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>> _cifrarPaciente(Paciente p) async {
    final data = <String, dynamic>{
      'notificaciones_activas': true,
      'maximo_registros_dia': 3,
      'creadoEn': FieldValue.serverTimestamp(),
    };
    await _reemplazarPorCifrado(
      data,
      plano: p.fullName,
      cifrado: 'nombre_cifrado',
    );
    await _reemplazarPorCifrado(data, plano: p.rut, cifrado: 'rut_cifrado');
    await _reemplazarPorCifrado(
      data,
      plano: p.age?.toString(),
      cifrado: 'edad_cifrada',
    );
    await _reemplazarPorCifrado(
      data,
      plano: p.diagnosis,
      cifrado: 'diagnostico_cifrado',
    );
    await _reemplazarPorCifrado(
      data,
      plano: p.tratamientoFase,
      cifrado: 'fase_tratamiento_cifrado',
    );
    await _reemplazarPorCifrado(
      data,
      plano: p.centroSaludNombre,
      cifrado: 'centro_salud_nombre_cifrado',
    );
    await _reemplazarPorCifrado(
      data,
      plano: p.centroSaludDireccion,
      cifrado: 'centro_salud_direccion_cifrado',
    );
    await _reemplazarPorCifrado(
      data,
      plano: p.centroSaludTelefono,
      cifrado: 'centro_salud_telefono_cifrado',
    );
    await _reemplazarPorCifrado(
      data,
      plano: p.contactoEmergenciaNombre,
      cifrado: 'contacto_emergencia_nombre_cifrado',
    );
    await _reemplazarPorCifrado(
      data,
      plano: p.contactoEmergenciaTelefono,
      cifrado: 'contacto_emergencia_telefono_cifrado',
    );
    data['version_encriptacion'] = 2;
    return data;
  }

  Future<void> _reemplazarPorCifrado(
    Map<String, dynamic> data, {
    required String? plano,
    required String cifrado,
  }) async {
    if (plano == null || plano.isEmpty) {
      data[cifrado] = FieldValue.delete();
    } else {
      data[cifrado] = await _cifrado.cifrar(_uid, plano);
    }
  }

  Future<Paciente> _descifrarPaciente(
    String id,
    Map<String, dynamic> datos,
  ) async {
    final nombre = await _descifrarCampo(datos, 'nombre_cifrado');
    final edad = await _descifrarCampo(datos, 'edad_cifrada');
    return Paciente(
      id: id,
      fullName: nombre ?? '',
      rut: await _descifrarCampo(datos, 'rut_cifrado'),
      age: int.tryParse(edad ?? ''),
      diagnosis: await _descifrarCampo(datos, 'diagnostico_cifrado'),
      tratamientoFase: await _descifrarCampo(datos, 'fase_tratamiento_cifrado'),
      centroSaludNombre: await _descifrarCampo(
        datos,
        'centro_salud_nombre_cifrado',
      ),
      centroSaludDireccion: await _descifrarCampo(
        datos,
        'centro_salud_direccion_cifrado',
      ),
      centroSaludTelefono: await _descifrarCampo(
        datos,
        'centro_salud_telefono_cifrado',
      ),
      contactoEmergenciaNombre: await _descifrarCampo(
        datos,
        'contacto_emergencia_nombre_cifrado',
      ),
      contactoEmergenciaTelefono: await _descifrarCampo(
        datos,
        'contacto_emergencia_telefono_cifrado',
      ),
      createdAt: (datos['creadoEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
      maximoRegistrosDia: (datos['maximo_registros_dia'] as num?)?.toInt() ?? 3,
    );
  }

  Future<String?> _descifrarCampo(
    Map<String, dynamic> datos,
    String campo,
  ) async {
    final cifrado = datos[campo] as String?;
    if (cifrado == null || cifrado.isEmpty) return null;
    try {
      return await _cifrado.descifrar(_uid, cifrado);
    } catch (e, pila) {
      debugPrint('No se pudo descifrar $campo: $e\n$pila');
      return null;
    }
  }

  Future<SignosVitales?> _descifrarSignosVitales(
    Map<String, dynamic> datos,
  ) async {
    final cifrado = datos['signos_vitales_cifrado'] as String?;
    if (cifrado != null && cifrado.isNotEmpty) {
      try {
        final texto = await _cifrado.descifrar(_uid, cifrado);
        final mapa = jsonDecode(texto) as Map<String, dynamic>;
        return SignosVitales(
          temperature: (mapa['temperature'] as num?)?.toDouble(),
          heartRate: (mapa['heartRate'] as num?)?.toInt(),
          oxygenSaturation: (mapa['oxygenSaturation'] as num?)?.toInt(),
          respiratoryRate: (mapa['respiratoryRate'] as num?)?.toInt(),
        );
      } catch (e, pila) {
        debugPrint('No se pudo descifrar signos_vitales_cifrado: $e\n$pila');
      }
    }
    final signosMapa = datos['signosVitales'];
    if (signosMapa is Map<String, dynamic>) {
      return SignosVitales(
        temperature: (signosMapa['temperature'] as num?)?.toDouble(),
        heartRate: signosMapa['heartRate'] as int?,
        oxygenSaturation: signosMapa['oxygenSaturation'] as int?,
        respiratoryRate: signosMapa['respiratoryRate'] as int?,
      );
    }
    return null;
  }

  Future<List<EntradaSintoma>> _descifrarSintomas(
    Map<String, dynamic> datos,
  ) async {
    final cifrado = datos['sintomas_cifrado'] as String?;
    if (cifrado != null && cifrado.isNotEmpty) {
      try {
        final texto = await _cifrado.descifrar(_uid, cifrado);
        final lista = jsonDecode(texto) as List<dynamic>;
        return [
          for (final item in lista)
            EntradaSintoma(
              name: (item['name'] as String?) ?? '',
              intensity: (item['intensity'] as num?)?.toInt() ?? 0,
              notes: item['notes'] as String?,
            ),
        ];
      } catch (e, pila) {
        debugPrint('No se pudo descifrar sintomas_cifrado: $e\n$pila');
      }
    }
    final sintomasRaw = datos['sintomas'];
    if (sintomasRaw is List) {
      final sintomas = <EntradaSintoma>[];
      for (final item in sintomasRaw.cast<Map<String, dynamic>>()) {
        final notesCifradas = item['notes_cifrado'] as String?;
        final notas = (notesCifradas != null && notesCifradas.isNotEmpty)
            ? await _descifrarCampo(item, 'notes_cifrado')
            : item['notes'] as String?;
        sintomas.add(
          EntradaSintoma(
            name: (item['name'] as String?) ?? '',
            intensity: (item['intensity'] as num?)?.toInt() ?? 0,
            notes: notas,
          ),
        );
      }
      return sintomas;
    }
    return const [];
  }

  Future<RegistroClinico> _descifrarRegistroClinico(
    String id,
    Map<String, dynamic> datos,
  ) async {
    final signos = await _descifrarSignosVitales(datos);
    final sintomas = await _descifrarSintomas(datos);

    final contenidoCifrado = datos['contenido_registro_cifrado'] as String?;
    final observaciones =
        (contenidoCifrado != null && contenidoCifrado.isNotEmpty)
        ? await _descifrarCampo(datos, 'contenido_registro_cifrado')
        : datos['observaciones'] as String?;

    final nivelRaw = datos['nivelAlerta'] as String?;
    final nivel = NivelAlerta.values.firstWhere(
      (v) => v.name == nivelRaw,
      orElse: () => NivelAlerta.normal,
    );

    return RegistroClinico(
      id: id,
      pacienteId: (datos['paciente_id'] as String?) ?? '',
      fecha: _fechaTolerante(datos['fecha']),
      creadoEn: _fechaTolerante(datos['creadoEn']),
      tipoRegistro: (datos['tipoRegistro'] as String?) ?? 'programado',
      signosVitales: signos,
      sintomas: sintomas,
      observaciones: observaciones,
      nivelAlerta: nivel,
      mensajeAlerta: await _descifrarCampo(datos, 'mensaje_alerta_cifrado'),
    );
  }

  DateTime _fechaTolerante(Object? valor) {
    if (valor is DateTime) return valor;
    if (valor is Timestamp) return valor.toDate();
    if (valor is String) return DateTime.tryParse(valor) ?? DateTime.now();
    return DateTime.now();
  }

  bool _tieneIdentidad() {
    if (_uidPrueba != null) return true;
    final auth = _auth;
    if (auth == null) return false;
    return auth.currentUser != null;
  }
}
