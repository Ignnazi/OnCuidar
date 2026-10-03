import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
import 'package:oncuidar/nucleo/sincronizacion/cola_escrituras.dart';

class RepositorioRegistrosClinicos {
  RepositorioRegistrosClinicos(this.bd);

  final BaseDatosSegura bd;

  CollectionReference _registrosClinicos(String idPaciente) => bd.docUsuario
      .collection('pacientes')
      .doc(idPaciente)
      .collection('registrosClinicos');

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
      'id': registro.id,
      'paciente_id': registro.pacienteId,
      'fecha': registro.fecha,
      'creadoEn': registro.creadoEn,
      'tipoRegistro': registro.tipoRegistro,
      'nivelAlerta': registro.nivelAlerta.name,
      if (signos != null)
        'signos_vitales_cifrado': await bd.cifrado.cifrar(
          bd.uid,
          jsonEncode({
            'temperatura': signos.temperatura,
            'frecuenciaCardiaca': signos.frecuenciaCardiaca,
            'saturacionOxigeno': signos.saturacionOxigeno,
            'frecuenciaRespiratoria': signos.frecuenciaRespiratoria,
          }),
        )
      else
        'signos_vitales_cifrado': FieldValue.delete(),
      'sintomas_cifrado': await bd.cifrado.cifrar(
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
    };
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
    datos['version_encriptacion'] = 3;
    await bd.escribir(
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
    await bd.borrar(_registrosClinicos(idPaciente).doc(idRegistro), idPaciente);
  }

  Stream<List<RegistroClinico>> registrosClinicosEnTiempoReal(
    String idPaciente,
  ) {
    if (!bd.tieneIdentidad()) return Stream.value(const []);
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
    if (!bd.tieneIdentidad()) return const [];
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
    if (!bd.tieneIdentidad()) return const [];
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

  Future<SignosVitales?> _descifrarSignosVitales(
    Map<String, dynamic> datos,
  ) async {
    final cifrado = datos['signos_vitales_cifrado'] as String?;
    if (cifrado != null && cifrado.isNotEmpty) {
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
      }
    }
    final signosMapa = datos['signosVitales'];
    if (signosMapa is Map<String, dynamic>) {
      return SignosVitales(
        temperatura: (signosMapa['temperatura'] as num?)?.toDouble(),
        frecuenciaCardiaca: signosMapa['frecuenciaCardiaca'] as int?,
        saturacionOxigeno: signosMapa['saturacionOxigeno'] as int?,
        frecuenciaRespiratoria: signosMapa['frecuenciaRespiratoria'] as int?,
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
      }
    }
    final sintomasRaw = datos['sintomas'];
    if (sintomasRaw is List) {
      final sintomas = <EntradaSintoma>[];
      for (final item in sintomasRaw.cast<Map<String, dynamic>>()) {
        final notesCifradas = item['notas_cifrado'] as String?;
        final notas = (notesCifradas != null && notesCifradas.isNotEmpty)
            ? await bd.descifrarCampo(item, 'notas_cifrado')
            : item['notas'] as String?;
        sintomas.add(
          EntradaSintoma(
            nombre: (item['nombre'] as String?) ?? '',
            intensidad: (item['intensidad'] as num?)?.toInt() ?? 0,
            notas: notas,
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
        ? await bd.descifrarCampo(datos, 'contenido_registro_cifrado')
        : datos['observaciones'] as String?;

    final nivelRaw = datos['nivelAlerta'] as String?;
    final nivel = NivelAlerta.values.firstWhere(
      (v) => v.name == nivelRaw,
      orElse: () => NivelAlerta.normal,
    );

    return RegistroClinico(
      id: id,
      pacienteId: (datos['paciente_id'] as String?) ?? '',
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
