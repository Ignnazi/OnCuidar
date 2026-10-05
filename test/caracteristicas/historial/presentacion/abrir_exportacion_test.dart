import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/pantalla_visor_pdf.dart';
import 'package:oncuidar/caracteristicas/historial/presentacion/pantalla_vista_excel.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/datos/repositorio_registros_clinicos.dart';

import '../../../ayudas/exportacion.dart';

void main() {
  Future<({List<String> compartidos, List<Map<Object?, Object?>> guardados})>
  prepararPantalla(WidgetTester tester) async {
    tallerDePrueba(tester);
    final (base, cifrado, activo, _) = await baseConDosPacientes();
    final guardados = <Map<Object?, Object?>>[];
    final compartidos = instalarCanalesDeExportacion(guardados: guardados);
    await RepositorioRegistrosClinicos(base).guardarRegistroClinico(
      activo,
      registroDe('2026-09-01', activo, DateTime(2026, 9, 1, 8)),
    );
    await tester.pumpWidget(
      pantallaHistorial(base, cifrado, pacienteActivo: activo),
    );
    await tester.pumpAndSettle();
    return (compartidos: compartidos, guardados: guardados);
  }

  testWidgets('exportar el PDF lo abre en el visor de la app', (tester) async {
    final c = await prepararPantalla(tester);

    await tester.tap(find.byTooltip('Exportar PDF'));
    await esperarHasta(tester, find.byType(PantallaVisorPdf));

    expect(find.byType(PantallaVisorPdf), findsOneWidget);
    expect(find.text('Historial clínico'), findsOneWidget);
    expect(find.textContaining('documento en '), findsOneWidget);
    expect(find.textContaining('.pdf'), findsOneWidget);
    expect(c.compartidos, isEmpty);
    expect(c.guardados, isEmpty);

    await tester.tap(find.byKey(const Key('cerrarVisorPdf')));
    await tester.pumpAndSettle();
    expect(find.byType(PantallaVisorPdf), findsNothing);
  });

  testWidgets('desde el visor del PDF se comparte el mismo archivo', (
    tester,
  ) async {
    final c = await prepararPantalla(tester);
    await tester.tap(find.byTooltip('Exportar PDF'));
    await esperarHasta(tester, find.byType(PantallaVisorPdf));

    await tester.tap(find.byKey(const Key('compartirVisorPdf')));
    for (var vuelta = 0; vuelta < 50 && c.compartidos.isEmpty; vuelta++) {
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    }

    expect(c.compartidos, hasLength(1));
    expect(c.compartidos.single, endsWith('.pdf'));
  });

  testWidgets('desde el visor del PDF se descarga al teléfono y se avisa', (
    tester,
  ) async {
    final c = await prepararPantalla(tester);
    await tester.tap(find.byTooltip('Exportar PDF'));
    await esperarHasta(tester, find.byType(PantallaVisorPdf));

    await tester.tap(find.byKey(const Key('descargarVisorPdf')));
    for (var vuelta = 0; vuelta < 50 && c.guardados.isEmpty; vuelta++) {
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    }
    await tester.pumpAndSettle();

    final guardado = c.guardados.single;
    expect(
      guardado['fileName'],
      matches(RegExp(r'^historial_oncuidar_.*\.pdf$')),
    );
    expect(
      String.fromCharCodes((guardado['data']! as List<int>).sublist(0, 4)),
      '%PDF',
    );
    expect(find.text('Archivo guardado en tu teléfono'), findsOneWidget);
  });

  testWidgets('exportar el Excel dibuja la hoja dentro de la app', (
    tester,
  ) async {
    final c = await prepararPantalla(tester);

    await tester.tap(find.byTooltip('Exportar Excel'));
    await esperarHasta(tester, find.byType(PantallaVistaExcel));

    expect(find.byType(PantallaVistaExcel), findsOneWidget);
    for (final texto in [
      'HISTORIAL ONCUIDAR',
      'RESUMEN',
      'Fecha',
      'Síntomas',
    ]) {
      expect(find.text(texto), findsWidgets, reason: 'falta «$texto»');
    }
    expect(c.compartidos, isEmpty);
    expect(c.guardados, isEmpty);

    await tester.tap(find.byKey(const Key('cerrarVistaExcel')));
    await tester.pumpAndSettle();
    expect(find.byType(PantallaVistaExcel), findsNothing);
  });

  testWidgets('desde la hoja de Excel se comparte y se descarga', (
    tester,
  ) async {
    final c = await prepararPantalla(tester);
    await tester.tap(find.byTooltip('Exportar Excel'));
    await esperarHasta(tester, find.byType(PantallaVistaExcel));

    await tester.tap(find.byKey(const Key('descargarVistaExcel')));
    for (var vuelta = 0; vuelta < 50 && c.guardados.isEmpty; vuelta++) {
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    }
    await tester.pumpAndSettle();
    expect(c.guardados.single['fileName'], endsWith('.xlsx'));
    expect(find.text('Archivo guardado en tu teléfono'), findsOneWidget);

    await tester.tap(find.byKey(const Key('compartirVistaExcel')));
    for (var vuelta = 0; vuelta < 50 && c.compartidos.isEmpty; vuelta++) {
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    }
    expect(c.compartidos.single, endsWith('.xlsx'));
  });

  testWidgets('si se cancela «Guardar como» se avisa que no se guardó', (
    tester,
  ) async {
    await prepararPantalla(tester);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_file_dialog'),
          (call) async => null,
        );
    await tester.tap(find.byTooltip('Exportar PDF'));
    await esperarHasta(tester, find.byType(PantallaVisorPdf));

    await tester.tap(find.byKey(const Key('descargarVisorPdf')));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    expect(find.text('No se guardó el archivo'), findsOneWidget);
  });

  testWidgets('compartir desde el visor sigue entregando un PDF válido', (
    tester,
  ) async {
    final c = await prepararPantalla(tester);

    final bytes = await exportarDesdeLaPantalla(
      tester,
      'Exportar PDF',
      c.compartidos,
    );

    expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
  });
}
