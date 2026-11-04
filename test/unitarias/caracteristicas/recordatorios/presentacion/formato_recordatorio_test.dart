import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/recordatorios/dominio/recordatorio.dart';
import 'package:oncuidar/caracteristicas/recordatorios/presentacion/formato_recordatorio.dart';

Recordatorio _recordatorio({
  required DateTime fechaHora,
  List<String> dias = const [],
  String? recurrencia,
}) => Recordatorio(
  id: 'c1',
  pacienteId: 'p1',
  tipo: 'medicamento',
  titulo: 'Ondansetrón',
  fechaHora: fechaHora,
  diasRepeticion: dias,
  recurrencia: recurrencia,
  creadoEn: DateTime(2026, 10, 20),
);

void main() {
  group('proximoAviso', () {
    test('una sola vez devuelve la fecha si aún no pasó', () {
      final r = _recordatorio(fechaHora: DateTime(2026, 10, 26, 8));
      expect(
        proximoAviso(r, DateTime(2026, 10, 26, 7)),
        DateTime(2026, 10, 26, 8),
      );
    });

    test('una sola vez devuelve null cuando ya pasó', () {
      final r = _recordatorio(fechaHora: DateTime(2026, 10, 26, 8));
      expect(proximoAviso(r, DateTime(2026, 10, 26, 9)), isNull);
    });

    test('semanal busca el próximo día elegido', () {
      final r = _recordatorio(
        fechaHora: DateTime(2026, 10, 26, 8),
        dias: const ['jue'],
      );
      expect(
        proximoAviso(r, DateTime(2026, 10, 28, 10)),
        DateTime(2026, 10, 29, 8),
      );
    });

    test('mensual avanza al mes siguiente conservando el día', () {
      final r = _recordatorio(
        fechaHora: DateTime(2026, 10, 26, 8),
        recurrencia: 'mensual',
      );
      expect(
        proximoAviso(r, DateTime(2026, 10, 26, 10)),
        DateTime(2026, 11, 26, 8),
      );
    });

    test('mensual ajusta el día al último del mes corto', () {
      final r = _recordatorio(
        fechaHora: DateTime(2026, 1, 31, 8),
        recurrencia: 'mensual',
      );
      expect(
        proximoAviso(r, DateTime(2026, 2, 1, 0)),
        DateTime(2026, 2, 28, 8),
      );
    });
  });

  group('textoProximoAviso', () {
    final ahora = DateTime(2026, 10, 26, 10);

    test('horas y minutos', () {
      expect(
        textoProximoAviso(
          ahora.add(const Duration(hours: 2, minutes: 15)),
          ahora,
        ),
        'en 2 h y 15 min',
      );
    });

    test('solo horas', () {
      expect(
        textoProximoAviso(ahora.add(const Duration(hours: 3)), ahora),
        'en 3 h',
      );
    });

    test('una hora en singular', () {
      expect(
        textoProximoAviso(
          ahora.add(const Duration(hours: 1, minutes: 5)),
          ahora,
        ),
        'en 1 h y 5 min',
      );
    });

    test('solo minutos', () {
      expect(
        textoProximoAviso(ahora.add(const Duration(minutes: 45)), ahora),
        'en 45 min',
      );
    });

    test('menos de un minuto', () {
      expect(
        textoProximoAviso(ahora.add(const Duration(seconds: 30)), ahora),
        'en menos de 1 min',
      );
    });

    test('días, horas y minutos', () {
      expect(
        textoProximoAviso(
          ahora.add(const Duration(days: 1, hours: 2, minutes: 30)),
          ahora,
        ),
        'en 1 d, 2 h y 30 min',
      );
    });
  });
}
