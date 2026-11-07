import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/compartido/widgets/aviso_cambios_fallidos.dart';
import 'package:oncuidar/nucleo/proveedores.dart';
import 'package:oncuidar/nucleo/sesion/servicio_sesion.dart';
import 'package:oncuidar/nucleo/sincronizacion/cola_escrituras.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../ayudas/offline.dart';

final _aviso = find.byKey(const Key('aviso_cambios_fallidos'));

Future<ColaEscrituras> _montar(
  WidgetTester tester, {
  int fallidas = 0,
  double escalaTexto = 1,
}) async {
  SharedPreferences.setMockInitialValues({});
  final cola = ColaEscrituras();
  for (var i = 0; i < fallidas; i++) {
    await cola.encolar('u1', escrituraDe(id: 'e$i'));
    await cola.moverAFallidas('u1', 'e$i');
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        colaEscriturasProvider.overrideWithValue(cola),
        estadoAutenticacionProvider.overrideWith(
          (_) => Stream.value(
            const SesionUsuario(uid: 'u1', correo: 'a@b.cl', token: 't'),
          ),
        ),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(escalaTexto)),
          child: child!,
        ),
        home: const Scaffold(body: AvisoCambiosFallidos()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return cola;
}

Future<ResumenCola> _resumen(WidgetTester tester, ColaEscrituras cola) async {
  ResumenCola? resultado;
  unawaited(cola.resumen('u1').then((r) => resultado = r));
  for (var i = 0; i < 10 && resultado == null; i++) {
    await tester.pump();
  }
  return resultado!;
}

void main() {
  testWidgets('sin fallidas no muestra nada', (tester) async {
    await _montar(tester);
    expect(_aviso, findsNothing);
  });

  testWidgets('con fallidas avisa cuántos cambios no se guardaron', (
    tester,
  ) async {
    await _montar(tester, fallidas: 2);
    expect(_aviso, findsOneWidget);
    expect(find.text('2 cambios no se pudieron guardar'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.text('Descartar'), findsOneWidget);
  });

  testWidgets('reintentar los devuelve a la cola de envío', (tester) async {
    final cola = await _montar(tester, fallidas: 1);
    expect(find.text('1 cambio no se pudo guardar'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(await _resumen(tester, cola), const ResumenCola(pendientes: 1));
    expect(_aviso, findsNothing);
  });

  testWidgets('descartar pide confirmación antes de borrar', (tester) async {
    final cola = await _montar(tester, fallidas: 1);

    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Se borrará 1 cambio que no se pudo guardar. Esto no se puede deshacer.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(await _resumen(tester, cola), const ResumenCola(fallidas: 1));

    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmar_descartar_fallidas')));
    await tester.pumpAndSettle();
    expect(await _resumen(tester, cola), ResumenCola.vacio);
    expect(_aviso, findsNothing);
  });

  testWidgets('en pantalla angosta con letra grande no se desborda', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _montar(tester, fallidas: 12, escalaTexto: 2);

    expect(tester.takeException(), isNull);
    expect(find.text('Reintentar').hitTestable(), findsOneWidget);
    expect(find.text('Descartar').hitTestable(), findsOneWidget);
  });
}
