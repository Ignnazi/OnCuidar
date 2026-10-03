import 'dart:typed_data';

import 'package:excel/excel.dart' as xlsx;
import 'package:oncuidar/caracteristicas/historial/datos/formato_exportacion.dart';
import 'package:oncuidar/caracteristicas/historial/dominio/orden_registros.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/paciente.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';
import 'package:oncuidar/nucleo/utilidades/formato_fecha.dart';

void _celdaMergeFila(
  xlsx.Sheet hoja,
  int fila,
  int columnaInicio,
  int columnaFin,
  String texto,
  xlsx.CellStyle estilo,
) {
  final inicio = xlsx.CellIndex.indexByColumnRow(
    columnIndex: columnaInicio,
    rowIndex: fila,
  );
  final fin = xlsx.CellIndex.indexByColumnRow(
    columnIndex: columnaFin,
    rowIndex: fila,
  );
  hoja.merge(inicio, fin);
  final celda = hoja.cell(inicio);
  celda.value = xlsx.TextCellValue(texto);
  celda.cellStyle = estilo;
}

void _etiquetaValor(
  xlsx.Sheet hoja,
  int fila,
  String etiqueta,
  String valor,
  xlsx.CellStyle estiloEtiqueta,
  xlsx.CellStyle estiloValor,
) {
  final celdaEtiqueta = hoja.cell(
    xlsx.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: fila),
  );
  celdaEtiqueta.value = xlsx.TextCellValue(etiqueta);
  celdaEtiqueta.cellStyle = estiloEtiqueta;

  final inicio = xlsx.CellIndex.indexByColumnRow(
    columnIndex: 1,
    rowIndex: fila,
  );
  final fin = xlsx.CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: fila);
  hoja.merge(inicio, fin);
  final celdaValor = hoja.cell(inicio);
  celdaValor.value = xlsx.TextCellValue(valor);
  celdaValor.cellStyle = estiloValor;
}

