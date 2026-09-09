import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../modelos/paciente.dart';
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

  // ── Cuidador ──
  /// Guarda al cuidador cifrando los datos personales.
  Future<void> crearCuidador(Map<String, dynamic> datos) async {
    final plano = <String, dynamic>{};
    // Solo el servidor (registerRecoveryEmail) escribe correo_respaldo_hash.
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

  /// Rollback tras un registro fallido: borra el doc del usuario (la cuenta de
  /// Auth ya se eliminó en ServicioRegistro). Best-effort; si el doc no existe
  /// o la red falla, se ignora para no enmascarar el error original.
  Future<void> limpiarRegistro(String uid) async {
    try {
      await _base.collection('users').doc(uid).delete();
    } catch (_) {}
  }

  /// Devuelve los datos visibles del cuidador con sus campos personales ya
  /// descifrados. El correo se devuelve en texto plano por ser el
  /// identificador de acceso.
  ///
  /// `correoRespaldo` es el correo de respaldo descifrado (solo existe si se
  /// registró vía la app; los usuarios legacy que solo tienen `correo_respaldo_hash`
  /// devolverán null porque un hash no se puede invertir).
  /// `pendienteCorreo` expone el estado "verificación pendiente" de un cambio
  /// de correo (principal o respaldo), o null si no hay ningún cambio pendiente.
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

  /// Actualiza los datos personales del cuidador cifrando solo los campos
  /// no nulos. Un campo vacío (teléfono/parentesco) se borra; el nombre se
  /// trata igual que el resto para mantener el contrato simple.
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

  // ── Paciente ──
  Future<String> crearPaciente(Paciente paciente) async {
    final ref = _docUsuario.collection('patients').doc();
    await ref.set(await _cifrarPaciente(paciente), SetOptions(merge: true));
    return ref.id;
  }

  /// Actualiza un paciente cifrando solo los campos editables presentes en
  /// [datos]. Usa `set` con merge para conservar los campos fijos.
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
    if (plano.isEmpty) return;
    await _docUsuario
        .collection('patients')
        .doc(idPaciente)
        .set(plano, SetOptions(merge: true));
  }

  /// Borrado LÓGICO del paciente: escribe `archivado: true` (en claro).
  /// Los datos se conservan pero deja de aparecer en las lecturas activas.
  Future<void> archivarPaciente(String idPaciente) async {
    await _docUsuario.collection('patients').doc(idPaciente).set({
      'archivado': true,
    }, SetOptions(merge: true));
  }

  /// Restaura un paciente archivado: vuelve a `archivado: false` y reaparece
  /// en las lecturas activas.
  Future<void> desarchivarPaciente(String idPaciente) async {
    await _docUsuario.collection('patients').doc(idPaciente).set({
      'archivado': false,
    }, SetOptions(merge: true));
  }

  /// Stream en tiempo real de los pacientes archivados (`archivado == true`).
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

  // ── Cambio de correo ──

  /// Re-autentica al usuario con su contraseña actual. Exigido por Firebase
  /// antes de cualquier cambio sensible en la cuenta (correo principal o
  /// respaldo) para no romper la sesión.
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

  /// Cambia el correo PRINCIPAL. Re-autentica con la contraseña actual y usa
  /// `verifyBeforeUpdateEmail` (patrón de la canónica): el email de Auth solo
  /// cambia cuando el usuario confirma el enlace enviado al nuevo correo.
  /// Mientras tanto se registra el estado "verificación pendiente" y la app lo
  /// muestra hasta que se confirma (o se limpia manualmente).
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

  /// Cambia el correo de RESPALDO. Re-autentica con la contraseña actual,
  /// guarda el nuevo correo cifrado (para mostrarlo en el perfil) y registra
  /// su hash HMAC en el servidor vía la callable `registerRecoveryEmail`
  /// (el cliente nunca escribe `correo_respaldo_hash` directamente).
  /// Devuelve true si el servidor confirmó el registro; si la callable falla
  /// (p. ej. no desplegada) el correo queda guardado localmente y se devuelve
  /// false para que la app avise.
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
      // Registro local correcto; el hash se confirmará al reintentar cuando
      // la callable esté desplegada.
    }
    return confirmadoServidor;
  }

  /// Limpia el estado pendiente de cambio de correo (al confirmar el nuevo
  /// correo o al cancelar la solicitud).
  Future<void> limpiarCambioCorreoPendiente() async {
    await _docUsuario.set({
      'pendiente_correo': FieldValue.delete(),
      'pendiente_correo_tipo': FieldValue.delete(),
      'pendiente_correo_solicitado_en': FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  /// Sincroniza el correo principal confirmado en Firestore, tras completarse
  /// la verificación del cambio (el email de Auth ya es el nuevo). El correo
  /// del doc es el identificador que usan las funciones del servidor
  /// (p. ej. recoverByBackupEmail), por eso solo se escribe tras confirmar.
  Future<void> sincronizarCorreoPrincipal(String email) async {
    await _docUsuario.set({
      'email': email.trim().toLowerCase(),
    }, SetOptions(merge: true));
  }

  // ── Mapeo de campos sensibles ──
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
      // No romper la lista por un campo corrupto, pero NO tragar el error en
      // silencio: dejamos rastro para diagnóstico.
      debugPrint('No se pudo descifrar $campo: $e\n$pila');
      return null;
    }
  }
}
