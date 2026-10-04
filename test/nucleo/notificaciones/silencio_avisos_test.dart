import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/nucleo/notificaciones/silencio_avisos.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('sin nada guardado no hay silencio', () async {
    expect(await SilencioAvisos.global(), isFalse);
    expect(await SilencioAvisos.pacientes(), isEmpty);
    expect(await SilencioAvisos.silenciado(idPaciente: 'p1'), isFalse);
  });

  test(
    'el silencio de un paciente no afecta a los demás ni al general',
    () async {
      await SilencioAvisos.fijarPaciente('p1', true);

      expect(await SilencioAvisos.silenciado(idPaciente: 'p1'), isTrue);
      expect(await SilencioAvisos.silenciado(idPaciente: 'p2'), isFalse);
      expect(await SilencioAvisos.silenciado(), isFalse);
      expect(await SilencioAvisos.global(), isFalse);
    },
  );

  test('el silencio general calla a todos los pacientes', () async {
    await SilencioAvisos.fijarGlobal(true);

    expect(await SilencioAvisos.silenciado(idPaciente: 'p1'), isTrue);
    expect(await SilencioAvisos.silenciado(), isTrue);
  });

  test('quitar el general no borra el silencio de cada paciente', () async {
    await SilencioAvisos.fijarPaciente('p1', true);
    await SilencioAvisos.fijarGlobal(true);
    await SilencioAvisos.fijarGlobal(false);

    expect(await SilencioAvisos.silenciado(idPaciente: 'p1'), isTrue);
    expect(await SilencioAvisos.silenciado(idPaciente: 'p2'), isFalse);
  });

  test(
    'silenciar dos veces o reactivar a quien no estaba no duplica ni falla',
    () async {
      await SilencioAvisos.fijarPaciente('p1', true);
      await SilencioAvisos.fijarPaciente('p1', true);
      await SilencioAvisos.fijarPaciente('p9', false);

      expect(await SilencioAvisos.pacientes(), {'p1'});

      await SilencioAvisos.fijarPaciente('p1', false);
      expect(await SilencioAvisos.pacientes(), isEmpty);
    },
  );
}
