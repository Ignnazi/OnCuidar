import 'dart:typed_data';

import 'package:oncuidar/caracteristicas/historial/datos/formato_exportacion.dart';
import 'package:oncuidar/caracteristicas/historial/dominio/orden_registros.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/paciente.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';
import 'package:oncuidar/nucleo/utilidades/formato_fecha.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

PdfColor _hex(String valor) => PdfColor.fromHex(valor);

// Paleta del documento.
final _doradoOscuro = _hex('#C08808');
final _doradoClaro = _hex('#FFF4D0');
final _textoPrincipal = _hex('#2C1A00');
final _textoSecundario = _hex('#6B5330');
final _lineaSuave = _hex('#E8DCC0');

pw.Widget _bandaPrimeraPagina(DateTime generadoEn, Paciente? paciente) {
  final nombre = paciente?.nombreCompleto.trim();
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    decoration: pw.BoxDecoration(
      gradient: pw.LinearGradient(
        begin: pw.Alignment.centerLeft,
        end: pw.Alignment.centerRight,
        colors: [_hex('#E8A820'), _hex('#C47E10')],
      ),
      borderRadius: pw.BorderRadius.circular(10),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'OnCuidar',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'Historial clínico',
              style: pw.TextStyle(
                fontSize: 11,
                color: PdfColors.white.withAlpha(0.92),
              ),
            ),
          ],
        ),
        pw.Spacer(),
        if (nombre != null && nombre.isNotEmpty)
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'PACIENTE',
                style: pw.TextStyle(
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white.withAlpha(0.8),
                  letterSpacing: 1.2,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                nombre,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'Generado: ${fechacorta(generadoEn)} ${hora12(generadoEn)}',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.white.withAlpha(0.85),
                ),
              ),
            ],
          ),
      ],
    ),
  );
}

pw.Widget _encabezadoContinuacion(Paciente? paciente) {
  final nombre = paciente?.nombreCompleto.trim();
  return pw.Container(
    padding: const pw.EdgeInsets.only(bottom: 5),
    margin: const pw.EdgeInsets.only(bottom: 8),
    decoration: pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: _lineaSuave, width: 0.6)),
    ),
    child: pw.Row(
      children: [
        pw.Text(
          'OnCuidar · Historial clínico',
          style: pw.TextStyle(
            fontSize: 8.5,
            fontWeight: pw.FontWeight.bold,
            color: _doradoOscuro,
          ),
        ),
        pw.Spacer(),
        if (nombre != null && nombre.isNotEmpty)
          pw.Text(
            nombre,
            style: pw.TextStyle(fontSize: 8.5, color: _textoSecundario),
          ),
      ],
    ),
  );
}

pw.Widget _piePagina(pw.Context contexto) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 8),
    child: pw.Row(
      children: [
        pw.Expanded(
          child: pw.Text(
            'OnCuidar · apoyo al cuidado oncológico pediátrico',
            style: pw.TextStyle(fontSize: 7.5, color: _textoSecundario),
          ),
        ),
        pw.Text(
          'Página ${contexto.pageNumber} de ${contexto.pagesCount}',
          style: pw.TextStyle(fontSize: 8, color: _textoSecundario),
        ),
      ],
    ),
  );
}

pw.Widget _tituloSeccion(String titulo) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    decoration: pw.BoxDecoration(
      color: _doradoClaro,
      borderRadius: pw.BorderRadius.circular(4),
    ),
    child: pw.Row(
      children: [
        pw.Container(
          width: 3,
          height: 12,
          decoration: pw.BoxDecoration(
            color: _hex('#E8A820'),
            borderRadius: pw.BorderRadius.circular(1),
          ),
        ),
        pw.SizedBox(width: 6),
        pw.Text(
          titulo,
          style: pw.TextStyle(
            fontSize: 9.5,
            fontWeight: pw.FontWeight.bold,
            color: _doradoOscuro,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );
}

pw.Widget _bloque(BloqueInfo bloque) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 10),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _tituloSeccion(bloque.titulo),
        pw.SizedBox(height: 5),
        for (final (etiqueta, valor) in bloque.filas)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3, left: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 70,
                  child: pw.Text(
                    etiqueta,
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                      color: _doradoOscuro,
                    ),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    valor,
                    style: pw.TextStyle(fontSize: 9, color: _textoPrincipal),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

pw.Widget _ficha(List<BloqueInfo> izquierda, List<BloqueInfo> derecha) {
  if (izquierda.isEmpty && derecha.isEmpty) return pw.SizedBox();
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [for (final b in izquierda) _bloque(b)],
        ),
      ),
      pw.SizedBox(width: 22),
      pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [for (final b in derecha) _bloque(b)],
        ),
      ),
    ],
  );
}

