import 'package:flutter/foundation.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
import 'package:oncuidar/nucleo/datos/rutas_api.dart';
import 'package:oncuidar/nucleo/sesion/servicio_sesion.dart';
import 'package:oncuidar/nucleo/sincronizacion/cola_escrituras.dart';

class RepositorioCuidador {
  RepositorioCuidador(this.bd);

  final BaseDatosSegura bd;

  ServicioSesion get _sesion =>
      bd.sesion ?? (throw StateError('No user authenticated'));

  Future<void> crearCuidador(Map<String, dynamic> datos) async {
    final cuerpo = <String, dynamic>{};
    final correoRespaldo = datos['correo_respaldo'] as String?;
    if (correoRespaldo != null && correoRespaldo.isNotEmpty) {
      bd.ponerCifrado(
        cuerpo,
        'correo_respaldo_cifrado',
        await bd.cifrado.cifrar(bd.uid, correoRespaldo.trim().toLowerCase()),
      );
    }
    await bd.reemplazarPorCifrado(
      cuerpo,
      plano: datos['nombre'] as String?,
      cifrado: 'nombre_cifrado',
    );
    await bd.reemplazarPorCifrado(
      cuerpo,
      plano: datos['telefono'] as String?,
      cifrado: 'telefono_cifrado',
    );
    await bd.reemplazarPorCifrado(
      cuerpo,
      plano: datos['relacion'] as String?,
      cifrado: 'relacion_cifrada',
    );
    await bd.reemplazarPorCifrado(
      cuerpo,
      plano: datos['direccion'] as String?,
      cifrado: 'direccion_cifrada',
    );
    cuerpo['versionEncriptacion'] = 2;
    await bd.escribir(
      RutasApi.cuidador,
      cuerpo,
      operacion: OperacionPendiente.guardar,
    );
  }

  Future<Map<String, dynamic>> obtenerCuidador() async {
    final json = await bd.leerConCache(RutasApi.cuidador);
    return _mapearCuidador((json as Map).cast<String, dynamic>());
  }

  Stream<Map<String, dynamic>?> cuidadorEnTiempoReal() {
    if (!bd.tieneIdentidad()) return Stream.value(null);
    return bd.flujo<Map<String, dynamic>?>(
      RutasApi.cuidador,
      vacio: <String, dynamic>{},
      convertir: (json) async {
        final datos = (json as Map).cast<String, dynamic>();
        if (datos.isEmpty) return null;
        try {
          return await _mapearCuidador(datos);
        } catch (_) {
          return null;
        }
      },
    );
  }

  Future<Map<String, dynamic>> _mapearCuidador(
    Map<String, dynamic> datos,
  ) async {
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
      'respaldoPendienteServidor': datos['respaldoPendienteServidor'] == true,
    };
  }

  Future<void> actualizarCuidador({
    String? nombre,
    String? telefono,
    String? relacion,
    String? direccion,
  }) async {
    final cuerpo = <String, dynamic>{};
    if (nombre != null) {
      await bd.reemplazarPorCifrado(
        cuerpo,
        plano: nombre,
        cifrado: 'nombre_cifrado',
      );
    }
    if (telefono != null) {
      await bd.reemplazarPorCifrado(
        cuerpo,
        plano: telefono,
        cifrado: 'telefono_cifrado',
      );
    }
    if (relacion != null) {
      await bd.reemplazarPorCifrado(
        cuerpo,
        plano: relacion,
        cifrado: 'relacion_cifrada',
      );
    }
    if (direccion != null) {
      await bd.reemplazarPorCifrado(
        cuerpo,
        plano: direccion,
        cifrado: 'direccion_cifrada',
      );
    }
    if (cuerpo.isEmpty) return;
    await bd.escribir(
      RutasApi.cuidador,
      cuerpo,
      operacion: OperacionPendiente.guardar,
    );
  }

  Future<void> cambiarCorreoPrincipal({
    required String contrasena,
    required String nuevoCorreo,
  }) async {
    await _sesion.cambiarCorreo(contrasena, nuevoCorreo);
    bd.notificarCambio();
  }

  Future<bool> cambiarCorreoRespaldo({
    required String contrasena,
    required String nuevoCorreo,
  }) async {
    await _sesion.verificarContrasena(contrasena);
    final normalizado = nuevoCorreo.trim().toLowerCase();
    final cuerpo = <String, dynamic>{'respaldoPendienteServidor': true};
    bd.ponerCifrado(
      cuerpo,
      'correo_respaldo_cifrado',
      await bd.cifrado.cifrar(bd.uid, normalizado),
    );
    await bd.escribir(
      RutasApi.cuidador,
      cuerpo,
      operacion: OperacionPendiente.guardar,
    );
    return _registrarRespaldoEnServidor(normalizado);
  }

  @visibleForTesting
  late Future<void> Function(String correo) registrarCorreoRespaldoServidor =
      (correo) => bd.api.post('/correo-respaldo', {
        'correo': correo,
      }, const Duration(seconds: 5));

  Future<bool> _registrarRespaldoEnServidor(String correo) async {
    try {
      await registrarCorreoRespaldoServidor(correo);
    } catch (e) {
      debugPrint('Registro del correo de respaldo pendiente: $e');
      return false;
    }
    await bd.escribir(RutasApi.cuidador, {
      'respaldoPendienteServidor': false,
    }, operacion: OperacionPendiente.guardar);
    return true;
  }

  Future<bool> reintentarRegistroRespaldo() async {
    final datos = ((await bd.leer(RutasApi.cuidador)) as Map)
        .cast<String, dynamic>();
    if (datos['respaldoPendienteServidor'] != true) return true;
    final correo = await bd.descifrarCampo(datos, 'correo_respaldo_cifrado');
    if (correo == null || correo.isEmpty) return false;
    return _registrarRespaldoEnServidor(correo);
  }
}
