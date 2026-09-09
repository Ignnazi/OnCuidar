import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../modelos/paciente.dart';
import '../servicios/servicio_base_datos.dart';
import '../servicios/servicio_cifrado.dart';
import '../servicios/servicio_registro.dart';

final servicioCifradoProvider = Provider<ServicioCifrado>((ref) {
  return ServicioCifrado();
});

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final estadoAutenticacionProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

class BloqueoCifradoNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void fijarDesbloqueado(bool valor) => state = valor;
}

final bloqueoCifradoProvider = NotifierProvider<BloqueoCifradoNotifier, bool>(
  BloqueoCifradoNotifier.new,
);

final servicioBaseDatosProvider = Provider<ServicioBaseDatos>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return ServicioBaseDatos(
    base: FirebaseFirestore.instance,
    auth: auth,
    cifrado: ref.watch(servicioCifradoProvider),
  );
});

final servicioRegistroProvider = Provider<ServicioRegistro>((ref) {
  return ServicioRegistro(
    auth: ref.watch(firebaseAuthProvider),
    cifrado: ref.watch(servicioCifradoProvider),
    baseDatos: ref.watch(servicioBaseDatosProvider),
    alDesbloquear: () =>
        ref.read(bloqueoCifradoProvider.notifier).fijarDesbloqueado(true),
  );
});

const _clavePacienteSeleccionado = 'selected_patient_id';

/// Lista de pacientes activos (no archivados) del cuidador autenticado, en
/// tiempo real. Se excluyen los pacientes con `archivado == true`.
final patientsListProvider = StreamProvider.autoDispose<List<Paciente>>((ref) {
  return ref.watch(servicioBaseDatosProvider).pacientesEnTiempoReal();
});

/// Lista de pacientes archivados (borrado lógico) del cuidador, en tiempo
/// real. Solo los documentos con `archivado == true`.
final archivedPatientsListProvider = StreamProvider.autoDispose<List<Paciente>>(
  (ref) {
    return ref
        .watch(servicioBaseDatosProvider)
        .pacientesArchivadosEnTiempoReal();
  },
);

/// ID del paciente seleccionado, persistido entre sesiones con
/// SharedPreferences (key 'selected_patient_id'). Arranca en null y se
/// restaura de forma asíncrona desde el prefs.
class SelectedPatientNotifier extends Notifier<String?> {
  @override
  String? build() {
    _cargarDelPrefs();
    return null;
  }

  Future<void> _cargarDelPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final guardado = prefs.getString(_clavePacienteSeleccionado);
      if (guardado != null) state = guardado;
    } catch (_) {
      // Sin almacenamiento disponible (tests, entorno restringido): se queda null.
    }
  }

  Future<void> select(String? idPaciente) async {
    state = idPaciente;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (idPaciente == null) {
        await prefs.remove(_clavePacienteSeleccionado);
      } else {
        await prefs.setString(_clavePacienteSeleccionado, idPaciente);
      }
    } catch (_) {
      // El estado en memoria ya quedó actualizado; la persistencia es best-effort.
    }
  }
}

final selectedPatientIdProvider =
    NotifierProvider<SelectedPatientNotifier, String?>(
      SelectedPatientNotifier.new,
    );

/// Paciente activo: si no hay pacientes emite null; si la selección guardada
/// sigue existiendo emite ese; si no, el primero de la lista.
final currentPatientProvider = StreamProvider.autoDispose<Paciente?>((
  ref,
) async* {
  final pacientesAsync = ref.watch(patientsListProvider);
  if (pacientesAsync is AsyncLoading) return;
  final pacientes = pacientesAsync.value ?? const <Paciente>[];
  if (pacientes.isEmpty) {
    yield null;
    return;
  }
  final seleccionadoId = ref.watch(selectedPatientIdProvider);
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
