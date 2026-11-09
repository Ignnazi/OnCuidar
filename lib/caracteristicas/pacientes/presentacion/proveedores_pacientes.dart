import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oncuidar/caracteristicas/pacientes/datos/proveedores_pacientes.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/paciente.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _clavePacienteSeleccionado = 'selected_patient_id';

final pacientesProvider = StreamProvider.autoDispose<List<Paciente>>((ref) {
  return ref.watch(repositorioPacientesProvider).pacientesEnTiempoReal();
});

final pacientesArchivadosProvider = StreamProvider.autoDispose<List<Paciente>>((
  ref,
) {
  return ref
      .watch(repositorioPacientesProvider)
      .pacientesArchivadosEnTiempoReal();
});

class PacienteSeleccionadoNotifier extends Notifier<String?> {
  bool _elegido = false;

  @override
  String? build() {
    _cargarDelPrefs();
    return null;
  }

  Future<void> _cargarDelPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final guardado = prefs.getString(_clavePacienteSeleccionado);
      // Lo guardado no pisa una selección hecha mientras se leía
      if (guardado != null && !_elegido) state = guardado;
    } catch (_) {
      // Si falla, se sigue igual.
    }
  }

  Future<void> seleccionar(String? idPaciente) async {
    _elegido = true;
    state = idPaciente;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (idPaciente == null) {
        await prefs.remove(_clavePacienteSeleccionado);
      } else {
        await prefs.setString(_clavePacienteSeleccionado, idPaciente);
      }
    } catch (_) {
      // Si falla, se sigue igual.
    }
  }
}

final idPacienteSeleccionadoProvider =
    NotifierProvider<PacienteSeleccionadoNotifier, String?>(
      PacienteSeleccionadoNotifier.new,
    );

final pacienteActivoProvider = StreamProvider.autoDispose<Paciente?>((
  ref,
) async* {
  final pacientesAsync = ref.watch(pacientesProvider);
  if (pacientesAsync is AsyncLoading) return;
  if (pacientesAsync is AsyncError && !pacientesAsync.hasValue) {
    throw pacientesAsync.error!;
  }
  final pacientes = pacientesAsync.value ?? const <Paciente>[];
  if (pacientes.isEmpty) {
    yield null;
    return;
  }
  final seleccionadoId = ref.watch(idPacienteSeleccionadoProvider);
  if (seleccionadoId != null) {
    for (final paciente in pacientes) {
      if (paciente.id == seleccionadoId) {
        yield paciente;
        return;
      }
    }
  }
  yield pacientes.first;
});
