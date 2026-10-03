import 'package:oncuidar/caracteristicas/pacientes/datos/repositorio_pacientes.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/ciclo_de_vida_paciente.dart';
import 'package:oncuidar/caracteristicas/recordatorios/datos/repositorio_recordatorios.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
import 'package:oncuidar/nucleo/notificaciones/servicio_notificaciones.dart';

CicloDeVidaPaciente cicloDeVida(
  BaseDatosSegura bd,
  ServicioNotificaciones notificaciones,
) {
  return CicloDeVidaPaciente(
    pacientes: RepositorioPacientes(bd),
    recordatorios: RepositorioRecordatorios(bd),
    notificaciones: notificaciones,
  );
}
