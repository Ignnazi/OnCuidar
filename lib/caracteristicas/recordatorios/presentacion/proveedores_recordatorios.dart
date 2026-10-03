import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oncuidar/caracteristicas/pacientes/presentacion/proveedores_pacientes.dart';
import 'package:oncuidar/caracteristicas/recordatorios/datos/proveedores_recordatorios.dart';
import 'package:oncuidar/caracteristicas/recordatorios/dominio/recordatorio.dart';

final recordatoriosProvider = StreamProvider.autoDispose<List<Recordatorio>>((
  ref,
) {
  final pacienteAsync = ref.watch(pacienteActivoProvider);
  if (pacienteAsync is AsyncLoading) return const Stream.empty();
  final paciente = pacienteAsync.value;
  if (paciente == null) return Stream.value(const []);
  return ref
      .watch(repositorioRecordatoriosProvider)
      .recordatoriosEnTiempoReal(paciente.id);
});
