import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oncuidar/caracteristicas/pacientes/datos/proveedores_pacientes.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/ciclo_de_vida_paciente.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/paciente.dart';
import 'package:oncuidar/caracteristicas/recordatorios/datos/proveedores_recordatorios.dart';
import 'package:oncuidar/caracteristicas/recordatorios/datos/repositorio_recordatorios.dart';
import 'package:oncuidar/caracteristicas/recordatorios/dominio/recordatorio.dart';
import 'package:oncuidar/nucleo/notificaciones/servicio_notificaciones.dart';
import 'package:oncuidar/nucleo/proveedores.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _claveSilencio = 'notificaciones_silenciadas';

class DatosRecordatorio {
  const DatosRecordatorio({
    required this.tipo,
    required this.titulo,
    required this.descripcion,
    required this.fecha,
    required this.hora,
    required this.modoRepeticion,
    required this.dias,
    required this.asignadoA,
  });

  final String tipo;
  final String titulo;

  final String descripcion;
  final DateTime fecha;
  final TimeOfDay hora;

  /// 'unavez', 'semanal' o 'mensual'.
  final String modoRepeticion;
  final List<String> dias;
  final String asignadoA;

  bool get mensual => modoRepeticion == 'mensual';

  DateTime get fechaHora =>
      DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute);

  /// Solo la repetición semanal guarda días.
  List<String> get diasGuardar => mensual || modoRepeticion == 'unavez'
      ? const <String>[]
      : List<String>.from(dias);

  String? get descripcionOpcional => descripcion.isEmpty ? null : descripcion;
}

class ControladorRecordatorios {
  ControladorRecordatorios({
    required this.repositorio,
    required this.notificaciones,
    required this.cicloDeVida,
  });

  final RepositorioRecordatorios repositorio;
  final ServicioNotificaciones notificaciones;
  final CicloDeVidaPaciente cicloDeVida;

  Future<void> programarAviso(String nombrePaciente, Recordatorio r) {
    return notificaciones.programar(
      id: ServicioNotificaciones.idSeguro(r.id),
      titulo: r.tituloAviso(nombrePaciente, etiquetaTipoRecordatorio(r.tipo)),
      cuerpo: r.cuerpoAviso,
      fechaHora: r.fechaHora,
      diasRepeticion: r.diasRepeticion,
      mensual: r.esMensual,
    );
  }

  Future<void> alternarActivo(Paciente paciente, Recordatorio r) async {
    final nuevoActivo = !r.activo;
    await repositorio.actualizarRecordatorio(
      paciente.id,
      r.id,
      activo: nuevoActivo,
    );
    if (nuevoActivo) {
      await notificaciones.solicitarPermiso();
      await programarAviso(paciente.nombreCompleto, r);
    } else {
      await notificaciones.cancelar(ServicioNotificaciones.idSeguro(r.id));
    }
  }

  Future<void> eliminar(String idPaciente, String idRecordatorio) async {
    await repositorio.eliminarRecordatorio(idPaciente, idRecordatorio);
    await notificaciones.cancelar(
      ServicioNotificaciones.idSeguro(idRecordatorio),
    );
  }

  Future<void> guardar(
    Paciente paciente,
    DatosRecordatorio datos, {
    Recordatorio? existente,
  }) async {
    if (existente == null) {
      final r = Recordatorio(
        id: '',
        pacienteId: paciente.id,
        tipo: datos.tipo,
        titulo: datos.titulo,
        descripcion: datos.descripcionOpcional,
        fechaHora: datos.fechaHora,
        diasRepeticion: datos.diasGuardar,
        recurrencia: datos.mensual ? 'mensual' : null,
        asignadoA: datos.asignadoA,
        activo: true,
        creadoEn: DateTime.now(),
      );
      final docId = await repositorio.agregarRecordatorio(paciente.id, r);
      await notificaciones.solicitarPermiso();
      await programarAviso(
        paciente.nombreCompleto,
        Recordatorio(
          id: docId,
          pacienteId: r.pacienteId,
          tipo: r.tipo,
          titulo: r.titulo,
          descripcion: r.descripcion,
          fechaHora: r.fechaHora,
          diasRepeticion: r.diasRepeticion,
          recurrencia: r.recurrencia,
          asignadoA: r.asignadoA,
          creadoEn: r.creadoEn,
        ),
      );
      return;
    }
    await repositorio.actualizarRecordatorio(
      paciente.id,
      existente.id,
      tipo: datos.tipo,
      titulo: datos.titulo,
      descripcion: datos.descripcion,
      fechaHora: datos.fechaHora,
      diasRepeticion: datos.diasGuardar,
      recurrencia: datos.mensual ? 'mensual' : '',
      asignadoA: datos.asignadoA,
    );
    final actualizado = Recordatorio(
      id: existente.id,
      pacienteId: paciente.id,
      tipo: datos.tipo,
      titulo: datos.titulo,
      descripcion: datos.descripcionOpcional,
      fechaHora: datos.fechaHora,
      diasRepeticion: datos.diasGuardar,
      recurrencia: datos.mensual ? 'mensual' : null,
      asignadoA: datos.asignadoA,
      creadoEn: existente.creadoEn,
    );
    await notificaciones.cancelar(
      ServicioNotificaciones.idSeguro(existente.id),
    );
    if (existente.activo) {
      await programarAviso(paciente.nombreCompleto, actualizado);
    }
  }

  static Future<bool> silencioGuardado() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_claveSilencio) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> fijarSilencio(bool silenciar) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_claveSilencio, silenciar);
    } catch (_) {
      // Si falla, se sigue igual.
    }
    if (silenciar) {
      await notificaciones.cancelarTodas();
    } else {
      await cicloDeVida.reagendarNotificaciones();
    }
  }
}

final controladorRecordatoriosProvider = Provider<ControladorRecordatorios>((
  ref,
) {
  return ControladorRecordatorios(
    repositorio: ref.watch(repositorioRecordatoriosProvider),
    notificaciones: ref.watch(servicioNotificacionesProvider),
    cicloDeVida: ref.watch(cicloDeVidaPacienteProvider),
  );
});
