import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:oncuidar/caracteristicas/pacientes/datos/repositorio_pacientes.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/paciente.dart';
import 'package:oncuidar/caracteristicas/perfil/datos/repositorio_cuidador.dart';
import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';

class DatosRegistro {
  const DatosRegistro({
    required this.nombre,
    required this.correo,
    required this.telefono,
    required this.contrasena,
    required this.paciente,
    this.relacion,
    this.correoRespaldo,
    this.direccion,
  });

  final String nombre;
  final String correo;
  final String telefono;
  final String? relacion;
  final String? correoRespaldo;
  final String? direccion;
  final String contrasena;
  final Paciente paciente;
}

sealed class ResultadoRegistro {}

class RegistroExitoso extends ResultadoRegistro {}

class RegistroFallido extends ResultadoRegistro {
  RegistroFallido(this.mensaje);

  final String mensaje;
}

typedef RegistrarCorreoRespaldo = Future<void> Function(String email);

class ServicioRegistro {
  ServicioRegistro({
    FirebaseAuth? auth,
    required ServicioCifrado cifrado,
    required RepositorioPacientes repositorioPacientes,
    required RepositorioCuidador repositorioCuidador,
    VoidCallback? alDesbloquear,
    RegistrarCorreoRespaldo? registrarCorreoRespaldo,
  }) : _auth = auth ?? FirebaseAuth.instance {
    _cifrado = cifrado;
    _repositorioPacientes = repositorioPacientes;
    _repositorioCuidador = repositorioCuidador;
    _alDesbloquear = alDesbloquear;
    _registrarCorreoRespaldo = registrarCorreoRespaldo ?? _viaCallable;
  }

  final FirebaseAuth _auth;
  late final ServicioCifrado _cifrado;
  late final RepositorioPacientes _repositorioPacientes;
  late final RepositorioCuidador _repositorioCuidador;
  late final VoidCallback? _alDesbloquear;
  late final RegistrarCorreoRespaldo _registrarCorreoRespaldo;

  Future<void> _viaCallable(String email) async {
    await FirebaseFunctions.instanceFor(region: 'southamerica-west1')
        .httpsCallable('registrarCorreoRespaldo')
        .call({'correo': email})
        .timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw FirebaseFunctionsException(
            code: 'unavailable',
            message: 'Sin conexión',
          ),
        );
  }

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
        await _repositorioCuidador.crearCuidador({
          'nombre': datos.nombre,
          'correo': datos.correo,
          'telefono': datos.telefono,
          'relacion': datos.relacion,
          'direccion': datos.direccion,
          // Cifrado para mostrarlo en el perfil
          if (respaldo != null && respaldo.isNotEmpty)
            'correo_respaldo': respaldo,
          'creadoEn': FieldValue.serverTimestamp(),
        });
        if (respaldo != null && respaldo.isNotEmpty) {
          await _registrarCorreoRespaldo(respaldo.trim().toLowerCase());
        }

        await _repositorioPacientes.crearPaciente(datos.paciente);
      } catch (_) {
        await _repositorioCuidador.limpiarRegistro(uid);
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
