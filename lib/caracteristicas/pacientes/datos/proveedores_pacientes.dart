import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oncuidar/caracteristicas/pacientes/datos/repositorio_pacientes.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/ciclo_de_vida_paciente.dart';
import 'package:oncuidar/caracteristicas/recordatorios/datos/proveedores_recordatorios.dart';
import 'package:oncuidar/nucleo/proveedores.dart';

final repositorioPacientesProvider = Provider<RepositorioPacientes>((ref) {
  return RepositorioPacientes(ref.watch(baseDatosSeguraProvider));
});

final cicloDeVidaPacienteProvider = Provider<CicloDeVidaPaciente>((ref) {
  return CicloDeVidaPaciente(
    pacientes: ref.watch(repositorioPacientesProvider),
    recordatorios: ref.watch(repositorioRecordatoriosProvider),
    notificaciones: ref.watch(servicioNotificacionesProvider),
  );
});
