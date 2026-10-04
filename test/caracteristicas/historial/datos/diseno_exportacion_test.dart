import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart' as xlsx;
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/historial/datos/exportador_excel.dart';
import 'package:oncuidar/caracteristicas/historial/datos/exportador_pdf.dart';
import 'package:oncuidar/caracteristicas/historial/datos/formato_exportacion.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/paciente.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';

import '../../../ayudas/exportacion.dart';

Paciente _paciente() => Paciente(
  id: 'p1',
  nombreCompleto: 'Paciente Test',
  edad: 8,
  diagnostico: 'Leucemia linfoblástica aguda',
  tratamientoFase: 'Mantenimiento',
  centroSaludNombre: 'Hospital Pediátrico',
  centroSaludDireccion: 'Av. Siempre Viva 742',
  centroSaludTelefono: '+56 2 2222 2222',
  contactoEmergenciaNombre: 'María Test',
  contactoEmergenciaTelefono: '+56 9 1111 1111',
  creadoEn: DateTime(2026, 1, 1),
);

RegistroClinico _registro({String observaciones = 'Observación'}) {
  final fecha = DateTime(2026, 10, 4, 9);
  return RegistroClinico(
    id: 'r',
    pacienteId: 'p1',
    fecha: fecha,
    creadoEn: fecha,
    tipoRegistro: 'programado',
    nivelAlerta: NivelAlerta.alerta,
    observaciones: observaciones,
  );
}

Future<String> _textoDelPdf({DateTime? inicio, DateTime? fin}) async =>
    textoPdf(
      await generarPdfHistorial(
        registros: [_registro()],
        paciente: _paciente(),
        nombreCuidador: 'Ana Torres',
        fechaInicio: inicio,
        fechaFin: fin,
        generadoEn: DateTime(2026, 10, 8, 20, 15),
      ),
    );

String _sinEspacios(String texto) => texto.replaceAll(' ', '');

String _xmlDelExcel(Uint8List bytes) => ZipDecoder()
    .decodeBytes(bytes)
    .files
    .where((f) => f.name.endsWith('.xml'))
    .map((f) => utf8.decode(f.content as List<int>))
    .join('\n');

