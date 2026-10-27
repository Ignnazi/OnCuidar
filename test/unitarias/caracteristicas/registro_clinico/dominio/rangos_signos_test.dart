import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/rangos_signos.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';

void main() {
  test('signos dentro del rango no dan error', () {
    const signos = SignosVitales(
      temperatura: 37,
      frecuenciaCardiaca: 90,
      saturacionOxigeno: 98,
      frecuenciaRespiratoria: 20,
    );
    expect(errorDeRango(signos), isNull);
  });

  test('sin signos vitales no hay error porque son opcionales', () {
    expect(errorDeRango(const SignosVitales()), isNull);
  });

  test('los bordes de cada rango son válidos', () {
    const minimos = SignosVitales(
      temperatura: 30,
      frecuenciaCardiaca: 20,
      saturacionOxigeno: 50,
      frecuenciaRespiratoria: 4,
    );
    const maximos = SignosVitales(
      temperatura: 45,
      frecuenciaCardiaca: 250,
      saturacionOxigeno: 100,
      frecuenciaRespiratoria: 60,
    );
    expect(errorDeRango(minimos), isNull);
    expect(errorDeRango(maximos), isNull);
  });

  test('un valor imposible muestra el rango válido', () {
    expect(
      errorDeRango(const SignosVitales(temperatura: 50)),
      rangoTemperatura.mensaje,
    );
    expect(
      errorDeRango(const SignosVitales(frecuenciaCardiaca: 300)),
      rangoFrecuenciaCardiaca.mensaje,
    );
    expect(
      errorDeRango(const SignosVitales(saturacionOxigeno: 40)),
      rangoSaturacion.mensaje,
    );
    expect(
      errorDeRango(const SignosVitales(frecuenciaRespiratoria: 2)),
      rangoFrecuenciaRespiratoria.mensaje,
    );
  });
}
