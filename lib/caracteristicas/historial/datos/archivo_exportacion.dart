import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

const _prefijoExportacion = 'historial_oncuidar_';

String nombreArchivoExportacion(DateTime ahora, String extension) {
  final mes = ahora.month.toString().padLeft(2, '0');
  final dia = ahora.day.toString().padLeft(2, '0');
  final fecha = '${ahora.year}-$mes-$dia';
  final hora =
      '${ahora.hour.toString().padLeft(2, '0')}${ahora.minute.toString().padLeft(2, '0')}';
  return '$_prefijoExportacion${fecha}_$hora.$extension';
}

Future<void> limpiarExportacionesViejas({Directory? directorio}) async {
  try {
    final dir = directorio ?? await getTemporaryDirectory();
    if (!await dir.exists()) return;
    await for (final entrada in dir.list()) {
      final nombre = entrada.uri.pathSegments.last;
      if (entrada is! File || !nombre.startsWith(_prefijoExportacion)) {
        continue;
      }
      try {
        await entrada.delete();
      } catch (_) {}
    }
  } catch (_) {}
}

Future<File> escribirArchivoTemporal(
  Uint8List bytes,
  String extension, {
  Directory? directorio,
}) async {
  final dir = directorio ?? await getTemporaryDirectory();
  await limpiarExportacionesViejas(directorio: dir);
  final archivo = File(
    '${dir.path}${Platform.pathSeparator}'
    '${nombreArchivoExportacion(DateTime.now(), extension)}',
  );
  await archivo.writeAsBytes(bytes, flush: true);
  return archivo;
}

Future<bool> descargarArchivoExportado(
  Uint8List bytes,
  String extension,
) async {
  try {
    final ruta = await FlutterFileDialog.saveFile(
      params: SaveFileDialogParams(
        data: bytes,
        fileName: nombreArchivoExportacion(DateTime.now(), extension),
        mimeTypesFilter: [
          extension == 'pdf'
              ? 'application/pdf'
              : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ],
      ),
    );
    return ruta != null;
  } catch (_) {
    return false;
  }
}

Future<void> compartirArchivoExportado(
  Uint8List bytes,
  String extension,
) async {
  final archivo = await escribirArchivoTemporal(bytes, extension);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(archivo.path)],
      subject: 'Historial clínico OnCuidar',
      text: 'Historial clínico OnCuidar',
    ),
  );
}
