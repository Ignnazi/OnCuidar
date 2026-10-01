import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../modelos/paciente.dart';
import '../../../modelos/registro_clinico.dart';
import 'orden_registros.dart';

PdfColor _hex(String valor) => PdfColor.fromHex(valor);

String _corta(DateTime fecha) {
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  return '$dia-$mes-${fecha.year}';
}

String _hora12(DateTime fecha) {
  final hora = fecha.hour % 12 == 0 ? 12 : fecha.hour % 12;
  final sufijo = fecha.hour >= 12 ? 'PM' : 'AM';
  return '$hora:${fecha.minute.toString().padLeft(2, '0')} $sufijo';
}

String _estadoLabel(NivelAlerta nivel) {
  switch (nivel) {
    case NivelAlerta.normal:
      return 'Normal';
    case NivelAlerta.alerta:
      return 'Alerta';
    case NivelAlerta.critico:
      return 'Crítico';
  }
}

String _tipoLabel(String tipo) => tipo == 'extra' ? 'Extra' : 'Programado';

String _sintomasTexto(List<EntradaSintoma> sintomas) {
  return sintomas
      .map(
        (s) =>
            '${s.name} (${EntradaSintoma.etiquetaPara(s.intensity)}) ${s.intensity}/10',
      )
      .join(', ');
}

pw.Widget _encabezadoPagina(DateTime generadoEn, Paciente? paciente) {
  final nombre = paciente?.fullName.trim();
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
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'OnCuidar',
              style: pw.TextStyle(
                fontSize: 17,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'Historial Clínico',
              style: pw.TextStyle(
                fontSize: 10.5,
                color: PdfColors.white.withAlpha(0.9),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Generado: ${_corta(generadoEn)} ${_hora12(generadoEn)}',
              style: pw.TextStyle(
                fontSize: 8.5,
                color: PdfColors.white.withAlpha(0.8),
              ),
            ),
          ],
        ),
        if (nombre != null && nombre.isNotEmpty) ...[
          pw.Spacer(),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'PACIENTE',
                style: pw.TextStyle(
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white.withAlpha(0.75),
                  letterSpacing: 1.2,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                nombre,
                style: pw.TextStyle(
                  fontSize: 10.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

pw.Widget _piePagina(pw.Context contexto) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 10),
    child: pw.Row(
      children: [
        pw.Expanded(
          child: pw.Text(
            'OnCuidar · apoyo al cuidado oncológico pediátrico',
            style: pw.TextStyle(fontSize: 7.5, color: _hex('#9A8060')),
          ),
        ),
        pw.Text(
          'Página ${contexto.pageNumber} de ${contexto.pagesCount}',
          style: pw.TextStyle(fontSize: 8, color: _hex('#9A8060')),
        ),
      ],
    ),
  );
}

pw.Widget _seccionTitulo(
  String titulo,
  pw.TextStyle estiloTexto,
  PdfColor fondo,
) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    decoration: pw.BoxDecoration(
      color: fondo,
      borderRadius: pw.BorderRadius.circular(4),
    ),
    child: pw.Row(
      children: [
        pw.Container(
          width: 3,
          height: 14,
          decoration: pw.BoxDecoration(
            color: _hex('#E8A820'),
            borderRadius: pw.BorderRadius.circular(1),
          ),
        ),
        pw.SizedBox(width: 6),
        pw.Text(titulo, style: estiloTexto),
      ],
    ),
  );
}

pw.Widget _cajasRegistrosPorEstado(List<RegistroClinico> registros) {
  final conteos = <NivelAlerta, int>{
    NivelAlerta.normal: 0,
    NivelAlerta.alerta: 0,
    NivelAlerta.critico: 0,
  };
  for (final registro in registros) {
    conteos[registro.nivelAlerta] = conteos[registro.nivelAlerta]! + 1;
  }

  const paletas = <NivelAlerta, (String fondo, String color, String label)>{
    NivelAlerta.normal: ('#E6F7F0', '#1FA97C', 'Normal'),
    NivelAlerta.alerta: ('#FFF4D0', '#E8A820', 'Alerta'),
    NivelAlerta.critico: ('#FDE8EE', '#E11D48', 'Crítico'),
  };

  return pw.Row(
    children: [
      for (final nivel in NivelAlerta.values) ...[
        if (nivel != NivelAlerta.values.first) pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            decoration: pw.BoxDecoration(
              color: _hex(paletas[nivel]!.$1),
              border: pw.Border(
                left: pw.BorderSide(color: _hex(paletas[nivel]!.$2), width: 3),
              ),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  '${conteos[nivel]}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: _hex(paletas[nivel]!.$2),
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  paletas[nivel]!.$3,
                  style: pw.TextStyle(
                    fontSize: 7.5,
                    color: _hex(paletas[nivel]!.$2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ],
  );
}

pw.Widget _filaEtiquetaValor(
  String etiqueta,
  String valor,
  pw.TextStyle estiloEtiqueta,
  pw.TextStyle estiloValor,
) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 3),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 120,
          child: pw.Text(etiqueta, style: estiloEtiqueta),
        ),
        pw.Expanded(child: pw.Text(valor, style: estiloValor)),
      ],
    ),
  );
}

