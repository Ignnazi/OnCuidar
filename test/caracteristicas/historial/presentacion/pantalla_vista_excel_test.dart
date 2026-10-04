import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/historial/presentacion/pantalla_vista_excel.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/paciente.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';

DatosHojaExcel _datos({
  DateTime? inicio,
  DateTime? fin,
  int cantidad = 3,
  String observaciones = 'Paciente estable durante el día',
}) {
  final base = DateTime(2026, 10, 4, 9);
  return DatosHojaExcel(
    registros: [
      for (var i = 0; i < cantidad; i++)
        RegistroClinico(
          id: 'r$i',
          pacienteId: 'p',
          fecha: base.add(Duration(days: cantidad - i)),
          creadoEn: base.add(Duration(days: cantidad - i)),
          tipoRegistro: 'programado',
          nivelAlerta: NivelAlerta.values[i % 3],
          observaciones: '$observaciones $i',
          signosVitales: const SignosVitales(temperatura: 38.2),
        ),
    ],
    paciente: Paciente(
      id: 'p',
      nombreCompleto: 'Paciente Test',
      centroSaludNombre: 'Hospital Pediátrico',
      contactoEmergenciaNombre: 'María Test',
      creadoEn: DateTime(2026, 1, 1),
    ),
    nombreCuidador: 'Ana Torres',
    fechaInicio: inicio,
    fechaFin: fin,
    generadoEn: DateTime(2026, 10, 8, 20, 15),
  );
}

Future<void> _abrir(
  WidgetTester tester,
  DatosHojaExcel datos, {
  Size tamano = const Size(360, 800),
  VoidCallback? alCompartir,
}) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: PantallaVistaExcel(datos: datos, alCompartir: alCompartir),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra el título, la ficha y el resumen', (tester) async {
    await _abrir(tester, _datos(inicio: DateTime(2026, 10, 4)));

    for (final texto in [
      'HISTORIAL ONCUIDAR',
      'PACIENTE',
      'CUIDADOR',
      'CENTRO DE SALUD',
      'CONTACTO DE EMERGENCIA',
      'RESUMEN',
      'Ana Torres',
      'Hospital Pediátrico',
    ]) {
      expect(find.text(texto), findsWidgets, reason: 'falta «$texto»');
    }
  });

  testWidgets('el resumen dice el día o el rango filtrado', (tester) async {
    await _abrir(tester, _datos(inicio: DateTime(2026, 10, 4)));
    expect(find.text('Día'), findsOneWidget);
    expect(find.text('Domingo 04/10/2026'), findsOneWidget);

    await _abrir(
      tester,
      _datos(inicio: DateTime(2026, 10, 4), fin: DateTime(2026, 10, 7)),
    );
    expect(find.text('Período'), findsOneWidget);
    expect(find.text('Del 04-10-2026 al 07-10-2026'), findsOneWidget);
  });

  testWidgets('la tabla trae los encabezados y una fila por registro', (
    tester,
  ) async {
    await _abrir(tester, _datos(cantidad: 4));

    for (final encabezado in ['Fecha', 'Hora', 'Estado', 'Temp.', 'Síntomas']) {
      expect(find.text(encabezado), findsOneWidget);
    }
    expect(find.text('Sat. O₂'), findsOneWidget);
    final tabla = tester.widget<Table>(find.byKey(const Key('tablaExcel')));
    expect(tabla.children, hasLength(5));
    expect(find.text('38.2°C'), findsNWidgets(4));
  });

  testWidgets('las filas salen del registro más antiguo al más reciente', (
    tester,
  ) async {
    await _abrir(tester, _datos(cantidad: 3));

    double y(String texto) => tester.getTopLeft(find.text(texto)).dy;
    expect(
      y('Paciente estable durante el día 2'),
      lessThan(y('Paciente estable durante el día 1')),
    );
    expect(
      y('Paciente estable durante el día 1'),
      lessThan(y('Paciente estable durante el día 0')),
    );
  });

  testWidgets('el texto largo se reparte en varias líneas dentro de su celda', (
    tester,
  ) async {
    await _abrir(tester, _datos(cantidad: 1, observaciones: 'palabra ' * 30));

    final observacion = find.textContaining('palabra');
    final alto = tester.getSize(observacion).height;
    expect(alto, greaterThan(40));
    expect(tester.getSize(observacion).width, lessThanOrEqualTo(44 * 7.2));
  });

  testWidgets('la hoja se puede acercar y mover sin desbordar la pantalla', (
    tester,
  ) async {
    await _abrir(tester, _datos(cantidad: 6), tamano: const Size(320, 568));
    expect(tester.takeException(), isNull);

    final zoom = find.byKey(const Key('zoomVistaExcel'));
    await tester.drag(zoom, const Offset(-400, -200));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final visor = tester.widget<InteractiveViewer>(zoom);
    expect(visor.constrained, isFalse);
    expect(visor.minScale, lessThan(1));
    expect(visor.maxScale, greaterThan(1));
  });

  testWidgets('compartir y volver funcionan', (tester) async {
    var compartido = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => abrirVistaExcel(
              context,
              datos: _datos(),
              alCompartir: () => compartido++,
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('compartirVistaExcel')));
    expect(compartido, 1);

    await tester.tap(find.byKey(const Key('cerrarVistaExcel')));
    await tester.pumpAndSettle();
    expect(find.byType(PantallaVistaExcel), findsNothing);
  });

  testWidgets('sin acción de compartir no hay botón', (tester) async {
    await _abrir(tester, _datos());
    expect(find.byKey(const Key('compartirVistaExcel')), findsNothing);
  });
}
