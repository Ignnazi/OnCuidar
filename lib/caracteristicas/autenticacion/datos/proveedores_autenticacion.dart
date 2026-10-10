import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oncuidar/caracteristicas/autenticacion/datos/servicio_alta_cuenta.dart';
import 'package:oncuidar/caracteristicas/pacientes/datos/proveedores_pacientes.dart';
import 'package:oncuidar/caracteristicas/perfil/datos/proveedores_perfil.dart';
import 'package:oncuidar/nucleo/proveedores.dart';

final servicioRegistroProvider = Provider<ServicioRegistro>((ref) {
  return ServicioRegistro(
    sesion: ref.watch(servicioSesionProvider),
    api: ref.watch(clienteApiProvider),
    cifrado: ref.watch(servicioCifradoProvider),
    repositorioPacientes: ref.watch(repositorioPacientesProvider),
    repositorioCuidador: ref.watch(repositorioCuidadorProvider),
    alDesbloquear: () =>
        ref.read(bloqueoCifradoProvider.notifier).fijarDesbloqueado(true),
  );
});
