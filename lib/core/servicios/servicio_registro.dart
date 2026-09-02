import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../modelos/paciente.dart';
import 'servicio_base_datos.dart';
import 'servicio_cifrado.dart';

class DatosRegistro {
  const DatosRegistro({
    required this.nombre,
    required this.correo,
    required this.telefono,
    required this.contrasena,
    required this.paciente,
    this.relacion,
    this.correoRespaldo,
  });

  final String nombre;
  final String correo;
  final String telefono;
  final String? relacion;
  final String? correoRespaldo;
  final String contrasena;
  final Paciente paciente;
}

sealed class ResultadoRegistro {}

class RegistroExitoso extends ResultadoRegistro {}

class RegistroFallido extends ResultadoRegistro {
  RegistroFallido(this.mensaje);

  final String mensaje;
}

class ServicioRegistro {
  ServicioRegistro({
    FirebaseAuth? auth,
    required ServicioCifrado cifrado,
    required ServicioBaseDatos baseDatos,
    VoidCallback? alDesbloquear,
  }) : _auth = auth ?? FirebaseAuth.instance {
    _cifrado = cifrado;
    _baseDatos = baseDatos;
    _alDesbloquear = alDesbloquear;
  }

  final FirebaseAuth _auth;
  late final ServicioCifrado _cifrado;
  late final ServicioBaseDatos _baseDatos;
  late final VoidCallback? _alDesbloquear;

  Future<ResultadoRegistro> registrar(DatosRegistro datos) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: datos.correo,
        password: datos.contrasena,
      );
      final uid = credential.user!.uid;

      try {
        await _cifrado.asegurarClave(uid);
        _alDesbloquear?.call();
        final respaldo = datos.correoRespaldo;
        await _baseDatos.crearCuidador({
          'displayName': datos.nombre,
          'email': datos.correo,
          'phone': datos.telefono,
          'relationship': datos.relacion,
          if (respaldo != null && respaldo.isNotEmpty)
            'correo_respaldo_hash': sha256
                .convert(utf8.encode(respaldo.trim().toLowerCase()))
                .toString(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        await _baseDatos.crearPaciente(datos.paciente);
      } catch (_) {
        try {
          await credential.user?.delete();
        } catch (_) {}
        rethrow;
      }

      return RegistroExitoso();
    } on FirebaseAuthException catch (e) {
      return RegistroFallido(_mensajePorCodigo(e.code));
    } catch (_) {
      return RegistroFallido('Error inesperado. Intenta de nuevo.');
    }
  }

  String _mensajePorCodigo(String codigo) {
    switch (codigo) {
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese correo electrónico.';
      case 'invalid-email':
        return 'El correo electrónico no es válido.';
      case 'weak-password':
        return 'La contraseña es muy débil. Usa al menos 6 caracteres.';
      default:
        return 'Error al crear la cuenta. Intenta de nuevo.';
    }
  }
}