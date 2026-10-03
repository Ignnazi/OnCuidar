import 'dart:typed_data';

import 'package:excel/excel.dart' as xlsx;
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/historial/exportadores/exportador_excel.dart';
import 'package:oncuidar/caracteristicas/historial/exportadores/exportador_pdf.dart';
import 'package:oncuidar/caracteristicas/historial/exportadores/orden_registros.dart';
import 'package:oncuidar/core/servicios/servicio_base_datos.dart';
import 'package:oncuidar/core/servicios/servicio_cifrado.dart';
import 'package:oncuidar/modelos/paciente.dart';
import 'package:oncuidar/modelos/registro_clinico.dart';

const _clavePrueba = 'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';
const _uid = 'uid-1';

RegistroClinico _registro(String id, String idPaciente, DateTime momento) =>
    RegistroClinico(
      id: id,
      pacienteId: idPaciente,
      fecha: momento,
      creadoEn: momento,
      tipoRegistro: 'programado',
      observaciones: 'obs-$id',
    );

Future<(ServicioBaseDatos, String, String)> _baseConDosPacientes() async {
  final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
  await cifrado.fijarClave(_uid, _clavePrueba);
  final base = ServicioBaseDatos(
    base: FakeFirebaseFirestore(),
    uidPrueba: _uid,
    cifrado: cifrado,
  );
  await base.crearCuidador({
    'displayName': 'Ana Torres',
    'email': 'cuidador@test.cl',
    'phone': '+56 9 1111 1111',
    'relationship': 'Madre',
    'address': 'Av. Siempre Viva 742',
  });
  final a = await base.crearPaciente(
    Paciente(id: 'a', fullName: 'Paciente A', createdAt: DateTime.now()),
  );
  final b = await base.crearPaciente(
    Paciente(id: 'b', fullName: 'Paciente B', createdAt: DateTime.now()),
  );
  return (base, a, b);
}

List<String> _observacionesExcel(Uint8List bytes) {
  final hoja = xlsx.Excel.decodeBytes(bytes)['Historial'];
  final filas = hoja.rows;
  final encabezado = filas.indexWhere(
    (f) => f.isNotEmpty && f.first?.value.toString() == 'Fecha',
  );
  return [
    for (final fila in filas.skip(encabezado + 1))
      if (fila.length > 9 && fila[9] != null) fila[9]!.value.toString(),
  ];
}

void main() {
  test('ordenarCronologicamente deja la lista ascendente', () {
    final base = DateTime(2026, 9, 10, 8);
    final lista = [
      _registro('c', 'p', base.add(const Duration(days: 2))),
      _registro('a', 'p', base),
      _registro('b', 'p', base.add(const Duration(hours: 3))),
    ];
    expect(ordenarCronologicamente(lista).map((r) => r.id), ['a', 'b', 'c']);
    expect(lista.first.id, 'c', reason: 'no debe mutar la lista original');
  });

  test('el Excel escribe las filas en orden ascendente', () {
    final base = DateTime(2026, 9, 10, 8);
    final bytes = generarExcelHistorial(
      registros: [
        _registro('tercero', 'p', base.add(const Duration(days: 2))),
        _registro('primero', 'p', base),
        _registro('segundo', 'p', base.add(const Duration(days: 1))),
      ],
      paciente: null,
      generadoEn: DateTime(2026, 9, 18),
    );
    expect(_observacionesExcel(bytes), [
      'obs-primero',
      'obs-segundo',
      'obs-tercero',
    ]);
  });

  test('el PDF ordena los registros de más antiguo a más reciente', () async {
    final base = DateTime(2026, 9, 10, 8);
    final bytes = await generarPdfHistorial(
      registros: [
        _registro('zzz', 'p', base.add(const Duration(days: 2))),
        _registro('aaa', 'p', base),
      ],
      paciente: null,
      generadoEn: DateTime(2026, 9, 18),
      comprimir: false,
    );
    final texto = String.fromCharCodes(bytes);
    expect(texto, isNot(contains('MEDICAMENTOS')));
    final primero = texto.indexOf('obs-aaa');
    final ultimo = texto.indexOf('obs-zzz');
    expect(primero, isNonNegative);
    expect(ultimo, greaterThan(primero), reason: 'el más antiguo va primero');
  });

  test(
    'la consulta por rango trae todo el rango, ascendente y del paciente',
    () async {
      final (base, a, b) = await _baseConDosPacientes();
      final inicio = DateTime(2026, 9, 1);
      for (var i = 0; i < 60; i++) {
        await base.guardarRegistroClinico(
          a,
          _registro('a$i', a, inicio.add(Duration(hours: 6 * i))),
        );
      }
      await base.guardarRegistroClinico(
        a,
        _registro('fuera', a, DateTime(2026, 8, 20)),
      );
      await base.guardarRegistroClinico(
        b,
        _registro('otro', b, DateTime(2026, 9, 5)),
      );

      final resultado = await base.registrosClinicosEnRango(
        a,
        desde: inicio,
        hasta: DateTime(2026, 10, 1),
      );

      expect(resultado, hasLength(60));
      expect(resultado.every((r) => r.pacienteId == a), isTrue);
      expect(resultado.map((r) => r.id), isNot(contains('fuera')));
      expect(resultado.map((r) => r.id), isNot(contains('otro')));
      for (var i = 1; i < resultado.length; i++) {
        expect(resultado[i].fecha.isBefore(resultado[i - 1].fecha), isFalse);
      }
      expect(
        resultado.first.observaciones,
        'obs-a0',
        reason: 'viene descifrado',
      );
    },
  );

  test(
    'la consulta sin límites trae todos los registros del paciente',
    () async {
      final (base, a, b) = await _baseConDosPacientes();
      await base.guardarRegistroClinico(
        a,
        _registro('x', a, DateTime(2025, 1, 1)),
      );
      await base.guardarRegistroClinico(
        a,
        _registro('y', a, DateTime(2026, 1, 1)),
      );
      await base.guardarRegistroClinico(
        b,
        _registro('z', b, DateTime(2026, 1, 1)),
      );
      final resultado = await base.registrosClinicosEnRango(a);
      expect(resultado.map((r) => r.id), ['x', 'y']);
    },
  );
}
