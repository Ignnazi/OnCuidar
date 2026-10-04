import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/pantalla_visor_pdf.dart';
import 'package:oncuidar/caracteristicas/historial/presentacion/pantalla_vista_excel.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/datos/repositorio_registros_clinicos.dart';

import '../../../ayudas/exportacion.dart';

Future<void> _esperar(WidgetTester tester, Finder aparece) async {
  for (var vuelta = 0; vuelta < 80 && aparece.evaluate().isEmpty; vuelta++) {
    await tester.pump(const Duration(milliseconds: 50));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
  }
  await tester.pumpAndSettle();
}

void main() {
  Future<List<String>> prepararPantalla(WidgetTester tester) async {
    tallerDePrueba(tester);
    final (base, cifrado, activo, _) = await baseConDosPacientes();
    final compartidos = instalarCanalesDeExportacion();
    await RepositorioRegistrosClinicos(base).guardarRegistroClinico(
      activo,
      registroDe('2026-09-01', activo, DateTime(2026, 9, 1, 8)),
    );
    await tester.pumpWidget(
      pantallaHistorial(
        base,
        cifrado,
        pacienteActivo: activo,
        overridesExtra: [
          constructorDocumentoPdfProvider.overrideWithValue(
            (ruta) => Center(child: Text('documento en $ruta')),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    return compartidos;
  }

  testWidgets('abrir el PDF lo muestra en el visor de la app', (tester) async {
    final compartidos = await prepararPantalla(tester);

    await tester.tap(find.byTooltip('Exportar PDF'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('botonAbrirExportacion')));
    await _esperar(tester, find.byType(PantallaVisorPdf));

    expect(find.byType(PantallaVisorPdf), findsOneWidget);
    expect(find.text('Historial clínico'), findsOneWidget);
    expect(find.textContaining('documento en '), findsOneWidget);
    expect(find.textContaining('.pdf'), findsOneWidget);
    expect(compartidos, isEmpty);

    await tester.tap(find.byKey(const Key('compartirVisorPdf')));
    for (var vuelta = 0; vuelta < 50 && compartidos.isEmpty; vuelta++) {
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    }
    expect(compartidos, hasLength(1));
    expect(compartidos.single, endsWith('.pdf'));

    await tester.tap(find.byKey(const Key('cerrarVisorPdf')));
    await tester.pumpAndSettle();
    expect(find.byType(PantallaVisorPdf), findsNothing);
  });

  testWidgets('abrir el Excel dibuja la hoja dentro de la app', (tester) async {
    final compartidos = await prepararPantalla(tester);

    await tester.tap(find.byTooltip('Exportar Excel'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('botonAbrirExportacion')));
    await _esperar(tester, find.byType(PantallaVistaExcel));

    expect(find.byType(PantallaVistaExcel), findsOneWidget);
    for (final texto in [
      'HISTORIAL ONCUIDAR',
      'RESUMEN',
      'Fecha',
      'Síntomas',
    ]) {
      expect(find.text(texto), findsWidgets, reason: 'falta «$texto»');
    }
    expect(compartidos, isEmpty);

    await tester.tap(find.byKey(const Key('compartirVistaExcel')));
    for (var vuelta = 0; vuelta < 50 && compartidos.isEmpty; vuelta++) {
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    }
    expect(compartidos.single, endsWith('.xlsx'));

    await tester.tap(find.byKey(const Key('cerrarVistaExcel')));
    await tester.pumpAndSettle();
    expect(find.byType(PantallaVistaExcel), findsNothing);
  });

  testWidgets('compartir desde el menú sigue funcionando como antes', (
    tester,
  ) async {
    final compartidos = await prepararPantalla(tester);

    final bytes = await exportarDesdeLaPantalla(
      tester,
      'Exportar PDF',
      compartidos,
    );

    expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
    expect(find.byType(PantallaVisorPdf), findsNothing);
  });
}
