import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oncuidar/caracteristicas/biblioteca/datos/repositorio_biblioteca.dart';
import 'package:oncuidar/caracteristicas/biblioteca/datos/servicio_cache_contenido.dart';
import 'package:oncuidar/caracteristicas/biblioteca/datos/servicio_cache_metadata.dart';
import 'package:oncuidar/nucleo/proveedores.dart';

final repositorioBibliotecaProvider = Provider<RepositorioBiblioteca>((ref) {
  return RepositorioBiblioteca(ref.watch(baseDatosSeguraProvider));
});

final servicioCacheContenidoProvider = Provider<ServicioCacheContenido>((ref) {
  return ServicioCacheContenido();
});

final servicioCacheMetadataProvider = Provider<ServicioCacheMetadata>((ref) {
  return ServicioCacheMetadata();
});
