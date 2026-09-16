import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../modelos/paciente.dart';
import '../../modelos/registro_clinico.dart';
import 'servicio_cifrado.dart';

class ServicioBaseDatos {
  ServicioBaseDatos({
    FirebaseFirestore? base,
    this._auth,
    this._uidPrueba,
    required this._cifrado,
  }) : _base = base ?? FirebaseFirestore.instance;

  final FirebaseFirestore _base;
  final FirebaseAuth? _auth;
  final String? _uidPrueba;
  final ServicioCifrado _cifrado;

  String get _uid {
    if (_uidPrueba != null) return _uidPrueba;
    final auth = _auth ?? (throw StateError('No auth configured'));
    final usuario = auth.currentUser;
    if (usuario == null) throw StateError('No user authenticated');
    return usuario.uid;
  }

  DocumentReference get _docUsuario => _base.collection('users').doc(_uid);

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
    final datos = (doc.data() as Map<String, dynamic>?) ?? {};
    final correoPendiente = datos['pendiente_correo'] as String?;
    return {
      'email': datos['email'] as String?,
      'nombre': await _descifrarCampo(datos, 'nombre_cifrado'),
      'telefono': await _descifrarCampo(datos, 'telefono_cifrado'),
      'relacion': await _descifrarCampo(datos, 'relacion_cifrada'),
      'direccion': await _descifrarCampo(datos, 'direccion_cifrada'),
      'correoRespaldo': await _descifrarCampo(datos, 'correo_respaldo_cifrado'),
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
    await _docUsuario.set(plano, SetOptions(merge: true));
  }

  Future<String> crearPaciente(Paciente paciente) async {
    final ref = _docUsuario.collection('patients').doc();
    await ref.set(await _cifrarPaciente(paciente), SetOptions(merge: true));
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

  Future<void> archivarPaciente(String idPaciente) async {
    await _docUsuario.collection('patients').doc(idPaciente).set({
      'archivado': true,
    }, SetOptions(merge: true));
  }

  Future<void> desarchivarPaciente(String idPaciente) async {
    await _docUsuario.collection('patients').doc(idPaciente).set({
      'archivado': false,
    }, SetOptions(merge: true));
  }

  Future<void> eliminarPaciente(String idPaciente) async {
    await _docUsuario.collection('patients').doc(idPaciente).delete();
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

  Future<List<Paciente>> obtenerPacientes() async {
    final snap = await _docUsuario.collection('patients').get();
    final lista = <Paciente>[];
    for (final doc in snap.docs) {
      if (doc.data()['archivado'] == true) continue;
      lista.add(await _descifrarPaciente(doc.id, doc.data()));
    }
    return lista;
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
    final signos = registro.signosVitales;
    final datos = <String, dynamic>{
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
    await _registrosClinicos(
      idPaciente,
    ).doc(registro.id).set(datos, SetOptions(merge: true));
  }

  /// Elimina un registro clínico del paciente.
  Future<void> eliminarRegistroClinico(
    String idPaciente,
    String idRegistro,
  ) async {
    await _registrosClinicos(idPaciente).doc(idRegistro).delete();
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
    await usuario.reauthenticateWithCredential(credencial);
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
    await _usuarioAutenticado.verifyBeforeUpdateEmail(normalizado);
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
    }, SetOptions(merge: true));
    var confirmadoServidor = false;
    try {
      await FirebaseFunctions.instanceFor(
        region: 'southamerica-west1',
      ).httpsCallable('registerRecoveryEmail').call({'email': normalizado});
      confirmadoServidor = true;
      await _docUsuario.set({
        'pendiente_correo': normalizado,
        'pendiente_correo_tipo': 'respaldo',
        'pendiente_correo_solicitado_en': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Si falla, se sigue igual.
    }
    return confirmadoServidor;
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
