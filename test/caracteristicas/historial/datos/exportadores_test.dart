import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart' as xlsx;
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/historial/datos/exportador_excel.dart';
import 'package:oncuidar/caracteristicas/historial/datos/exportador_pdf.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/paciente.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';

Paciente _paciente() => Paciente(
  id: 'paciente-1',
  nombreCompleto: 'Paciente Test',
  edad: 8,
  diagnostico: 'Leucemia linfoblástica aguda',
  tratamientoFase: 'Mantenimiento',
  centroSaludNombre: 'Hospital Pediátrico',
  centroSaludTelefono: '+56 2 2222 2222',
  contactoEmergenciaNombre: 'María Test',
  contactoEmergenciaTelefono: '+56 9 1111 1111',
  creadoEn: DateTime.now(),
);

RegistroClinico _registroConSignos(String id) {
  final ahora = DateTime.now();
  return RegistroClinico(
    id: id,
    pacienteId: 'paciente-1',
    fecha: ahora,
    creadoEn: ahora.subtract(const Duration(hours: 2)),
    tipoRegistro: 'programado',
    signosVitales: const SignosVitales(
      temperatura: 36.5,
      frecuenciaCardiaca: 72,
      saturacionOxigeno: 98,
      frecuenciaRespiratoria: 16,
    ),
    nivelAlerta: NivelAlerta.critico,
    sintomas: const [
      EntradaSintoma(nombre: 'Dolor de cabeza', intensidad: 7),
      EntradaSintoma(nombre: 'Fiebre', intensidad: 4),
    ],
    observaciones: 'Paciente estable durante el día',
  );
}

String _textoXml(Uint8List bytes) {
  final archivo = ZipDecoder().decodeBytes(bytes);
  return archivo.files
      .where((f) => f.name.endsWith('.xml'))
      .map((f) => utf8.decode(f.content as List<int>))
      .join('\n');
}

List<String> _nombresHojas(Uint8List bytes) {
  final archivo = ZipDecoder().decodeBytes(bytes);
  final workbook = archivo.files.firstWhere((f) => f.name == 'xl/workbook.xml');
  final xml = utf8.decode(workbook.content as List<int>);
  return [
    for (final match in RegExp(r'<sheet[^>]*name="([^"]+)"').allMatches(xml))
      match.group(1)!,
  ];
}

void main() {
  test('el PDF generado es un documento válido con un registro', () async {
    final bytes = await generarPdfHistorial(
      registros: [_registroConSignos('registro-1')],
      paciente: _paciente(),
      nombreCuidador: 'Ana Torres',
      fechaInicio: DateTime(2026, 9, 1),
      fechaFin: DateTime(2026, 9, 18),
      generadoEn: DateTime(2026, 9, 18, 20, 54),
    );

    expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
    expect(bytes.length, greaterThan(1000));
  });

  test('el PDF crece al agregar más registros', () async {
    final baseParametros = (
      paciente: _paciente(),
      nombreCuidador: 'Ana Torres',
      fechaInicio: DateTime(2026, 9, 1),
      fechaFin: DateTime(2026, 9, 18),
      generadoEn: DateTime(2026, 9, 18, 20, 54),
    );

    final uno = await generarPdfHistorial(
      registros: [_registroConSignos('registro-1')],
      paciente: baseParametros.paciente,
      nombreCuidador: baseParametros.nombreCuidador,
      fechaInicio: baseParametros.fechaInicio,
      fechaFin: baseParametros.fechaFin,
      generadoEn: baseParametros.generadoEn,
    );
    final dos = await generarPdfHistorial(
      registros: [
        _registroConSignos('registro-1'),
        _registroConSignos('registro-2'),
      ],
      paciente: baseParametros.paciente,
      nombreCuidador: baseParametros.nombreCuidador,
      fechaInicio: baseParametros.fechaInicio,
      fechaFin: baseParametros.fechaFin,
      generadoEn: baseParametros.generadoEn,
    );

    expect(
      dos.length,
      greaterThan(uno.length),
      reason: 'un registro extra debe aumentar el tamaño del PDF',
    );
  });

  test('el PDF genera sin crashear con lista vacía', () async {
    final bytes = await generarPdfHistorial(
      registros: const [],
      paciente: _paciente(),
      nombreCuidador: 'Ana Torres',
      fechaInicio: null,
      fechaFin: null,
      generadoEn: DateTime(2026, 9, 18, 20, 54),
    );

    expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
    expect(bytes.length, greaterThan(1000));
  });

  test('el Excel generado es un archivo xlsx con la hoja Historial', () {
    final bytes = generarExcelHistorial(
      registros: [_registroConSignos('registro-1')],
      paciente: _paciente(),
      nombreCuidador: 'Ana Torres',
      fechaInicio: DateTime(2026, 9, 1),
      fechaFin: DateTime(2026, 9, 18),
      generadoEn: DateTime(2026, 9, 18, 20, 54),
    );

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.sublist(0, 2)), 'PK');

    final contenido = _textoXml(bytes);
    expect(contenido, contains('Historial'));
    expect(contenido, contains('HISTORIAL ONCUIDAR'));
    expect(contenido, contains('Paciente Test'));

    final hojas = _nombresHojas(bytes);
    expect(hojas, hasLength(1));
    expect(hojas, contains('Historial'));
    expect(hojas, isNot(contains('Sheet1')));

    expect(contenido, isNot(contains('Sheet1')));
  });

  test('el Excel genera sin crashear con lista vacía', () {
    final bytes = generarExcelHistorial(
      registros: const [],
      paciente: null,
      nombreCuidador: '',
      fechaInicio: null,
      fechaFin: null,
      generadoEn: DateTime(2026, 9, 18, 20, 54),
    );

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.sublist(0, 2)), 'PK');
  });

  test('la hoja Historial tiene las columnas legibles (CA-11.3)', () {
    final bytes = generarExcelHistorial(
      registros: [_registroConSignos('r1')],
      paciente: _paciente(),
      nombreCuidador: 'Ana',
      fechaInicio: null,
      fechaFin: null,
      generadoEn: DateTime(2026, 9, 18, 20, 54),
    );

    final filas = xlsx.Excel.decodeBytes(bytes)['Historial'].rows;
    final encabezado = filas.firstWhere(
      (f) => f.isNotEmpty && f.first?.value.toString() == 'Fecha',
    );
    expect(
      [
        for (final celda in encabezado)
          if (celda != null) celda.value.toString(),
      ],
      [
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
      ],
    );
  });
}
