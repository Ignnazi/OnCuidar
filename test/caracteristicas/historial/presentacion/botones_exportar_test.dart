import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/datos/repositorio_registros_clinicos.dart';

import '../../../ayudas/exportacion.dart';

void main() {
  testWidgets('las palabras PDF y Excel son blancas también en modo oscuro', (
    tester,
  ) async {
    tallerDePrueba(tester);
    Paleta.usar(coloresOscuros);
    addTearDown(() => Paleta.usar(coloresClaros));
    final (base, cifrado, activo, _) = await baseConDosPacientes();
    instalarCanalesDeExportacion();
    await RepositorioRegistrosClinicos(base).guardarRegistroClinico(
      activo,
      registroDe('2026-09-01', activo, DateTime(2026, 9, 1, 8)),
    );

    await tester.pumpWidget(
      pantallaHistorial(base, cifrado, pacienteActivo: activo),
    );
    await tester.pumpAndSettle();

    for (final nombre in ['PDF', 'Excel']) {
      final texto = tester.widget<Text>(find.text(nombre));
      expect(texto.style!.color, Colors.white, reason: 'palabra «$nombre»');
    }
  });
}
