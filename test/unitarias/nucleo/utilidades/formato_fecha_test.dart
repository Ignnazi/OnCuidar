import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/nucleo/utilidades/formato_fecha.dart';

void main() {
  group('mismoDia', () {
    test('ignora la hora', () {
      expect(
        mismoDia(DateTime(2026, 11, 2, 0, 5), DateTime(2026, 11, 2, 23, 59)),
        isTrue,
      );
    });

    test('distingue días, meses y años', () {
      final base = DateTime(2026, 11, 2);
      expect(mismoDia(base, DateTime(2026, 11, 3)), isFalse);
      expect(mismoDia(base, DateTime(2026, 10, 2)), isFalse);
      expect(mismoDia(base, DateTime(2025, 11, 2)), isFalse);
    });
  });

  group('formatos de fecha', () {
    final fecha = DateTime(2026, 11, 2);

    test('fechalarga incluye el día de la semana', () {
      expect(fechalarga(fecha), 'Lunes 02/11/2026');
      expect(fechalarga(DateTime(2026, 11, 1)), 'Domingo 01/11/2026');
    });

    test('fechacorta usa guiones y ceros a la izquierda', () {
      expect(fechacorta(fecha), '02-11-2026');
    });

    test('fechaEntrada usa barras', () {
      expect(fechaEntrada(fecha), '02/11/2026');
    });
  });

  group('hora12', () {
    test('medianoche es 12 AM', () {
      expect(hora12(DateTime(2026, 11, 2, 0, 5)), '12:05 AM');
    });

    test('mediodía es 12 PM', () {
      expect(hora12(DateTime(2026, 11, 2, 12, 0)), '12:00 PM');
    });

    test('la tarde pasa a formato de 12 horas', () {
      expect(hora12(DateTime(2026, 11, 2, 15, 30)), '3:30 PM');
    });

    test('la mañana conserva la hora', () {
      expect(hora12(DateTime(2026, 11, 2, 9, 7)), '9:07 AM');
    });
  });

  group('etiquetaDia', () {
    final ahora = DateTime(2026, 11, 2, 10);

    test('el mismo día es Hoy', () {
      expect(etiquetaDia(DateTime(2026, 11, 2, 23), ahora), 'Hoy');
    });

    test('el día anterior es Ayer', () {
      expect(etiquetaDia(DateTime(2026, 11, 1, 23), ahora), 'Ayer');
    });

    test('un día más antiguo usa la fecha larga', () {
      expect(etiquetaDia(DateTime(2026, 10, 30), ahora), 'Viernes 30/10/2026');
    });
  });

  group('parsearFechaEntrada', () {
    test('lee una fecha válida', () {
      expect(parsearFechaEntrada('02/11/2026'), DateTime(2026, 11, 2));
      expect(parsearFechaEntrada(' 5/3/2024 '), DateTime(2024, 3, 5));
    });

    test('rechaza días que no existen en ese mes', () {
      expect(parsearFechaEntrada('31/02/2026'), isNull);
      expect(parsearFechaEntrada('29/02/2025'), isNull);
    });

    test('acepta el 29 de febrero en año bisiesto', () {
      expect(parsearFechaEntrada('29/02/2024'), DateTime(2024, 2, 29));
    });

    test('rechaza formatos incompletos o con letras', () {
      expect(parsearFechaEntrada('1/2'), isNull);
      expect(parsearFechaEntrada('a/b/c'), isNull);
      expect(parsearFechaEntrada(''), isNull);
    });

    test('rechaza meses fuera de rango y años anteriores a 1900', () {
      expect(parsearFechaEntrada('10/13/2026'), isNull);
      expect(parsearFechaEntrada('01/01/1899'), isNull);
    });
  });
}
