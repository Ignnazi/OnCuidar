import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/conteo_registros.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';

final _hoy = DateTime(2026, 10, 26, 9);

RegistroClinico _registro(
  String id,
  String tipo, {
  int hora = 9,
  int dia = 26,
}) {
  final fecha = DateTime(2026, 10, dia, hora);
  return RegistroClinico(
    id: id,
    pacienteId: 'p1',
    fecha: fecha,
    creadoEn: fecha,
    tipoRegistro: tipo,
  );
}

void main() {
  group('tipo de registro al guardar', () {
    test('bajo el tope diario se guarda como programado', () {
      expect(tipoEfectivoRegistro('programado', 2, 3), 'programado');
    });

    test('al llegar al tope diario se guarda como extra', () {
      expect(tipoEfectivoRegistro('programado', 3, 3), 'extra');
    });

    test('un registro extra sigue siendo extra', () {
      expect(tipoEfectivoRegistro('extra', 0, 3), 'extra');
    });
  });

  group('conteo del día', () {
    final registros = [
      _registro('a', 'programado', hora: 8),
      _registro('b', 'programado', hora: 12),
      _registro('c', 'extra', hora: 14),
      _registro('d', 'programado', dia: 25),
    ];

    test('cuenta solo los programados de ese día', () {
      expect(contarProgramadosDelDia(registros, _hoy), 2);
    });

    test('cuenta los extra de ese día', () {
      expect(contarExtrasDelDia(registros, _hoy), 1);
    });

    test('numera los programados según la hora en que se crearon', () {
      expect(
        etiquetaNumeroRegistro(registros[0], registros, 3),
        'Registro 1/3',
      );
      expect(
        etiquetaNumeroRegistro(registros[1], registros, 3),
        'Registro 2/3',
      );
      expect(
        etiquetaNumeroRegistro(registros[2], registros, 3),
        'Registro extra',
      );
    });

    test('un programado que pasa el tope se muestra como extra', () {
      expect(
        etiquetaNumeroRegistro(registros[1], registros, 1),
        'Registro extra',
      );
    });
  });
}