pw.Widget _datoResumen(String rotulo, String valor) {
  return pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _lineaSuave, width: 0.6),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            rotulo.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
              color: _doradoOscuro,
              letterSpacing: 0.8,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            valor,
            style: pw.TextStyle(
              fontSize: 10.5,
              fontWeight: pw.FontWeight.bold,
              color: _textoPrincipal,
            ),
          ),
        ],
      ),
    ),
  );
}

PdfColor? _colorEstado(String estado) => switch (estado) {
  'Normal' => _hex('#168A63'),
  'Alerta' => _hex('#B77900'),
  'Crítico' => _hex('#D1103F'),
  _ => null,
};

const _anchosTabla = <int, pw.TableColumnWidth>{
  0: pw.FixedColumnWidth(60), // Fecha
  1: pw.FixedColumnWidth(54), // Hora
  2: pw.FixedColumnWidth(62), // Tipo
  3: pw.FixedColumnWidth(50), // Estado
  4: pw.FixedColumnWidth(46), // Temp.
  5: pw.FixedColumnWidth(54), // F.C.
  6: pw.FixedColumnWidth(48), // Sat. O2
  7: pw.FixedColumnWidth(54), // F.R.
  8: pw.FlexColumnWidth(5), // Síntomas
  9: pw.FlexColumnWidth(4), // Observaciones
};

pw.Widget _tablaRegistros(List<RegistroClinico> registros) {
  final datos = [
    for (final rec in ordenarCronologicamente(registros))
      celdasRegistro(rec, vacio: '-'),
  ];
  final estiloCelda = pw.TextStyle(
    fontSize: 8.5,
    color: _textoPrincipal,
    lineSpacing: 1.5,
  );

  return pw.TableHelper.fromTextArray(
    headers: encabezadosRegistro,
    data: datos,
    headerStyle: pw.TextStyle(
      fontSize: 8.5,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
      letterSpacing: 0.3,
    ),
    headerDecoration: pw.BoxDecoration(color: _hex('#C47E10')),
    headerPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
    headerAlignment: pw.Alignment.centerLeft,
    cellStyle: estiloCelda,
    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
    cellHeight: 22,
    cellAlignment: pw.Alignment.centerLeft,
    cellAlignments: {for (var i = 3; i <= 7; i++) i: pw.Alignment.center},
    headerAlignments: {for (var i = 3; i <= 7; i++) i: pw.Alignment.center},
    rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
    oddRowDecoration: pw.BoxDecoration(color: _hex('#FFF9E8')),
    columnWidths: _anchosTabla,
    textStyleBuilder: (indice, valor, _) {
      if (indice != 3) return null;
      final color = _colorEstado('$valor');
      if (color == null) return null;
      return pw.TextStyle(
        fontSize: 8.5,
        fontWeight: pw.FontWeight.bold,
        color: color,
      );
    },
    border: pw.TableBorder(
      bottom: pw.BorderSide(color: _lineaSuave, width: 0.6),
      horizontalInside: pw.BorderSide(color: _lineaSuave, width: 0.4),
    ),
  );
}

Future<Uint8List> generarPdfHistorial({
  required List<RegistroClinico> registros,
  required Paciente? paciente,
  String? nombreCuidador,
  DateTime? fechaInicio,
  DateTime? fechaFin,
  required DateTime generadoEn,
  bool comprimir = true,
}) async {
  final izquierda = bloquesPacienteYCuidador(paciente, nombreCuidador);
  final derecha = bloquesCentroYContacto(paciente);
  final documento = pw.Document(compress: comprimir);

  documento.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 26),
      header: (contexto) => contexto.pageNumber == 1
          ? pw.SizedBox()
          : _encabezadoContinuacion(paciente),
      footer: _piePagina,
      build: (_) {
        return <pw.Widget>[
          _bandaPrimeraPagina(generadoEn, paciente),
          pw.SizedBox(height: 14),
          _ficha(izquierda, derecha),
          _tituloSeccion('RESUMEN'),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              _datoResumen(
                rotuloPeriodo(fechaInicio, fechaFin),
                etiquetaPeriodo(fechaInicio, fechaFin),
              ),
              pw.SizedBox(width: 10),
              _datoResumen('Total de registros', '${registros.length}'),
              pw.SizedBox(width: 10),
              _datoResumen(
                'Generado',
                '${fechacorta(generadoEn)} ${hora12(generadoEn)}',
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          _tituloSeccion('REGISTROS (${registros.length})'),
          pw.SizedBox(height: 8),
          if (registros.isEmpty)
            pw.Text(
              'No hay registros para el período seleccionado.',
              style: pw.TextStyle(fontSize: 9, color: _textoSecundario),
            )
          else
            _tablaRegistros(registros),
        ];
      },
    ),
  );

  return documento.save();
}
