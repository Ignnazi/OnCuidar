import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/configuracion/dominio/escala_texto.dart';
import 'package:oncuidar/caracteristicas/configuracion/dominio/modo_tema.dart';
import 'package:oncuidar/caracteristicas/configuracion/presentacion/proveedores_configuracion.dart';
import 'package:oncuidar/caracteristicas/configuracion/presentacion/seccion_configuracion.dart';
import 'package:oncuidar/caracteristicas/perfil/presentacion/widgets/tarjeta_configuracion.dart';
import 'package:oncuidar/nucleo/proveedores.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../ayudas/recordatorios.dart';

Future<(ProviderContainer, NotificacionesFalsas)> _montar(
  WidgetTester tester,
) async {
  final (base, _) = await baseRecordatorios();
  final notif = NotificacionesFalsas();
  final contenedor = ProviderContainer(
    overrides: [
      baseDatosSeguraProvider.overrideWith((_) => base),
      servicioNotificacionesProvider.overrideWithValue(notif),
    ],
  );
  addTearDown(contenedor.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: contenedor,
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: SeccionConfiguracion()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (contenedor, notif);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('elegir un tamaño lo aplica y lo guarda', (tester) async {
    final (contenedor, _) = await _montar(tester);
    expect(contenedor.read(escalaTextoProvider), EscalaTexto.normal);

    await tester.tap(find.byKey(const Key('escala_grande')));
    await tester.pumpAndSettle();

    expect(contenedor.read(escalaTextoProvider), EscalaTexto.grande);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(claveEscalaTexto), 'grande');
  });

  testWidgets('elegir el modo oscuro lo aplica y lo guarda', (tester) async {
    final (contenedor, _) = await _montar(tester);
    expect(contenedor.read(modoTemaProvider), ModoTema.sistema);

    await tester.tap(find.byKey(const Key('modo_oscuro')));
    await tester.pumpAndSettle();

    expect(contenedor.read(modoTemaProvider), ModoTema.oscuro);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(claveModoTema), 'oscuro');
  });

  testWidgets('el modo guardado se restaura al abrir la app', (tester) async {
    SharedPreferences.setMockInitialValues({claveModoTema: 'claro'});
    final (contenedor, _) = await _montar(tester);

    expect(contenedor.read(modoTemaProvider), ModoTema.claro);
  });

  testWidgets('el tamaño guardado se restaura al abrir la app', (tester) async {
    SharedPreferences.setMockInitialValues({claveEscalaTexto: 'muyGrande'});
    final (contenedor, _) = await _montar(tester);

    expect(contenedor.read(escalaTextoProvider), EscalaTexto.muyGrande);
  });

  testWidgets('silenciar avisos cancela los programados y se recuerda', (
    tester,
  ) async {
    final (_, notif) = await _montar(tester);

    await tester.tap(find.byKey(const Key('interruptorSilencio')));
    await tester.pumpAndSettle();

    expect(notif.canceladasTodas, 1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('notificaciones_silenciadas'), isTrue);
  });

  testWidgets('el interruptor refleja el silencio ya guardado', (tester) async {
    SharedPreferences.setMockInitialValues({
      'notificaciones_silenciadas': true,
    });
    await _montar(tester);

    final interruptor = tester.widget<SwitchListTile>(
      find.byKey(const Key('interruptorSilencio')),
    );
    expect(interruptor.value, isTrue);
  });

  testWidgets('la tarjeta del perfil abre los ajustes en una hoja', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: TarjetaConfiguracion())),
      ),
    );

    await tester.tap(find.byKey(const Key('abrirConfiguracion')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('hojaConfiguracion')), findsOneWidget);
    expect(find.byKey(const Key('modo_oscuro')), findsOneWidget);
    expect(find.byKey(const Key('interruptorSilencio')), findsOneWidget);
  });
}