pw.Widget _tablaRegistros(
  List<RegistroClinico> registros,
  pw.TextStyle estiloEncabezado,
  pw.TextStyle estiloCelda,
) {
  const encabezados = [
    'Fecha',
    'Hora',
    'Tipo',
    'Estado',
    'Temp.',
    'F.C.',
    'Sat. O2',
    'F.R.',
    'Síntomas',
    'Observaciones',
  ];

  final datos = [
    for (final rec in ordenarCronologicamente(registros)) _filaRegistro(rec),
  ];

  return pw.TableHelper.fromTextArray(
    headers: encabezados,
    data: datos,
    headerStyle: estiloEncabezado,
    headerDecoration: pw.BoxDecoration(
      color: _hex('#E8A820'),
      borderRadius: pw.BorderRadius.only(
        topLeft: pw.Radius.circular(4),
        topRight: pw.Radius.circular(4),
      ),
    ),
    headerPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    cellStyle: estiloCelda,
    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    cellHeight: 18,
    rowDecoration: pw.BoxDecoration(color: PdfColors.white),
    oddRowDecoration: pw.BoxDecoration(color: _hex('#FFF9E8')),
    columnWidths: const {
      0: pw.FixedColumnWidth(46),
      1: pw.FixedColumnWidth(40),
      2: pw.FixedColumnWidth(50),
      3: pw.FixedColumnWidth(42),
      4: pw.FixedColumnWidth(30),
      5: pw.FixedColumnWidth(38),
      6: pw.FixedColumnWidth(34),
      7: pw.FixedColumnWidth(30),
      8: pw.FixedColumnWidth(120),
      9: pw.FixedColumnWidth(105),
    },
    textStyleBuilder: (indice, valor, _) {
      if (indice != 3) return null;
      final color = switch (valor) {
        'Normal' => _hex('#1FA97C'),
        'Alerta' => _hex('#E8A820'),
        'Crítico' => _hex('#E11D48'),
        _ => null,
      };
      if (color == null) return null;
      return pw.TextStyle(
        fontSize: 7.5,
        fontWeight: pw.FontWeight.bold,
        color: color,
      );
    },
    border: pw.TableBorder(
      top: pw.BorderSide(color: _hex('#E8A820'), width: 0.6),
      bottom: pw.BorderSide(color: _hex('#E8DCC0'), width: 0.5),
      left: pw.BorderSide(color: _hex('#F0E6D0'), width: 0.5),
      right: pw.BorderSide(color: _hex('#F0E6D0'), width: 0.5),
      horizontalInside: pw.BorderSide(color: _hex('#E8DCC0'), width: 0.4),
      verticalInside: pw.BorderSide(color: _hex('#F0E6D0'), width: 0.4),
    ),
  );
}

