import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/historial/datos/archivo_exportacion.dart';

void main() {
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('oncuidar_exportacion_');
  });

  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  List<String> nombres() =>
      dir.listSync().map((e) => e.uri.pathSegments.last).toList()..sort();

  test('limpiarExportacionesViejas borra solo las exportaciones', () async {
    File(
      '${dir.path}/historial_oncuidar_2026-01-01_1000.pdf',
    ).writeAsStringSync('a');
    File(
      '${dir.path}/historial_oncuidar_2026-01-02_1100.xlsx',
    ).writeAsStringSync('b');
    File('${dir.path}/otro_archivo.pdf').writeAsStringSync('c');

    await limpiarExportacionesViejas(directorio: dir);

    expect(nombres(), ['otro_archivo.pdf']);
  });

  test('exportar de nuevo borra la exportación anterior', () async {
    File(
      '${dir.path}/historial_oncuidar_2026-01-01_1000.pdf',
    ).writeAsStringSync('vieja');
    File('${dir.path}/otro_archivo.pdf').writeAsStringSync('c');

    final nuevo = await escribirArchivoTemporal(
      Uint8List.fromList([1, 2, 3]),
      'pdf',
      directorio: dir,
    );

    expect(nuevo.readAsBytesSync(), [1, 2, 3]);
    expect(
      nombres(),
      {nuevo.uri.pathSegments.last, 'otro_archivo.pdf'}.toList()..sort(),
    );
  });

  test('limpiar un directorio sin exportaciones no falla', () async {
    await limpiarExportacionesViejas(directorio: dir);
    expect(nombres(), isEmpty);
  });
}
