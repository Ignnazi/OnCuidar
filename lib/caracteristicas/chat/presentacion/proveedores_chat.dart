import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oncuidar/caracteristicas/chat/datos/proveedores_chat.dart';
import 'package:oncuidar/caracteristicas/chat/dominio/conversacion.dart';

final conversacionesProvider = StreamProvider.autoDispose<List<Conversacion>>((
  ref,
) {
  return ref
      .watch(repositorioConversacionesProvider)
      .conversacionesEnTiempoReal();
});
