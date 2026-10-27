import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/historial/dominio/filtro_historial.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';

RegistroClinico _registro(DateTime fecha, NivelAlerta nivel) => RegistroClinico(
  id: 'r1',
  pacienteId: 'p1',
  fecha: fecha,
  creadoEn: fecha,
  tipoRegistro: 'programado',
  nivelAlerta: nivel,
);

void main() {
  final lunes = DateTime(2026, 10, 19, 10);
  final miercoles = DateTime(2026, 10, 21, 23, 30);
  final viernes = DateTime(2026, 10, 23, 8);

  test('sin filtros admite todos los registros', () {
    const filtro = FiltroHistorial();
    expect(filtro.hayFiltros, isFalse);
    expect(filtro.admite(_registro(lunes, NivelAlerta.critico)), isTrue);
  });

  test('filtra por nivel de alerta', () {
    final filtro = const FiltroHistorial().conEstado('alerta');
    expect(filtro.admite(_registro(lunes, NivelAlerta.alerta)), isTrue);
    expect(filtro.admite(_registro(lunes, NivelAlerta.normal)), isFalse);
  });

  test('con solo fecha de inicio muestra ese día completo', () {
    final filtro = const FiltroHistorial().conRango(
      DateTime(2026, 10, 21),
      null,
    );
    expect(filtro.coincideFecha(miercoles), isTrue);
    expect(filtro.coincideFecha(lunes), isFalse);
    expect(filtro.coincideFecha(viernes), isFalse);
  });

  test('con solo fecha de fin incluye todo hasta el final de ese día', () {
    final filtro = const FiltroHistorial().conRango(
      null,
      DateTime(2026, 10, 21),
    );
    expect(filtro.coincideFecha(lunes), isTrue);
    expect(filtro.coincideFecha(miercoles), isTrue);
    expect(filtro.coincideFecha(viernes), isFalse);
  });

  test('un rango incluye los dos días de los extremos', () {
    final filtro = const FiltroHistorial().conRango(
      DateTime(2026, 10, 19),
      DateTime(2026, 10, 21),
    );
    expect(filtro.coincideFecha(lunes), isTrue);
    expect(filtro.coincideFecha(miercoles), isTrue);
    expect(filtro.coincideFecha(viernes), isFalse);
  });

  test('nivel y fecha se combinan', () {
    final filtro = const FiltroHistorial()
        .conEstado('critico')
        .conRango(DateTime(2026, 10, 19), DateTime(2026, 10, 21));
    expect(filtro.admite(_registro(lunes, NivelAlerta.critico)), isTrue);
    expect(filtro.admite(_registro(lunes, NivelAlerta.normal)), isFalse);
    expect(filtro.admite(_registro(viernes, NivelAlerta.critico)), isFalse);
  });

  test('los límites para consultar al servidor cubren días completos', () {
    final (desde, hasta) = const FiltroHistorial()
        .conRango(DateTime(2026, 10, 19, 15), DateTime(2026, 10, 21, 9))
        .limites();
    expect(desde, DateTime(2026, 10, 19));
    expect(hasta, DateTime(2026, 10, 22));
  });
}
