import 'package:flutter/material.dart';
import 'package:oncuidar/caracteristicas/pacientes/datos/repositorio_pacientes.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/paciente.dart';
import 'package:oncuidar/caracteristicas/perfil/datos/repositorio_cuidador.dart';
import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';
import 'package:oncuidar/nucleo/red/cliente_api.dart';
import 'package:oncuidar/nucleo/sesion/servicio_sesion.dart';

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
    required this._sesion,
    required this._api,
    required ServicioCifrado cifrado,
    required RepositorioPacientes repositorioPacientes,
    required RepositorioCuidador repositorioCuidador,
    VoidCallback? alDesbloquear,
    RegistrarCorreoRespaldo? registrarCorreoRespaldo,
  }) {
    _cifrado = cifrado;
    _repositorioPacientes = repositorioPacientes;
    _repositorioCuidador = repositorioCuidador;
    _alDesbloquear = alDesbloquear;
    _registrarCorreoRespaldo = registrarCorreoRespaldo ?? _viaApi;
  }

  final ServicioSesion _sesion;
  final ClienteApi _api;
  late final ServicioCifrado _cifrado;
  late final RepositorioPacientes _repositorioPacientes;
  late final RepositorioCuidador _repositorioCuidador;
  late final VoidCallback? _alDesbloquear;
  late final RegistrarCorreoRespaldo _registrarCorreoRespaldo;

  Future<void> _viaApi(String email) async {
    await _api.post('/correo-respaldo', {
      'correo': email,
    }, const Duration(seconds: 5));
  }

  Future<ResultadoRegistro> registrar(DatosRegistro datos) async {
    try {
      final sesion = await _sesion.registrar(datos.correo, datos.contrasena);

      try {
        await _cifrado.asegurarClave(sesion.uid);
        _alDesbloquear?.call();
        final respaldo = datos.correoRespaldo;
        await _repositorioCuidador.crearCuidador({
          'nombre': datos.nombre,
          'telefono': datos.telefono,
          'relacion': datos.relacion,
          'direccion': datos.direccion,
          // Cifrado para mostrarlo en el perfil
          if (respaldo != null && respaldo.isNotEmpty)
            'correo_respaldo': respaldo,
        });
        if (respaldo != null && respaldo.isNotEmpty) {
          await _registrarCorreoRespaldo(respaldo.trim().toLowerCase());
        }

        await _repositorioPacientes.crearPaciente(datos.paciente);
      } catch (_) {
        try {
          await _sesion.eliminarCuenta();
        } catch (_) {}
        rethrow;
      }

      return RegistroExitoso();
    } on ExcepcionSesion catch (e) {
      return RegistroFallido(_mensajePorCodigo(e.codigo));
    } catch (_) {
      return RegistroFallido('Error inesperado. Intenta de nuevo.');
    }
  }

  String _mensajePorCodigo(CodigoErrorSesion codigo) {
    switch (codigo) {
      case CodigoErrorSesion.correoEnUso:
        return 'Ya existe una cuenta con ese correo electrónico.';
      case CodigoErrorSesion.correoInvalido:
        return 'El correo electrónico no es válido.';
      case CodigoErrorSesion.contrasenaDebil:
        return 'La contraseña es muy débil. Usa al menos 6 caracteres.';
      default:
        return 'Error al crear la cuenta. Intenta de nuevo.';
    }
  }
}
