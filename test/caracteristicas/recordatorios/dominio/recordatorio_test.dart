import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/pacientes/datos/repositorio_pacientes.dart';
import 'package:oncuidar/caracteristicas/recordatorios/datos/repositorio_recordatorios.dart';
import 'package:oncuidar/caracteristicas/recordatorios/dominio/recordatorio.dart';
import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';
import 'package:oncuidar/nucleo/notificaciones/servicio_notificaciones.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../ayudas/ciclo_de_vida.dart';
import '../../../ayudas/recordatorios.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Modelo Recordatorio', () {
    test('sin asignación guardada va dirigido al paciente', () {
      final r = Recordatorio.fromMap('x', {'titulo': 'Antiguo'});
      expect(r.asignadoA, Recordatorio.asignadoAPaciente);
      expect(r.esParaCuidador, isFalse);
    });

    test('el título del aviso nombra al cuidador o al paciente', () {
      final paraPaciente = recordatorioDe('p');
      final paraCuidador = recordatorioDe(
        'p',
        asignadoA: Recordatorio.asignadoACuidador,
      );
      expect(paraPaciente.tituloAviso('Rosa', 'Cita'), 'Rosa · Cita');
      expect(paraCuidador.tituloAviso('Rosa', 'Cita'), 'Cuidador · Cita');
    });

    test('el cuerpo del aviso incluye la descripción', () {
      expect(
        recordatorioDe('p', titulo: 'Jarabe', descripcion: '5 ml').cuerpoAviso,
        'Jarabe · 5 ml',
      );
      expect(recordatorioDe('p', titulo: 'Jarabe').cuerpoAviso, 'Jarabe');
    });
  });

  group('RepositorioRecordatorios — asignación', () {
    test('la asignación viaja dentro del payload cifrado', () async {
      final (base, firestore) = await baseRecordatorios();
      final idPaciente = await crearPacienteRecordatorios(base);
      final id = await RepositorioRecordatorios(base).agregarRecordatorio(
        idPaciente,
        recordatorioDe(idPaciente, asignadoA: Recordatorio.asignadoACuidador),
      );
      final doc = await firestore
          .collection('usuarios')
          .doc(uidRecordatorios)
          .collection('pacientes')
          .doc(idPaciente)
          .collection('recordatorios')
          .doc(id)
          .get();
      final datos = doc.data()!;
      expect(datos.containsKey('asignadoA'), isFalse);
      expect(datos['pacienteId'], idPaciente);
      final cifrado = ServicioCifrado(clavePrueba: clavePruebaRecordatorios);
      await cifrado.fijarClave(uidRecordatorios, clavePruebaRecordatorios);
      final payload =
          jsonDecode(
                await cifrado.descifrar(
                  uidRecordatorios,
                  datos['datos_cifrados'] as String,
                ),
              )
              as Map<String, dynamic>;
      expect(payload['asignadoA'], 'cuidador');

      final leidos = await RepositorioRecordatorios(
        base,
      ).recordatoriosEnTiempoReal(idPaciente).first;
      expect(leidos.single.asignadoA, Recordatorio.asignadoACuidador);
    });

    test('actualizar la asignación conserva el resto del payload', () async {
      final (base, _) = await baseRecordatorios();
      final idPaciente = await crearPacienteRecordatorios(base);
      final fecha = DateTime.now().add(const Duration(days: 3));
      final id = await RepositorioRecordatorios(base).agregarRecordatorio(
        idPaciente,
        recordatorioDe(idPaciente, fechaHora: fecha, dias: const ['lun']),
      );
      await RepositorioRecordatorios(base).actualizarRecordatorio(
        idPaciente,
        id,
        asignadoA: Recordatorio.asignadoACuidador,
      );
      final r = (await RepositorioRecordatorios(
        base,
      ).recordatoriosEnTiempoReal(idPaciente).first).single;
      expect(r.asignadoA, 'cuidador');
      expect(r.diasRepeticion, ['lun']);
      expect(r.tipo, 'medicamento');
    });
  });

  group('reagendarNotificaciones', () {
    test('no reprograma uno de una sola vez que ya venció', () async {
      final (base, _) = await baseRecordatorios();
      final idPaciente = await crearPacienteRecordatorios(base);
      await RepositorioRecordatorios(base).agregarRecordatorio(
        idPaciente,
        recordatorioDe(
          idPaciente,
          titulo: 'Vencido',
          fechaHora: DateTime.now().subtract(const Duration(days: 1)),
        ),
      );
      await RepositorioRecordatorios(base).agregarRecordatorio(
        idPaciente,
        recordatorioDe(idPaciente, titulo: 'Vigente'),
      );
      final notif = NotificacionesFalsas();
      await cicloDeVida(base, notif).reagendarNotificaciones();
      expect(notif.programados.map((p) => p['cuerpo']), ['Vigente']);
    });

    test('el aviso incluye la descripción y nombra al cuidador', () async {
      final (base, _) = await baseRecordatorios();
      final idPaciente = await crearPacienteRecordatorios(base);
      await RepositorioRecordatorios(base).agregarRecordatorio(
        idPaciente,
        recordatorioDe(
          idPaciente,
          titulo: 'Control',
          descripcion: 'Llevar exámenes',
          asignadoA: Recordatorio.asignadoACuidador,
        ),
      );
      final notif = NotificacionesFalsas();
      await cicloDeVida(base, notif).reagendarNotificaciones();
      expect(notif.programados.single['cuerpo'], 'Control · Llevar exámenes');
      expect(notif.programados.single['titulo'], 'Cuidador · Medicamento');
    });
  });

  group('Avisos al archivar, restaurar y eliminar un paciente', () {
    test('archivar cancela los avisos de sus recordatorios', () async {
      final (base, _) = await baseRecordatorios();
      final idPaciente = await crearPacienteRecordatorios(base);
      final id1 = await RepositorioRecordatorios(base).agregarRecordatorio(
        idPaciente,
        recordatorioDe(idPaciente, titulo: 'Uno'),
      );
      final id2 = await RepositorioRecordatorios(base).agregarRecordatorio(
        idPaciente,
        recordatorioDe(idPaciente, titulo: 'Dos'),
      );
      final notif = NotificacionesFalsas();
      await cicloDeVida(base, notif).archivar(idPaciente);
      expect(
        notif.cancelados,
        containsAll([
          ServicioNotificaciones.idSeguro(id1),
          ServicioNotificaciones.idSeguro(id2),
        ]),
      );
    });

    test('archivar no toca los avisos de otro paciente', () async {
      final (base, _) = await baseRecordatorios();
      final a = await crearPacienteRecordatorios(base, nombre: 'Paciente A');
      final b = await crearPacienteRecordatorios(base, nombre: 'Paciente B');
      await RepositorioRecordatorios(
        base,
      ).agregarRecordatorio(a, recordatorioDe(a, titulo: 'De A'));
      final idB = await RepositorioRecordatorios(
        base,
      ).agregarRecordatorio(b, recordatorioDe(b, titulo: 'De B'));
      final notif = NotificacionesFalsas();
      await cicloDeVida(base, notif).archivar(a);
      expect(
        notif.cancelados,
        isNot(contains(ServicioNotificaciones.idSeguro(idB))),
      );
    });

    test('restaurar vuelve a programar los avisos', () async {
      final (base, _) = await baseRecordatorios();
      final idPaciente = await crearPacienteRecordatorios(base);
      await RepositorioRecordatorios(base).agregarRecordatorio(
        idPaciente,
        recordatorioDe(idPaciente, titulo: 'Jarabe'),
      );
      await RepositorioPacientes(base).archivarPaciente(idPaciente);
      final notif = NotificacionesFalsas();
      await cicloDeVida(base, notif).desarchivar(idPaciente);
      expect(notif.programados.map((p) => p['cuerpo']), ['Jarabe']);
    });

    test('un paciente archivado no se reprograma al iniciar sesión', () async {
      final (base, _) = await baseRecordatorios();
      final idPaciente = await crearPacienteRecordatorios(base);
      await RepositorioRecordatorios(base).agregarRecordatorio(
        idPaciente,
        recordatorioDe(idPaciente, titulo: 'Jarabe'),
      );
      await RepositorioPacientes(base).archivarPaciente(idPaciente);
      final notif = NotificacionesFalsas();
      await cicloDeVida(base, notif).reagendarNotificaciones();
      expect(notif.programados, isEmpty);
    });

    test('eliminar cancela los avisos antes de borrar al paciente', () async {
      final (base, _) = await baseRecordatorios();
      final idPaciente = await crearPacienteRecordatorios(base);
      final id = await RepositorioRecordatorios(
        base,
      ).agregarRecordatorio(idPaciente, recordatorioDe(idPaciente));
      final notif = NotificacionesFalsas();
      await cicloDeVida(base, notif).eliminar(idPaciente);
      expect(notif.cancelados, contains(ServicioNotificaciones.idSeguro(id)));
      expect(
        await RepositorioPacientes(base).pacientesEnTiempoReal().first,
        isEmpty,
      );
    });
  });
}
