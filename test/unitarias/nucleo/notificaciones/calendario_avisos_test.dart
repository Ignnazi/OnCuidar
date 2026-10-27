import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/nucleo/notificaciones/calendario_avisos.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  late tz.Location zona;

  setUpAll(() {
    tz.initializeTimeZones();
    zona = tz.getLocation('America/Santiago');
  });

  tz.TZDateTime miercolesALas10() => tz.TZDateTime(zona, 2026, 10, 7, 10);

  group('Repetición semanal', () {
    test('el mismo día, a una hora que aún no pasa, avisa hoy', () {
      final momento = proximaCoincidenciaSemanal(
        miercolesALas10(),
        DateTime(2026, 1, 1, 18, 30),
        ['mie'],
      );
      expect(momento, tz.TZDateTime(zona, 2026, 10, 7, 18, 30));
    });

    test('el mismo día, a una hora que ya pasó, avisa la próxima semana', () {
      final momento = proximaCoincidenciaSemanal(
        miercolesALas10(),
        DateTime(2026, 1, 1, 8),
        ['mie'],
      );
      expect(momento, tz.TZDateTime(zona, 2026, 10, 14, 8));
    });

    test('elige el día de la lista más cercano', () {
      final momento = proximaCoincidenciaSemanal(
        miercolesALas10(),
        DateTime(2026, 1, 1, 9),
        ['lun', 'vie'],
      );
      expect(momento.weekday, DateTime.friday);
      expect(momento, tz.TZDateTime(zona, 2026, 10, 9, 9));
    });

    test('un recordatorio creado hace meses no queda en el pasado', () {
      final momento = proximaCoincidenciaSemanal(
        miercolesALas10(),
        DateTime(2025, 3, 3, 12),
        ['jue'],
      );
      expect(momento.isAfter(miercolesALas10()), isTrue);
      expect(momento, tz.TZDateTime(zona, 2026, 10, 8, 12));
    });
  });

  test('el cambio de horario no corre la hora del aviso semanal', () {
    final momento = proximaCoincidenciaSemanal(
      tz.TZDateTime(zona, 2026, 4, 3, 10),
      DateTime(2026, 1, 1, 8),
      ['lun'],
    );
    expect(momento, tz.TZDateTime(zona, 2026, 4, 6, 8));
  });

  group('Repetición mensual', () {
    test('si el día de este mes aún no llega, avisa este mes', () {
      final momento = proximaMensual(
        miercolesALas10(),
        DateTime(2026, 1, 20, 9),
      );
      expect(momento, tz.TZDateTime(zona, 2026, 10, 20, 9));
    });

    test('si el día de este mes ya pasó, avisa el mes siguiente', () {
      final momento = proximaMensual(miercolesALas10(), DateTime(2026, 1, 5));
      expect(momento, tz.TZDateTime(zona, 2026, 11, 5));
    });

    test('el día 31 se ajusta al último día de un mes más corto', () {
      final momento = proximaMensual(
        tz.TZDateTime(zona, 2026, 11, 2, 10),
        DateTime(2026, 1, 31, 8),
      );
      expect(momento, tz.TZDateTime(zona, 2026, 11, 30, 8));
    });

    test('el día 31 avisa el último día de cada mes sin quedar fijo', () {
      final momentos = proximasMensuales(
        tz.TZDateTime(zona, 2026, 1, 31, 10),
        DateTime(2026, 1, 31, 8),
        3,
      );
      expect(momentos, [
        tz.TZDateTime(zona, 2026, 2, 28, 8),
        tz.TZDateTime(zona, 2026, 3, 31, 8),
        tz.TZDateTime(zona, 2026, 4, 30, 8),
      ]);
    });

    test('en diciembre pasa al año siguiente', () {
      final momento = proximaMensual(
        tz.TZDateTime(zona, 2026, 12, 20, 10),
        DateTime(2026, 1, 3, 8),
      );
      expect(momento, tz.TZDateTime(zona, 2027, 1, 3, 8));
    });
  });

  group('Una sola vez', () {
    test('una fecha futura se respeta tal cual', () {
      final momento = momentoUnaVez(
        miercolesALas10(),
        DateTime(2026, 10, 9, 15),
      );
      expect(momento, tz.TZDateTime(zona, 2026, 10, 9, 15));
    });

    test('una hora que ya pasó no se programa', () {
      final momento = momentoUnaVez(
        miercolesALas10(),
        DateTime(2026, 10, 7, 9),
      );
      expect(momento, isNull);
    });
  });
}
