import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/historial/exportadores/exportador_excel.dart';
import 'package:oncuidar/caracteristicas/historial/exportadores/exportador_pdf.dart';
import 'package:oncuidar/modelos/paciente.dart';
import 'package:oncuidar/modelos/registro_clinico.dart';

Paciente _paciente() => Paciente(
  id: 'paciente-1',
  fullName: 'Paciente Test',
  age: 8,
  diagnosis: 'Leucemia linfoblástica aguda',
  tratamientoFase: 'Mantenimiento',
  centroSaludNombre: 'Hospital Pediátrico',
  centroSaludTelefono: '+56 2 2222 2222',
  contactoEmergenciaNombre: 'María Test',
  contactoEmergenciaTelefono: '+56 9 1111 1111',
  createdAt: DateTime.now(),
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
      temperature: 36.5,
      heartRate: 72,
      oxygenSaturation: 98,
      respiratoryRate: 16,
    ),
    nivelAlerta: NivelAlerta.critico,
    sintomas: const [
      EntradaSintoma(name: 'Dolor de cabeza', intensity: 7),
      EntradaSintoma(name: 'Fiebre', intensity: 4),
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
  final workbook =
      archivo.files.firstWhere((f) => f.name == 'xl/workbook.xml');
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
}