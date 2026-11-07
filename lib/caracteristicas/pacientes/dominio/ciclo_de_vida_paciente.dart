import 'dart:async';

import 'package:oncuidar/caracteristicas/pacientes/datos/repositorio_pacientes.dart';
import 'package:oncuidar/caracteristicas/recordatorios/datos/repositorio_recordatorios.dart';
import 'package:oncuidar/caracteristicas/recordatorios/dominio/recordatorio.dart';
import 'package:oncuidar/nucleo/notificaciones/servicio_notificaciones.dart';
import 'package:oncuidar/nucleo/notificaciones/silencio_avisos.dart';

class CicloDeVidaPaciente {
  CicloDeVidaPaciente({
    required this.pacientes,
    required this.recordatorios,
    required this.notificaciones,
  });

  final RepositorioPacientes pacientes;
  final RepositorioRecordatorios recordatorios;
  final ServicioNotificaciones notificaciones;

  /// Archiva al paciente y apaga sus avisos locales.
  Future<void> archivar(String idPaciente) async {
    await pacientes.archivarPaciente(idPaciente);
    await recordatorios.cancelarNotificacionesPaciente(
      idPaciente,
      notificaciones,
    );
  }

  Future<void> desarchivar(String idPaciente) async {
    await pacientes.desarchivarPaciente(idPaciente);
    await reagendarNotificaciones();
  }

  /// Elimina al paciente y sus datos.
  Future<void> eliminar(String idPaciente) async {
    await recordatorios.cancelarNotificacionesPaciente(
      idPaciente,
      notificaciones,
    );
    await pacientes.eliminarPaciente(idPaciente);
    await SilencioAvisos.fijarPaciente(idPaciente, false);
  }

  Future<void> reagendarNotificaciones() async {
    try {
      if (!pacientes.bd.tieneIdentidad()) return;
      final activos = await pacientes.pacientesEnTiempoReal().first;
      final porPaciente = [
        for (final paciente in activos)
          (
            paciente,
            await recordatorios.recordatoriosEnTiempoReal(paciente.id).first,
          ),
      ];
      await notificaciones.cancelarTodas();
      final ahora = DateTime.now();
      var permisoPedido = false;
      for (final (paciente, delPaciente) in porPaciente) {
        for (final r in delPaciente) {
          if (!r.activo) continue;
          if (r.titulo.isEmpty) continue;
          if (!r.esRecurrente && r.fechaHora.isBefore(ahora)) continue;
          try {
            if (!permisoPedido) {
              permisoPedido = true;
              await notificaciones.solicitarPermisoAvisos();
            }
            await notificaciones.programar(
              id: ServicioNotificaciones.idSeguro(r.id),
              titulo: r.tituloAviso(
                paciente.nombreCompleto,
                etiquetaTipoRecordatorio(r.tipo),
              ),
              cuerpo: r.cuerpoAviso,
              fechaHora: r.fechaHora,
              diasRepeticion: r.diasRepeticion,
              mensual: r.esMensual,
              idPaciente: paciente.id,
            );
          } catch (_) {
            // Si falla uno, se siguen programando los demás.
          }
        }
      }
    } catch (_) {
      // Si falla una lectura, los avisos quedan como estaban.
    }
  }
}

void reagendarAvisosEnSegundoPlano(CicloDeVidaPaciente cicloDeVida) {
  unawaited(
    cicloDeVida
        .reagendarNotificaciones()
        .timeout(const Duration(seconds: 20), onTimeout: () {})
        .catchError((_) {}),
  );
}
