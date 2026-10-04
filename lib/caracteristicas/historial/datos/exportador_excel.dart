import 'dart:math' as math;
import 'dart:typed_data';

import 'package:excel/excel.dart' as xlsx;
import 'package:oncuidar/caracteristicas/historial/datos/formato_exportacion.dart';
import 'package:oncuidar/caracteristicas/historial/dominio/orden_registros.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/paciente.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';
import 'package:oncuidar/nucleo/utilidades/formato_fecha.dart';

xlsx.ExcelColor _color(String hex) => xlsx.ExcelColor.fromHexString(hex);

const anchosColumnasExcel = <double>[13, 11, 13, 10, 10, 10, 10, 10, 38, 44];

const _ultimaColumnaIzquierda = 4;
const _ultimaColumna = 9;

const _altoLinea = 13.5;

xlsx.CellIndex _indice(int columna, int fila) =>
    xlsx.CellIndex.indexByColumnRow(columnIndex: columna, rowIndex: fila);

void _fusionar(
  xlsx.Sheet hoja,
  int fila,
  int desde,
  int hasta,
  String texto,
  xlsx.CellStyle estilo,
) {
  if (hasta > desde) hoja.merge(_indice(desde, fila), _indice(hasta, fila));
  final celda = hoja.cell(_indice(desde, fila));
  celda.value = xlsx.TextCellValue(texto);
  celda.cellStyle = estilo;
}