void main() {
  group('Período filtrado', () {
    test('un solo día se dice como día', () {
      final dia = DateTime(2026, 10, 4);
      expect(rotuloPeriodo(dia, null), 'Día');
      expect(etiquetaPeriodo(dia, null), 'Domingo 04/10/2026');
      final mismoDia = DateTime(2026, 10, 4, 23);
      expect(rotuloPeriodo(dia, mismoDia), 'Día');
      expect(etiquetaPeriodo(dia, mismoDia), 'Domingo 04/10/2026');
    });

    test('varios días se dicen como «del … al …»', () {
      final inicio = DateTime(2026, 10, 4);
      final fin = DateTime(2026, 10, 7);
      expect(etiquetaPeriodo(inicio, fin), 'Del 04-10-2026 al 07-10-2026');
      expect(rotuloPeriodo(inicio, fin), 'Período');
    });

    test('sin filtro de fechas o con una sola cota', () {
      expect(etiquetaPeriodo(null, null), 'Todos los registros');
      expect(
        etiquetaPeriodo(null, DateTime(2026, 10, 7)),
        'Hasta el 07-10-2026',
      );
    });

    test('nunca aparece «sin inicio» ni «sin fin»', () async {
      for (final (inicio, fin) in [
        (null, null),
        (DateTime(2026, 10, 4), null),
        (null, DateTime(2026, 10, 7)),
      ]) {
        final texto = await _textoDelPdf(inicio: inicio, fin: fin);
        expect(texto, isNot(contains('sin inicio')));
        expect(texto, isNot(contains('sin fin')));
      }
    });
  });

  group('PDF', () {
    test('muestra el día filtrado y el rango en el resumen', () async {
      expect(
        await _textoDelPdf(inicio: DateTime(2026, 10, 4)),
        allOf(contains(_sinEspacios('Domingo 04/10/2026')), contains('DÍA')),
      );
      expect(
        await _textoDelPdf(
          inicio: DateTime(2026, 10, 4),
          fin: DateTime(2026, 10, 7),
        ),
        contains(_sinEspacios('Del 04-10-2026 al 07-10-2026')),
      );
    });

    test('ya no incluye el recuadro de registros por estado', () async {
      final texto = await _textoDelPdf();
      expect(texto, isNot(contains(_sinEspacios('Registros por estado'))));
      expect(texto, isNot(contains('Rango')));
    });

    test('trae la ficha completa y el resumen', () async {
      final texto = await _textoDelPdf();
      for (final dato in [
        'PACIENTE',
        'CUIDADOR',
        'CENTRO DE SALUD',
        'CONTACTO DE EMERGENCIA',
        'RESUMEN',
        'Paciente Test',
        'Ana Torres',
        'Hospital Pediátrico',
        'María Test',
      ]) {
        expect(texto, contains(_sinEspacios(dato)), reason: 'falta «$dato»');
      }
    });
  });

  group('Ficha en dos columnas', () {
    test(
      'paciente y cuidador a la izquierda; centro y contacto a la derecha',
      () {
        final izquierda = bloquesPacienteYCuidador(_paciente(), 'Ana Torres');
        final derecha = bloquesCentroYContacto(_paciente());

        expect([for (final b in izquierda) b.titulo], ['PACIENTE', 'CUIDADOR']);
        expect(
          [for (final b in derecha) b.titulo],
          ['CENTRO DE SALUD', 'CONTACTO DE EMERGENCIA'],
        );
      },
    );

    test('solo aparecen los bloques con datos', () {
      expect(bloquesPacienteYCuidador(null, ''), isEmpty);
      expect(bloquesCentroYContacto(null), isEmpty);
      final soloNombre = Paciente(
        id: 'p',
        nombreCompleto: 'Solo Nombre',
        creadoEn: DateTime(2026, 1, 1),
      );
      expect(bloquesCentroYContacto(soloNombre), isEmpty);
      expect(bloquesPacienteYCuidador(soloNombre, null), hasLength(1));
    });
  });

  group('Excel', () {
    Uint8List generar({String obs = 'Observación', DateTime? inicio}) =>
        generarExcelHistorial(
          registros: [_registro(observaciones: obs)],
          paciente: _paciente(),
          nombreCuidador: 'Ana Torres',
          fechaInicio: inicio,
          generadoEn: DateTime(2026, 10, 8, 20, 15),
        );

    test('dice el día filtrado y no «sin inicio»', () {
      final xml = _xmlDelExcel(generar(inicio: DateTime(2026, 10, 4)));
      expect(xml, contains('Domingo 04/10/2026'));
      expect(xml, isNot(contains('sin inicio')));
      expect(xml, isNot(contains('sin fin')));
    });

    test('la ficha lleva el centro de salud a la derecha del paciente', () {
      final hoja = xlsx.Excel.decodeBytes(generar())['Historial'];
      String texto(int columna, int fila) =>
          hoja
              .cell(
                xlsx.CellIndex.indexByColumnRow(
                  columnIndex: columna,
                  rowIndex: fila,
                ),
              )
              .value
              ?.toString() ??
          '';

      final filaTitulos = [
        for (var f = 0; f < 12; f++)
          if (texto(0, f) == 'PACIENTE') f,
      ].single;
      expect(texto(5, filaTitulos), 'CENTRO DE SALUD');
    });

    test('los textos largos se ajustan: salto de línea y fila más alta', () {
      final corta = generar();
      final larga = generar(obs: 'palabra ' * 40);
      int alto(Uint8List bytes) {
        final xml = _xmlDelExcel(bytes);
        final alturas = [
          for (final m in RegExp(r'<row[^>]* ht="([\d.]+)"').allMatches(xml))
            double.parse(m.group(1)!).round(),
        ];
        return alturas.reduce((a, b) => a > b ? a : b);
      }

      expect(alto(larga), greaterThan(alto(corta)));
      expect(_xmlDelExcel(larga), contains('wrapText="1"'));
    });

    test('las celdas vacías muestran un guion, no quedan en blanco', () {
      final hoja = xlsx.Excel.decodeBytes(
        generarExcelHistorial(
          registros: [_registro(observaciones: '')],
          paciente: null,
          generadoEn: DateTime(2026, 10, 8),
        ),
      )['Historial'];
      final textos = [
        for (final fila in hoja.rows)
          for (final celda in fila)
            if (celda != null) celda.value.toString(),
      ];
      expect(textos.where((t) => t == '–').length, 6);
    });
  });

  group('lineasNecesarias', () {
    test('un texto corto ocupa una línea', () {
      expect(lineasNecesarias('Hola', 40), 1);
      expect(lineasNecesarias('', 40), 1);
    });

    test('reparte por palabras sin partirlas', () {
      expect(lineasNecesarias('uno dos tres cuatro', 8), 3);
    });

    test('una palabra más larga que la celda se parte', () {
      expect(lineasNecesarias('a' * 25, 10), 3);
    });

    test('respeta los saltos de línea', () {
      expect(lineasNecesarias('uno\ndos\ntres', 40), 3);
    });
  });
}
