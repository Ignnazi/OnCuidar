import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oncuidar/caracteristicas/recordatorios/datos/repositorio_recordatorios.dart';
import 'package:oncuidar/nucleo/proveedores.dart';

final repositorioRecordatoriosProvider = Provider<RepositorioRecordatorios>((
  ref,
) {
  return RepositorioRecordatorios(ref.watch(baseDatosSeguraProvider));
});
