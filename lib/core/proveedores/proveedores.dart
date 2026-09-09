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

final patientsListProvider = StreamProvider.autoDispose<List<Paciente>>((ref) {
  return ref.watch(servicioBaseDatosProvider).pacientesEnTiempoReal();
});

final archivedPatientsListProvider = StreamProvider.autoDispose<List<Paciente>>(
  (ref) {
    return ref
        .watch(servicioBaseDatosProvider)
        .pacientesArchivadosEnTiempoReal();
  },
);

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
      // Si falla, se sigue igual.
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
      // Si falla, se sigue igual.
    }
  }
}

final selectedPatientIdProvider =
    NotifierProvider<SelectedPatientNotifier, String?>(
      SelectedPatientNotifier.new,
    );

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