int _escribirBloque(
  xlsx.Sheet hoja,
  int fila,
  int desde,
  int hasta,
  BloqueInfo bloque, {
  required xlsx.CellStyle estiloSeccion,
  required xlsx.CellStyle estiloEtiqueta,
  required xlsx.CellStyle estiloValor,
}) {
  _fusionar(hoja, fila, desde, hasta, bloque.titulo, estiloSeccion);
  var f = fila + 1;
  for (final (etiqueta, valor) in bloque.filas) {
    final celdaEtiqueta = hoja.cell(_indice(desde, f));
    celdaEtiqueta.value = xlsx.TextCellValue(etiqueta);
    celdaEtiqueta.cellStyle = estiloEtiqueta;
    _fusionar(hoja, f, desde + 1, hasta, valor, estiloValor);
    f++;
  }
  return f - fila;
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

  final lineaSuave = xlsx.Border(
    borderStyle: xlsx.BorderStyle.Thin,
    borderColorHex: _color('#E8DCC0'),
  );
  final lineaEncabezado = xlsx.Border(
    borderStyle: xlsx.BorderStyle.Thin,
    borderColorHex: _color('#C47E10'),
  );

  final estiloTitulo = xlsx.CellStyle(
    bold: true,
    fontSize: 15,
    backgroundColorHex: _color('#E8A820'),
    fontColorHex: _color('#FFFFFF'),
    verticalAlign: xlsx.VerticalAlign.Center,
  );
  final estiloSubtitulo = xlsx.CellStyle(
    fontSize: 10,
    fontColorHex: _color('#6B5330'),
    verticalAlign: xlsx.VerticalAlign.Center,
  );
  final estiloSeccion = xlsx.CellStyle(
    bold: true,
    fontSize: 11,
    backgroundColorHex: _color('#FFF4D0'),
    fontColorHex: _color('#C08808'),
    verticalAlign: xlsx.VerticalAlign.Center,
  );
  final estiloEtiqueta = xlsx.CellStyle(
    bold: true,
    fontSize: 10,
    fontColorHex: _color('#C08808'),
    verticalAlign: xlsx.VerticalAlign.Top,
  );
  final estiloValor = xlsx.CellStyle(
    fontSize: 10,
    fontColorHex: _color('#2C1A00'),
    textWrapping: xlsx.TextWrapping.WrapText,
    verticalAlign: xlsx.VerticalAlign.Top,
  );
  final estiloEncabezadoTabla = xlsx.CellStyle(
    bold: true,
    fontSize: 10,
    backgroundColorHex: _color('#C47E10'),
    fontColorHex: _color('#FFFFFF'),
    horizontalAlign: xlsx.HorizontalAlign.Center,
    verticalAlign: xlsx.VerticalAlign.Center,
    textWrapping: xlsx.TextWrapping.WrapText,
    bottomBorder: lineaEncabezado,
  );

  var fila = 0;

  // Título y una línea con el paciente.
  _fusionar(hoja, fila, 0, _ultimaColumna, 'HISTORIAL ONCUIDAR', estiloTitulo);
  hoja.setRowHeight(fila, 28);
  fila++;
  final nombre = paciente?.nombreCompleto.trim();
  _fusionar(
    hoja,
    fila,
    0,
    _ultimaColumna,
    [
      if (nombre != null && nombre.isNotEmpty) 'Paciente: $nombre',
      'Generado: ${fechacorta(generadoEn)} ${hora12(generadoEn)}',
    ].join('   ·   '),
    estiloSubtitulo,
  );
  hoja.setRowHeight(fila, 20);
  fila++;
  hoja.setRowHeight(fila, 8);
  fila++;

  final izquierda = bloquesPacienteYCuidador(paciente, nombreCuidador);
  final derecha = bloquesCentroYContacto(paciente);
  for (var i = 0; i < math.max(izquierda.length, derecha.length); i++) {
    var ocupadas = 0;
    if (i < izquierda.length) {
      ocupadas = _escribirBloque(
        hoja,
        fila,
        0,
        _ultimaColumnaIzquierda,
        izquierda[i],
        estiloSeccion: estiloSeccion,
        estiloEtiqueta: estiloEtiqueta,
        estiloValor: estiloValor,
      );
    }
    if (i < derecha.length) {
      ocupadas = math.max(
        ocupadas,
        _escribirBloque(
          hoja,
          fila,
          _ultimaColumnaIzquierda + 1,
          _ultimaColumna,
          derecha[i],
          estiloSeccion: estiloSeccion,
          estiloEtiqueta: estiloEtiqueta,
          estiloValor: estiloValor,
        ),
      );
    }
    fila += ocupadas;
    hoja.setRowHeight(fila, 8);
    fila++;
  }

  _fusionar(hoja, fila, 0, _ultimaColumna, 'RESUMEN', estiloSeccion);
  fila++;
  for (final (etiqueta, valor) in <FilaInfo>[
    (
      rotuloPeriodo(fechaInicio, fechaFin),
      etiquetaPeriodo(fechaInicio, fechaFin),
    ),
    ('Registros', '${registros.length}'),
  ]) {
    final celdaEtiqueta = hoja.cell(_indice(0, fila));
    celdaEtiqueta.value = xlsx.TextCellValue(etiqueta);
    celdaEtiqueta.cellStyle = estiloEtiqueta;
    _fusionar(hoja, fila, 1, _ultimaColumnaIzquierda, valor, estiloValor);
    fila++;
  }
  hoja.setRowHeight(fila, 10);
  fila++;

  // Tabla de registros.
  for (var i = 0; i < encabezadosRegistro.length; i++) {
    final celda = hoja.cell(_indice(i, fila));
    celda.value = xlsx.TextCellValue(
      encabezadosRegistro[i].replaceAll('O2', 'O₂'),
    );
    celda.cellStyle = estiloEncabezadoTabla;
  }
  hoja.setRowHeight(fila, 24);
  fila++;

  var numero = 0;
  for (final rec in ordenarCronologicamente(registros)) {
    final celdas = celdasRegistro(rec, vacio: '–');
    final fondo = numero.isOdd ? _color('#FFF9E8') : _color('#FFFFFF');
    for (var i = 0; i < celdas.length; i++) {
      final esTexto = i >= 8;
      final celda = hoja.cell(_indice(i, fila));
      celda.value = xlsx.TextCellValue(celdas[i]);
      celda.cellStyle = xlsx.CellStyle(
        fontSize: 10,
        backgroundColorHex: fondo,
        fontColorHex: i == 3
            ? _color(switch (celdas[i]) {
                'Normal' => '#168A63',
                'Alerta' => '#B77900',
                'Crítico' => '#D1103F',
                _ => '#2C1A00',
              })
            : _color('#2C1A00'),
        bold: i == 3,
        horizontalAlign: esTexto
            ? xlsx.HorizontalAlign.Left
            : xlsx.HorizontalAlign.Center,
        verticalAlign: xlsx.VerticalAlign.Center,
        textWrapping: xlsx.TextWrapping.WrapText,
        bottomBorder: lineaSuave,
      );
    }
    final lineas = math.max(
      lineasNecesarias(celdas[8], (anchosColumnasExcel[8] * 1.05).floor()),
      lineasNecesarias(celdas[9], (anchosColumnasExcel[9] * 1.05).floor()),
    );
    hoja.setRowHeight(fila, math.max(22, lineas * _altoLinea + 8));
    fila++;
    numero++;
  }

  for (var i = 0; i < anchosColumnasExcel.length; i++) {
    hoja.setColumnWidth(i, anchosColumnasExcel[i]);
  }

  final bytes = libro.save();
  if (bytes == null) {
    throw StateError('No se pudo serializar el archivo Excel');
  }
  return Uint8List.fromList(bytes);
}
