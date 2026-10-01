import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayudas_exportacion.dart';

void main() {
  testWidgets('el PDF exportado sale del más antiguo al más reciente', (
    tester,
  ) async {
    tallerDePrueba(tester);
    final (base, cifrado, activo, _) = await baseConDosPacientes();
    final compartidos = instalarCanalesDeExportacion();
    for (final dia in ['03', '01', '02']) {
      await base.guardarRegistroClinico(
        activo,
        registroDe(
          '2026-09-$dia',
          activo,
          DateTime(2026, 9, int.parse(dia), 8),
        ),
      );
    }

    await tester.pumpWidget(
      pantallaHistorial(base, cifrado, pacienteActivo: activo),
    );
    await tester.pumpAndSettle();
    final bytes = await exportarDesdeLaPantalla(
      tester,
      'Exportar PDF',
      compartidos,
    );

    expect(observacionesPdf(bytes, prefijo: 'obs'), [
      'obs-2026-09-01',
      'obs-2026-09-02',
      'obs-2026-09-03',
    ]);
    expect(
      fechasEsperadasEnPdf(bytes, {'01-09-2026', '02-09-2026', '03-09-2026'}),
      ['01-09-2026', '02-09-2026', '03-09-2026'],
    );
  });

  testWidgets('el menú de exportación ofrece Abrir y Compartir', (
    tester,
  ) async {
    tallerDePrueba(tester);
    final (base, cifrado, activo, _) = await baseConDosPacientes();
    instalarCanalesDeExportacion();
    await base.guardarRegistroClinico(
      activo,
      registroDe('2026-09-01', activo, DateTime(2026, 9, 1, 8)),
    );

    await tester.pumpWidget(
      pantallaHistorial(base, cifrado, pacienteActivo: activo),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Exportar PDF'));
    await tester.pumpAndSettle();

    expect(find.text('Abrir archivo'), findsOneWidget);
    expect(find.text('Compartir'), findsOneWidget);
    expect(find.byKey(const Key('botonAbrirExportacion')), findsOneWidget);
    expect(find.byKey(const Key('botonCompartirExportacion')), findsOneWidget);
  });
}
