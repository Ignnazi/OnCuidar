import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oncuidar/caracteristicas/historial/datos/exportador_excel.dart';
import 'package:oncuidar/caracteristicas/historial/datos/exportador_pdf.dart';
import 'package:oncuidar/caracteristicas/historial/dominio/filtro_historial.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/paciente.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/datos/proveedores_registro_clinico.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/datos/repositorio_registros_clinicos.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';

/// Formatos en que se exporta el historial.
enum FormatoExportacion {
  pdf('PDF', 'pdf'),
  excel('Excel', 'xlsx');

  const FormatoExportacion(this.nombre, this.extension);

  final String nombre;
  final String extension;
}

class ControladorHistorial {
  ControladorHistorial(this.repositorio);

  static const tamanoPagina = 50;

  final RepositorioRegistrosClinicos repositorio;

  Future<List<RegistroClinico>> cargarMas(
    String idPaciente,
    DateTime ultimoCreadoEn,
  ) {
    return repositorio.cargarMasRegistrosClinicos(idPaciente, ultimoCreadoEn);
  }

  Future<void> eliminar(String idPaciente, String idRegistro) {
    return repositorio.eliminarRegistroClinico(idPaciente, idRegistro);
  }

  Future<List<RegistroClinico>> registrosParaExportar(
    Paciente? paciente,
    FiltroHistorial filtro,
    List<RegistroClinico> Function() respaldo,
  ) async {
    if (paciente == null) return respaldo();
    final (desde, hasta) = filtro.limites();
    try {
      final todos = await repositorio.registrosClinicosEnRango(
        paciente.id,
        desde: desde,
        hasta: hasta,
      );
      return [
        for (final r in todos)
          if (filtro.admite(r)) r,
      ];
    } catch (_) {
      return respaldo();
    }
  }

  Future<Uint8List> generar(
    FormatoExportacion formato, {
    required List<RegistroClinico> registros,
    required Paciente? paciente,
    required String nombreCuidador,
    required FiltroHistorial filtro,
    DateTime? generadoEn,
  }) async {
    final momento = generadoEn ?? DateTime.now();
    return switch (formato) {
      FormatoExportacion.pdf => await generarPdfHistorial(
        registros: registros,
        paciente: paciente,
        nombreCuidador: nombreCuidador,
        fechaInicio: filtro.inicio,
        fechaFin: filtro.fin,
        generadoEn: momento,
      ),
      FormatoExportacion.excel => generarExcelHistorial(
        registros: registros,
        paciente: paciente,
        nombreCuidador: nombreCuidador,
        fechaInicio: filtro.inicio,
        fechaFin: filtro.fin,
        generadoEn: momento,
      ),
    };
  }
}

final controladorHistorialProvider = Provider<ControladorHistorial>((ref) {
  return ControladorHistorial(ref.watch(repositorioRegistrosClinicosProvider));
});
