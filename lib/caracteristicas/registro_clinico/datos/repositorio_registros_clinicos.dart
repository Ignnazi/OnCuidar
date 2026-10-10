import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
import 'package:oncuidar/nucleo/datos/rutas_api.dart';
import 'package:oncuidar/nucleo/sincronizacion/cola_escrituras.dart';

class RepositorioRegistrosClinicos {
  RepositorioRegistrosClinicos(this.bd);

  final BaseDatosSegura bd;

  static const _tamanoPagina = 50;

  Future<void> guardarRegistroClinico(
    String idPaciente,
    RegistroClinico registro,
  ) async {
    if (registro.pacienteId != idPaciente) {
      throw ArgumentError(
        'El registro pertenece a "${registro.pacienteId}", no a "$idPaciente"',
      );
    }
    await bd.verificarEscrituraDisponible();
    final signos = registro.signosVitales;
    final datos = <String, dynamic>{
      'pacienteId': registro.pacienteId,
      'fecha': registro.fecha.toUtc().toIso8601String(),
      'creadoEn': registro.creadoEn.toUtc().toIso8601String(),
      'tipoRegistro': registro.tipoRegistro,
      'nivelAlerta': registro.nivelAlerta.name,
      'versionEncriptacion': 3,
    };
    bd.ponerCifrado(
      datos,
      'signos_vitales_cifrado',
      signos == null
          ? null
          : await bd.cifrado.cifrar(
              bd.uid,
              jsonEncode({
                'temperatura': signos.temperatura,
                'frecuenciaCardiaca': signos.frecuenciaCardiaca,
                'saturacionOxigeno': signos.saturacionOxigeno,
                'frecuenciaRespiratoria': signos.frecuenciaRespiratoria,
              }),
            ),
    );
    bd.ponerCifrado(
      datos,
      'sintomas_cifrado',
      await bd.cifrado.cifrar(
        bd.uid,
        jsonEncode([
          for (final sintoma in registro.sintomas)
            {
              'nombre': sintoma.nombre,
              'intensidad': sintoma.intensidad,
              if (sintoma.notas != null && sintoma.notas!.isNotEmpty)
                'notas': sintoma.notas,
            },
        ]),
      ),
    );
    await bd.reemplazarPorCifrado(
      datos,
      plano: registro.observaciones,
      cifrado: 'contenido_registro_cifrado',
    );
    await bd.reemplazarPorCifrado(
      datos,
      plano: registro.mensajeAlerta,
      cifrado: 'mensaje_alerta_cifrado',
    );
    await bd.escribir(
      RutasApi.registro(idPaciente, registro.id),
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
    await bd.borrar(RutasApi.registro(idPaciente, idRegistro), idPaciente);
  }

  Stream<List<RegistroClinico>> registrosClinicosEnTiempoReal(
    String idPaciente,
  ) {
    if (!bd.tieneIdentidad()) return Stream.value(const []);
    return bd.flujo<List<RegistroClinico>>(
      '${RutasApi.registros(idPaciente)}?limite=$_tamanoPagina',
      convertir: (json) async {
        final lista = await _descifrarLista(json as List, idPaciente);
        return lista..sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
      },
    );
  }

  Future<List<RegistroClinico>> cargarMasRegistrosClinicos(
    String idPaciente,
    DateTime ultimoCreadoEn,
  ) async {
    if (!bd.tieneIdentidad()) return const [];
    final antes = Uri.encodeQueryComponent(
      ultimoCreadoEn.toUtc().toIso8601String(),
    );
    final json = await bd.leer(
      '${RutasApi.registros(idPaciente)}?limite=$_tamanoPagina'
      '&antesDeCreadoEn=$antes',
    );
    return _descifrarLista(json as List, idPaciente);
  }

  Future<List<RegistroClinico>> registrosClinicosEnRango(
    String idPaciente, {
    DateTime? desde,
    DateTime? hasta,
  }) async {
    if (!bd.tieneIdentidad()) return const [];
    final params = [
      if (desde != null)
        'desde=${Uri.encodeQueryComponent(desde.toUtc().toIso8601String())}',
      if (hasta != null)
        'hasta=${Uri.encodeQueryComponent(hasta.toUtc().toIso8601String())}',
    ];
    if (params.isEmpty) params.add('desde=1970-01-01T00:00:00.000Z');
    final json = await bd.leer(
      '${RutasApi.registros(idPaciente)}?${params.join('&')}&limite=5000',
    );
    return _descifrarLista(json as List, idPaciente);
  }

  Future<List<RegistroClinico>> _descifrarLista(
    List json,
    String idPaciente,
  ) async {
    final lista = <RegistroClinico>[];
    for (final e in json) {
      final datos = (e as Map).cast<String, dynamic>();
      final registro = await _descifrarRegistroClinico(
        datos['id'] as String,
        datos,
      );
      if (registro.pacienteId.isEmpty || registro.pacienteId == idPaciente) {
        lista.add(registro);
      }
    }
    return lista;
  }

  Future<SignosVitales?> _descifrarSignosVitales(
    Map<String, dynamic> datos,
  ) async {
    final cifrado = bd.textoCifrado(datos, 'signos_vitales_cifrado');
    if (cifrado == null || cifrado.isEmpty) return null;
    try {
      final texto = await bd.cifrado.descifrar(bd.uid, cifrado);
      final mapa = jsonDecode(texto) as Map<String, dynamic>;
      return SignosVitales(
        temperatura: (mapa['temperatura'] as num?)?.toDouble(),
        frecuenciaCardiaca: (mapa['frecuenciaCardiaca'] as num?)?.toInt(),
        saturacionOxigeno: (mapa['saturacionOxigeno'] as num?)?.toInt(),
        frecuenciaRespiratoria: (mapa['frecuenciaRespiratoria'] as num?)
            ?.toInt(),
      );
    } catch (e, pila) {
      debugPrint('No se pudo descifrar signos_vitales_cifrado: $e\n$pila');
      return null;
    }
  }

  Future<List<EntradaSintoma>> _descifrarSintomas(
    Map<String, dynamic> datos,
  ) async {
    final cifrado = bd.textoCifrado(datos, 'sintomas_cifrado');
    if (cifrado == null || cifrado.isEmpty) return const [];
    try {
      final texto = await bd.cifrado.descifrar(bd.uid, cifrado);
      final lista = jsonDecode(texto) as List<dynamic>;
      return [
        for (final item in lista)
          EntradaSintoma(
            nombre: (item['nombre'] as String?) ?? '',
            intensidad: (item['intensidad'] as num?)?.toInt() ?? 0,
            notas: item['notas'] as String?,
          ),
      ];
    } catch (e, pila) {
      debugPrint('No se pudo descifrar sintomas_cifrado: $e\n$pila');
      return const [];
    }
  }

  Future<RegistroClinico> _descifrarRegistroClinico(
    String id,
    Map<String, dynamic> datos,
  ) async {
    final signos = await _descifrarSignosVitales(datos);
    final sintomas = await _descifrarSintomas(datos);
    final observaciones = await bd.descifrarCampo(
      datos,
      'contenido_registro_cifrado',
    );

    final nivelRaw = datos['nivelAlerta'] as String?;
    final nivel = NivelAlerta.values.firstWhere(
      (v) => v.name == nivelRaw,
      orElse: () => NivelAlerta.normal,
    );

    return RegistroClinico(
      id: id,
      pacienteId: (datos['pacienteId'] as String?) ?? '',
      fecha: bd.fechaTolerante(datos['fecha']),
      creadoEn: bd.fechaTolerante(datos['creadoEn']),
      tipoRegistro: (datos['tipoRegistro'] as String?) ?? 'programado',
      signosVitales: signos,
      sintomas: sintomas,
      observaciones: observaciones,
      nivelAlerta: nivel,
      mensajeAlerta: await bd.descifrarCampo(datos, 'mensaje_alerta_cifrado'),
    );
  }
}
