import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oncuidar/caracteristicas/perfil/datos/repositorio_cuidador.dart';
import 'package:oncuidar/nucleo/proveedores.dart';

final repositorioCuidadorProvider = Provider<RepositorioCuidador>((ref) {
  return RepositorioCuidador(ref.watch(baseDatosSeguraProvider));
});