Uint8List generarExcelHistorial({
  required List<RegistroClinico> registros,
  required Paciente? paciente,
  String? nombreCuidador,
  DateTime? fechaInicio,
  DateTime? fechaFin,
  required DateTime generadoEn,
}) {
  final libro = xlsx.Excel.createExcel();
  libro.rename('Sheet1', 'Historial');
  final hoja = libro['Historial'];

  final estiloTitulo = xlsx.CellStyle(
    bold: true,
    fontSize: 14,
    backgroundColorHex: xlsx.ExcelColor.fromHexString('#E8A820'),
    fontColorHex: xlsx.ExcelColor.fromHexString('#FFFFFF'),
  );
  final estiloSeccion = xlsx.CellStyle(
    bold: true,
    fontSize: 11,
    backgroundColorHex: xlsx.ExcelColor.fromHexString('#FFF4D0'),
    fontColorHex: xlsx.ExcelColor.fromHexString('#C08808'),
  );
  final estiloEtiqueta = xlsx.CellStyle(
    bold: true,
    fontSize: 10,
    fontColorHex: xlsx.ExcelColor.fromHexString('#C08808'),
  );
  final estiloValor = xlsx.CellStyle(
    fontSize: 10,
    fontColorHex: xlsx.ExcelColor.fromHexString('#2C1A00'),
  );
  final estiloEncabezadoTabla = xlsx.CellStyle(
    bold: true,
    fontSize: 11,
    backgroundColorHex: xlsx.ExcelColor.fromHexString('#E8A820'),
    fontColorHex: xlsx.ExcelColor.fromHexString('#FFFFFF'),
  );

  var fila = 0;

  _celdaMergeFila(hoja, fila, 0, 9, 'HISTORIAL ONCUIDAR', estiloTitulo);
  fila++;
  fila++;

  if (paciente != null) {
    _celdaMergeFila(hoja, fila, 0, 9, 'PACIENTE', estiloSeccion);
    fila++;
    _etiquetaValor(
      hoja,
      fila,
      'Nombre',
      paciente.nombreCompleto,
      estiloEtiqueta,
      estiloValor,
    );
    fila++;
    if (paciente.edad != null) {
      _etiquetaValor(
        hoja,
        fila,
        'Edad',
        '${paciente.edad} años',
        estiloEtiqueta,
        estiloValor,
      );
      fila++;
    }
    if (paciente.diagnostico?.isNotEmpty == true) {
      _etiquetaValor(
        hoja,
        fila,
        'Diagnóstico',
        paciente.diagnostico!,
        estiloEtiqueta,
        estiloValor,
      );
      fila++;
    }
    if (paciente.tratamientoFase?.isNotEmpty == true) {
      _etiquetaValor(
        hoja,
        fila,
        'Fase',
        paciente.tratamientoFase!,
        estiloEtiqueta,
        estiloValor,
      );
      fila++;
    }
    fila++;
  }

  if (nombreCuidador?.trim().isNotEmpty == true) {
    _celdaMergeFila(hoja, fila, 0, 9, 'CUIDADOR', estiloSeccion);
    fila++;
    _etiquetaValor(
      hoja,
      fila,
      'Nombre',
      nombreCuidador!.trim(),
      estiloEtiqueta,
      estiloValor,
    );
    fila++;
    fila++;
  }

  if (paciente?.centroSaludNombre?.isNotEmpty == true) {
    _celdaMergeFila(hoja, fila, 0, 9, 'CENTRO DE SALUD', estiloSeccion);
    fila++;
    _etiquetaValor(
      hoja,
      fila,
      'Nombre',
      paciente!.centroSaludNombre!,
      estiloEtiqueta,
      estiloValor,
    );
    fila++;
    if (paciente.centroSaludDireccion?.isNotEmpty == true) {
      _etiquetaValor(
        hoja,
        fila,
        'Dirección',
        paciente.centroSaludDireccion!,
        estiloEtiqueta,
        estiloValor,
      );
      fila++;
    }
    if (paciente.centroSaludTelefono?.isNotEmpty == true) {
      _etiquetaValor(
        hoja,
        fila,
        'Teléfono',
        paciente.centroSaludTelefono!,
        estiloEtiqueta,
        estiloValor,
      );
      fila++;
    }
    fila++;
  }

  if (paciente?.contactoEmergenciaNombre?.isNotEmpty == true) {
    _celdaMergeFila(hoja, fila, 0, 9, 'CONTACTO DE EMERGENCIA', estiloSeccion);
    fila++;
    _etiquetaValor(
      hoja,
      fila,
      'Nombre',
      paciente!.contactoEmergenciaNombre!,
      estiloEtiqueta,
      estiloValor,
    );
    fila++;
    if (paciente.contactoEmergenciaTelefono?.isNotEmpty == true) {
      _etiquetaValor(
        hoja,
        fila,
        'Teléfono',
        paciente.contactoEmergenciaTelefono!,
        estiloEtiqueta,
        estiloValor,
      );
      fila++;
    }
    fila++;
  }

  _celdaMergeFila(hoja, fila, 0, 9, 'RESUMEN', estiloSeccion);
  fila++;
  final inicio = fechaInicio != null ? fechacorta(fechaInicio) : 'sin inicio';
  final fin = fechaFin != null ? fechacorta(fechaFin) : 'sin fin';
  _etiquetaValor(
    hoja,
    fila,
    'Rango',
    '$inicio - $fin',
    estiloEtiqueta,
    estiloValor,
  );
  fila++;
  _etiquetaValor(
    hoja,
    fila,
    'Total registros',
    '${registros.length}',
    estiloEtiqueta,
    estiloValor,
  );
  fila++;
  _etiquetaValor(
    hoja,
    fila,
    'Generado',
    '${fechacorta(generadoEn)} ${hora12(generadoEn)}',
    estiloEtiqueta,
    estiloValor,
  );
  fila++;
  fila++;

  const encabezados = [
    'Fecha',
    'Hora',
    'Tipo',
    'Estado',
    'Temp.',
    'F.C.',
    'Sat. O₂',
    'F.R.',
    'Síntomas',
    'Observaciones',
  ];
  for (var i = 0; i < encabezados.length; i++) {
    final celda = hoja.cell(
      xlsx.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: fila),
    );
    celda.value = xlsx.TextCellValue(encabezados[i]);
    celda.cellStyle = estiloEncabezadoTabla;
  }
  fila++;

  for (final rec in ordenarCronologicamente(registros)) {
    final celdas = celdasRegistro(rec, vacio: '');
    for (var i = 0; i < celdas.length; i++) {
      final celda = hoja.cell(
        xlsx.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: fila),
      );
      celda.value = xlsx.TextCellValue(celdas[i]);
    }
    fila++;
  }

  const anchos = <int, double>{
    0: 18,
    1: 16,
    2: 17,
    3: 16,
    4: 12,
    5: 12,
    6: 12,
    7: 11,
    8: 40,
    9: 40,
  };
  for (var i = 0; i < 10; i++) {
    hoja.setColumnWidth(i, anchos[i]!);
  }

  final bytes = libro.save();
  if (bytes == null) {
    throw StateError('No se pudo serializar el archivo Excel');
  }
  return Uint8List.fromList(bytes);
}
