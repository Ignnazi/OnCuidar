import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/recordatorios/datos/repositorio_recordatorios.dart';
import 'package:oncuidar/caracteristicas/recordatorios/presentacion/controlador_recordatorios.dart';
import 'package:oncuidar/nucleo/notificaciones/servicio_notificaciones.dart';
import 'package:oncuidar/nucleo/notificaciones/silencio_avisos.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ayudas/ciclo_de_vida.dart';
import '../ayudas/recordatorios.dart';

Future<
  ({
    NotificacionesFalsas notif,
    ControladorRecordatorios controlador,
    String idA,
    String idB,
    int avisoA,
    int avisoB,
    dynamic ciclo,
  })
>
_escenario() async {
  SharedPreferences.setMockInitialValues({});
  final (base, _) = await baseRecordatorios();
  final idA = await crearPacienteRecordatorios(base, nombre: 'Ana');
  final idB = await crearPacienteRecordatorios(base, nombre: 'Beto');
  final repo = RepositorioRecordatorios(base);
  final recA = await repo.agregarRecordatorio(
    idA,
    recordatorioDe(idA, titulo: 'Jarabe de Ana'),
  );
  final recB = await repo.agregarRecordatorio(
    idB,
    recordatorioDe(idB, titulo: 'Jarabe de Beto'),
  );
  final notif = NotificacionesFalsas();
  final ciclo = cicloDeVida(base, notif);
  return (
    notif: notif,
    controlador: ControladorRecordatorios(
      repositorio: repo,
      notificaciones: notif,
      cicloDeVida: ciclo,
    ),
    idA: idA,
    idB: idB,
    avisoA: ServicioNotificaciones.idSeguro(recA),
    avisoB: ServicioNotificaciones.idSeguro(recB),
    ciclo: ciclo,
  );
}

Set<int> _programados(NotificacionesFalsas n) => {
  for (final p in n.programados) p['id'] as int,
};

void main() {
  test('silenciar a un paciente deja sonar al otro', () async {
    final e = await _escenario();

    await e.controlador.fijarSilencioPaciente(e.idA, true);
    await e.ciclo.reagendarNotificaciones();

    expect(_programados(e.notif), {e.avisoB});
    expect(await SilencioAvisos.global(), isFalse);
    expect(await SilencioAvisos.pacientes(), {e.idA});
  });

  test(
    'silenciar a un paciente cancela sus avisos y no todos los del teléfono',
    () async {
      final e = await _escenario();

      await e.controlador.fijarSilencioPaciente(e.idA, true);

      expect(e.notif.cancelados, contains(e.avisoA));
      expect(e.notif.cancelados, isNot(contains(e.avisoB)));
      expect(e.notif.canceladasTodas, 0);
    },
  );

  test('reactivar a un paciente vuelve a programar sus avisos', () async {
    final e = await _escenario();
    await e.controlador.fijarSilencioPaciente(e.idA, true);
    e.notif.programados.clear();

    await e.controlador.fijarSilencioPaciente(e.idA, false);

    expect(_programados(e.notif), {e.avisoA, e.avisoB});
    expect(await SilencioAvisos.pacientes(), isEmpty);
  });

  test(
    'el silencio general calla a todos y al quitarlo respeta a los silenciados',
    () async {
      final e = await _escenario();
      await e.controlador.fijarSilencioPaciente(e.idB, true);
      e.notif.programados.clear();

      await e.controlador.fijarSilencio(true);
      expect(e.notif.canceladasTodas, greaterThan(0));
      await e.ciclo.reagendarNotificaciones();
      expect(_programados(e.notif), isEmpty);

      await e.controlador.fijarSilencio(false);

      expect(_programados(e.notif), {e.avisoA});
      expect(await SilencioAvisos.pacientes(), {e.idB});
    },
  );

  test('eliminar a un paciente borra su silencio guardado', () async {
    final e = await _escenario();
    await e.controlador.fijarSilencioPaciente(e.idA, true);

    await e.ciclo.eliminar(e.idA);

    expect(await SilencioAvisos.pacientes(), isEmpty);
  });
}
