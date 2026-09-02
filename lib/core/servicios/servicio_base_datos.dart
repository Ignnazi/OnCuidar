import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    if (datos['email'] != null) plano['email'] = datos['email'];
    if (datos['correo_respaldo_hash'] != null) {
      plano['correo_respaldo_hash'] = datos['correo_respaldo_hash'];
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
    plano['version_encriptacion'] = 2;
    await _docUsuario.set(plano, SetOptions(merge: true));
  }

  /// Devuelve los datos visibles del cuidador con sus campos personales ya
  /// descifrados. El correo se devuelve en texto plano por ser el
  /// identificador de acceso.
  Future<Map<String, String?>> obtenerCuidador() async {
    final doc = await _docUsuario.get();
    final datos = (doc.data() as Map<String, dynamic>?) ?? {};
    return {
      'email': datos['email'] as String?,
      'nombre': await _descifrarCampo(datos, 'nombre_cifrado'),
      'telefono': await _descifrarCampo(datos, 'telefono_cifrado'),
      'relacion': await _descifrarCampo(datos, 'relacion_cifrada'),
    };
  }

  // ── Paciente ──
  Future<String> crearPaciente(Paciente paciente) async {
    final ref = _docUsuario.collection('patients').doc();
    await ref.set(await _cifrarPaciente(paciente), SetOptions(merge: true));
    return ref.id;
  }

  Future<List<Paciente>> obtenerPacientes() async {
    final snap = await _docUsuario.collection('patients').get();
    final lista = <Paciente>[];
    for (final doc in snap.docs) {
      lista.add(await _descifrarPaciente(doc.id, doc.data()));
    }
    return lista;
  }

  Stream<List<Paciente>> pacientesEnTiempoReal() {
    return _docUsuario.collection('patients').snapshots().asyncMap(
          (snap) => Future.wait(
            snap.docs.map((d) => _descifrarPaciente(d.id, d.data())),
          ),
        );
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
    await _reemplazarPorCifrado(
      data,
      plano: p.rut,
      cifrado: 'rut_cifrado',
    );
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
      tratamientoFase:
          await _descifrarCampo(datos, 'fase_tratamiento_cifrado'),
      centroSaludNombre:
          await _descifrarCampo(datos, 'centro_salud_nombre_cifrado'),
      centroSaludDireccion:
          await _descifrarCampo(datos, 'centro_salud_direccion_cifrado'),
      centroSaludTelefono:
          await _descifrarCampo(datos, 'centro_salud_telefono_cifrado'),
      contactoEmergenciaNombre: await _descifrarCampo(
          datos, 'contacto_emergencia_nombre_cifrado'),
      contactoEmergenciaTelefono: await _descifrarCampo(
          datos, 'contacto_emergencia_telefono_cifrado'),
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
    } catch (_) {
      return null;
    }
  }
}