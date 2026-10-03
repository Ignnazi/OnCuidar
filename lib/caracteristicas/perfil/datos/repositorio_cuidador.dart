import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';

class RepositorioCuidador {
  RepositorioCuidador(this.bd);

  final BaseDatosSegura bd;

  Future<void> crearCuidador(Map<String, dynamic> datos) async {
    final plano = <String, dynamic>{};
    if (datos['correo'] != null) plano['correo'] = datos['correo'];
    final correoRespaldo = datos['correo_respaldo'] as String?;
    if (correoRespaldo != null && correoRespaldo.isNotEmpty) {
      plano['correo_respaldo_cifrado'] = await bd.cifrado.cifrar(
        bd.uid,
        correoRespaldo.trim().toLowerCase(),
      );
    }
    if (datos['creadoEn'] != null) plano['creadoEn'] = datos['creadoEn'];
    await bd.reemplazarPorCifrado(
      plano,
      plano: datos['nombre'] as String?,
      cifrado: 'nombre_cifrado',
    );
    await bd.reemplazarPorCifrado(
      plano,
      plano: datos['telefono'] as String?,
      cifrado: 'telefono_cifrado',
    );
    await bd.reemplazarPorCifrado(
      plano,
      plano: datos['relacion'] as String?,
      cifrado: 'relacion_cifrada',
    );
    await bd.reemplazarPorCifrado(
      plano,
      plano: datos['direccion'] as String?,
      cifrado: 'direccion_cifrada',
    );
    plano['version_encriptacion'] = 2;
    await bd.docUsuario.set(plano, SetOptions(merge: true));
  }

  Future<void> limpiarRegistro(String uid) async {
    try {
      await bd.firestore.collection('usuarios').doc(uid).delete();
    } catch (_) {}
  }

  Future<Map<String, dynamic>> obtenerCuidador() async {
    final doc = await bd.docUsuario.get();
    return _mapearCuidador((doc.data() as Map<String, dynamic>?) ?? {});
  }

  Stream<Map<String, dynamic>?> cuidadorEnTiempoReal() {
    if (!bd.tieneIdentidad()) return Stream.value(null);
    return bd.docUsuario.snapshots().asyncMap((doc) async {
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
      'correo': datos['correo'] as String?,
      'nombre': await bd.descifrarCampo(datos, 'nombre_cifrado'),
      'telefono': await bd.descifrarCampo(datos, 'telefono_cifrado'),
      'relacion': await bd.descifrarCampo(datos, 'relacion_cifrada'),
      'direccion': await bd.descifrarCampo(datos, 'direccion_cifrada'),
      'correoRespaldo': await bd.descifrarCampo(
        datos,
        'correo_respaldo_cifrado',
      ),
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
      await bd.reemplazarPorCifrado(
        plano,
        plano: nombre,
        cifrado: 'nombre_cifrado',
      );
    }
    if (telefono != null) {
      await bd.reemplazarPorCifrado(
        plano,
        plano: telefono,
        cifrado: 'telefono_cifrado',
      );
    }
    if (relacion != null) {
      await bd.reemplazarPorCifrado(
        plano,
        plano: relacion,
        cifrado: 'relacion_cifrada',
      );
    }
    if (direccion != null) {
      await bd.reemplazarPorCifrado(
        plano,
        plano: direccion,
        cifrado: 'direccion_cifrada',
      );
    }
    if (plano.isEmpty) return;
    await bd.sinEsperarSinRed(
      () => bd.docUsuario.set(plano, SetOptions(merge: true)),
    );
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
    final auth = bd.auth ?? FirebaseAuth.instance;
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
    await bd.docUsuario.set({
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
    await bd.docUsuario.set({
      'correo_respaldo_cifrado': await bd.cifrado.cifrar(bd.uid, normalizado),
      'respaldo_pendiente_servidor': true,
    }, SetOptions(merge: true));
    return _registrarRespaldoEnServidor(normalizado);
  }

  @visibleForTesting
  Future<void> Function(String correo) registrarCorreoRespaldoServidor =
      (correo) => FirebaseFunctions.instanceFor(region: 'southamerica-west1')
          .httpsCallable('registrarCorreoRespaldo')
          .call({'correo': correo})
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
    await bd.docUsuario.set({
      'respaldo_pendiente_servidor': FieldValue.delete(),
    }, SetOptions(merge: true));
    return true;
  }

  Future<bool> reintentarRegistroRespaldo() async {
    final datos =
        ((await bd.docUsuario.get()).data() as Map<String, dynamic>?) ?? {};
    if (datos['respaldo_pendiente_servidor'] != true) return true;
    final correo = await bd.descifrarCampo(datos, 'correo_respaldo_cifrado');
    if (correo == null || correo.isEmpty) return false;
    return _registrarRespaldoEnServidor(correo);
  }

  Future<void> limpiarCambioCorreoPendiente() async {
    await bd.docUsuario.set({
      'pendiente_correo': FieldValue.delete(),
      'pendiente_correo_tipo': FieldValue.delete(),
      'pendiente_correo_solicitado_en': FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  Future<void> sincronizarCorreoPrincipal(String email) async {
    await bd.docUsuario.set({
      'correo': email.trim().toLowerCase(),
    }, SetOptions(merge: true));
  }
}
