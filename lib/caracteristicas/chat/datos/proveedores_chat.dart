import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oncuidar/caracteristicas/chat/datos/repositorio_conversaciones.dart';
import 'package:oncuidar/nucleo/proveedores.dart';

final repositorioConversacionesProvider = Provider<RepositorioConversaciones>((
  ref,
) {
  return RepositorioConversaciones(ref.watch(baseDatosSeguraProvider));
});
