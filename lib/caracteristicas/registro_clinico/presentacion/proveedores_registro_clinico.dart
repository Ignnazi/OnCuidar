import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:oncuidar/caracteristicas/pacientes/presentacion/proveedores_pacientes.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/datos/proveedores_registro_clinico.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';

final registrosClinicosProvider =
    StreamProvider.autoDispose<List<RegistroClinico>>((ref) {
      final pacienteAsync = ref.watch(pacienteActivoProvider);
      if (pacienteAsync is AsyncLoading) return const Stream.empty();
      final paciente = pacienteAsync.value;
      if (paciente == null) return Stream.value(const []);
      return ref
          .watch(repositorioRegistrosClinicosProvider)
          .registrosClinicosEnTiempoReal(paciente.id);
    });

final registroEnEdicionProvider = StateProvider<RegistroClinico?>(
  (ref) => null,
);
