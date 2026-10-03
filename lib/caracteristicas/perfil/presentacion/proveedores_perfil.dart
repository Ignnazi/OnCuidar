import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oncuidar/caracteristicas/perfil/datos/proveedores_perfil.dart';

final cuidadorProvider = StreamProvider.autoDispose<Map<String, dynamic>?>((
  ref,
) {
  return ref.watch(repositorioCuidadorProvider).cuidadorEnTiempoReal();
});