List<dynamic> _filaRegistro(RegistroClinico rec) {
  final vs = rec.signosVitales;
  return [
    _corta(rec.fecha),
    _hora12(rec.creadoEn),
    _tipoLabel(rec.tipoRegistro),
    _estadoLabel(rec.nivelAlerta),
    vs?.temperature != null ? '${vs!.temperature!.toStringAsFixed(1)}°C' : '-',
    vs?.heartRate != null ? '${vs!.heartRate} lpm' : '-',
    vs?.oxygenSaturation != null ? '${vs!.oxygenSaturation}%' : '-',
    vs?.respiratoryRate != null ? '${vs!.respiratoryRate} rpm' : '-',
    _sintomasTexto(rec.sintomas),
    rec.observaciones?.isNotEmpty == true ? rec.observaciones! : '-',
  ];
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
  final doradoOscuro = _hex('#C08808');
  final doradoClaro = _hex('#FFF4D0');
  final textoPrincipal = _hex('#2C1A00');
  final textoSecundario = _hex('#9A8060');

  final estiloSeccion = pw.TextStyle(
    fontSize: 10,
    fontWeight: pw.FontWeight.bold,
    color: doradoOscuro,
    letterSpacing: 0.5,
  );
  final estiloEtiqueta = pw.TextStyle(
    fontSize: 8.5,
    fontWeight: pw.FontWeight.bold,
    color: doradoOscuro,
  );
  final estiloValor = pw.TextStyle(fontSize: 8.5, color: textoSecundario);
  final estiloEncabezadoTabla = pw.TextStyle(
    fontSize: 8,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.white,
    letterSpacing: 0.4,
  );
  final estiloCelda = pw.TextStyle(fontSize: 7.5, color: textoPrincipal);

  final inicio = fechaInicio != null ? _corta(fechaInicio) : 'sin inicio';
  final fin = fechaFin != null ? _corta(fechaFin) : 'sin fin';

  final documento = pw.Document(compress: comprimir);

  documento.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(30),
      header: (_) => _encabezadoPagina(generadoEn, paciente),
      footer: _piePagina,
      build: (_) {
        final contenido = <pw.Widget>[pw.SizedBox(height: 6)];

        if (paciente != null) {
          contenido.add(_seccionTitulo('PACIENTE', estiloSeccion, doradoClaro));
          contenido.add(pw.SizedBox(height: 6));
          contenido.add(
            _filaEtiquetaValor(
              'Nombre',
              paciente.fullName,
              estiloEtiqueta,
              estiloValor,
            ),
          );
          if (paciente.age != null) {
            contenido.add(
              _filaEtiquetaValor(
                'Edad',
                '${paciente.age} años',
                estiloEtiqueta,
                estiloValor,
              ),
            );
          }
          if (paciente.diagnosis?.isNotEmpty == true) {
            contenido.add(
              _filaEtiquetaValor(
                'Diagnóstico',
                paciente.diagnosis!,
                estiloEtiqueta,
                estiloValor,
              ),
            );
          }
          if (paciente.tratamientoFase?.isNotEmpty == true) {
            contenido.add(
              _filaEtiquetaValor(
                'Fase',
                paciente.tratamientoFase!,
                estiloEtiqueta,
                estiloValor,
              ),
            );
          }
          contenido.add(pw.SizedBox(height: 10));
        }

        final nombreLimpio = nombreCuidador?.trim();
        if (nombreLimpio != null && nombreLimpio.isNotEmpty) {
          contenido.add(_seccionTitulo('CUIDADOR', estiloSeccion, doradoClaro));
          contenido.add(pw.SizedBox(height: 6));
          contenido.add(
            _filaEtiquetaValor(
              'Nombre',
              nombreLimpio,
              estiloEtiqueta,
              estiloValor,
            ),
          );
          contenido.add(pw.SizedBox(height: 10));
        }

        if (paciente?.centroSaludNombre?.isNotEmpty == true) {
          contenido.add(
            _seccionTitulo('CENTRO DE SALUD', estiloSeccion, doradoClaro),
          );
          contenido.add(pw.SizedBox(height: 6));
          contenido.add(
            _filaEtiquetaValor(
              'Nombre',
              paciente!.centroSaludNombre!,
              estiloEtiqueta,
              estiloValor,
            ),
          );
          if (paciente.centroSaludDireccion?.isNotEmpty == true) {
            contenido.add(
              _filaEtiquetaValor(
                'Dirección',
                paciente.centroSaludDireccion!,
                estiloEtiqueta,
                estiloValor,
              ),
            );
          }
          if (paciente.centroSaludTelefono?.isNotEmpty == true) {
            contenido.add(
              _filaEtiquetaValor(
                'Teléfono',
                paciente.centroSaludTelefono!,
                estiloEtiqueta,
                estiloValor,
              ),
            );
          }
          contenido.add(pw.SizedBox(height: 10));
        }

        if (paciente?.contactoEmergenciaNombre?.isNotEmpty == true) {
          contenido.add(
            _seccionTitulo(
              'CONTACTO DE EMERGENCIA',
              estiloSeccion,
              doradoClaro,
            ),
          );
          contenido.add(pw.SizedBox(height: 6));
          contenido.add(
            _filaEtiquetaValor(
              'Nombre',
              paciente!.contactoEmergenciaNombre!,
              estiloEtiqueta,
              estiloValor,
            ),
          );
          if (paciente.contactoEmergenciaTelefono?.isNotEmpty == true) {
            contenido.add(
              _filaEtiquetaValor(
                'Teléfono',
                paciente.contactoEmergenciaTelefono!,
                estiloEtiqueta,
                estiloValor,
              ),
            );
          }
          contenido.add(pw.SizedBox(height: 10));
        }

        contenido.add(_seccionTitulo('RESUMEN', estiloSeccion, doradoClaro));
        contenido.add(pw.SizedBox(height: 6));
        contenido.add(
          _filaEtiquetaValor(
            'Rango',
            '$inicio - $fin',
            estiloEtiqueta,
            estiloValor,
          ),
        );
        contenido.add(
          _filaEtiquetaValor(
            'Total registros',
            '${registros.length}',
            estiloEtiqueta,
            estiloValor,
          ),
        );
        contenido.add(
          _filaEtiquetaValor(
            'Generado',
            '${_corta(generadoEn)} ${_hora12(generadoEn)}',
            estiloEtiqueta,
            estiloValor,
          ),
        );
        if (registros.isNotEmpty) {
          contenido.add(pw.SizedBox(height: 8));
          contenido.add(pw.Text('Registros por estado', style: estiloEtiqueta));
          contenido.add(pw.SizedBox(height: 5));
          contenido.add(_cajasRegistrosPorEstado(registros));
        }
        contenido.add(pw.SizedBox(height: 15));

        contenido.add(
          _seccionTitulo(
            'REGISTROS (${registros.length})',
            estiloSeccion,
            doradoClaro,
          ),
        );
        contenido.add(pw.SizedBox(height: 8));

        if (registros.isEmpty) {
          contenido.add(
            pw.Text(
              'No hay registros para el rango seleccionado.',
              style: estiloValor,
            ),
          );
        } else {
          contenido.add(
            _tablaRegistros(registros, estiloEncabezadoTabla, estiloCelda),
          );
        }

        return contenido;
      },
    ),
  );

  return documento.save();
}
