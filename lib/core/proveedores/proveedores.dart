import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

final bloqueoCifradoProvider =
    NotifierProvider<BloqueoCifradoNotifier, bool>(BloqueoCifradoNotifier.new);

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