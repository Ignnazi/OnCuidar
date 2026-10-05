import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/datos/repositorio_registros_clinicos.dart';

import '../../../ayudas/exportacion.dart';

void main() {
  testWidgets('el PDF exportado sale del más antiguo al más reciente', (
    tester,
  ) async {
    tallerDePrueba(tester);
    final (base, cifrado, activo, _) = await baseConDosPacientes();
    final compartidos = instalarCanalesDeExportacion();
    for (final dia in ['03', '01', '02']) {
      await RepositorioRegistrosClinicos(base).guardarRegistroClinico(
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

  testWidgets('exportar abre el archivo directo, sin menú de Abrir o Compartir', (
    tester,
  ) async {
    tallerDePrueba(tester);
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
    await tester.tap(find.byTooltip('Exportar PDF'));
    await esperarHasta(tester, find.byKey(const Key('compartirVisorPdf')));

    expect(find.text('Abrir archivo'), findsNothing);
    expect(find.byKey(const Key('botonAbrirExportacion')), findsNothing);
    expect(find.byKey(const Key('botonCompartirExportacion')), findsNothing);
    expect(find.byKey(const Key('compartirVisorPdf')), findsOneWidget);
    expect(find.byKey(const Key('descargarVisorPdf')), findsOneWidget);
  });

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
