import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/paciente.dart';
import 'package:oncuidar/caracteristicas/pacientes/presentacion/proveedores_pacientes.dart';
import 'package:oncuidar/caracteristicas/panel_principal/presentacion/pantalla_panel_principal.dart';
import 'package:oncuidar/caracteristicas/perfil/presentacion/proveedores_perfil.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/presentacion/proveedores_registro_clinico.dart';

Paciente _paciente() => Paciente(
  id: 'paciente-1',
  nombreCompleto: 'Paciente Test',
  creadoEn: DateTime.now(),
);

RegistroClinico _registroConSignos() {
  final ahora = DateTime.now();
  return RegistroClinico(
    id: 'registro-1',
    pacienteId: 'paciente-1',
    fecha: ahora,
    creadoEn: ahora.subtract(const Duration(hours: 2)),
    tipoRegistro: 'programado',
    signosVitales: const SignosVitales(
      temperatura: 36.5,
      frecuenciaCardiaca: 72,
      saturacionOxigeno: 98,
      frecuenciaRespiratoria: 16,
    ),
    nivelAlerta: NivelAlerta.critico,
    sintomas: const [
      EntradaSintoma(nombre: 'Dolor de cabeza', intensidad: 7),
      EntradaSintoma(nombre: 'Fiebre', intensidad: 4),
    ],
  );
}

RegistroClinico _registroDeHoy(String id, String tipo) {
  final ahora = DateTime.now();
  return RegistroClinico(
    id: id,
    pacienteId: 'paciente-1',
    fecha: ahora,
    creadoEn: ahora,
    tipoRegistro: tipo,
  );
}

Widget _pantalla({
  required Paciente? paciente,
  List<RegistroClinico> registros = const [],
  void Function(Map<String, dynamic>? extra)? alAbrirHistorial,
}) {
  final router = GoRouter(
    initialLocation: '/dashboard',
    routes: [
      GoRoute(path: '/dashboard', builder: (c, s) => const Dashboard()),
      GoRoute(
        path: '/perfil',
        builder: (c, s) => const Scaffold(body: Text('Perfil')),
      ),
      GoRoute(
        path: '/registro-clinico',
        builder: (c, s) => const Scaffold(body: Text('Registro')),
      ),
      GoRoute(
        path: '/historial',
        builder: (c, s) {
          alAbrirHistorial?.call(s.extra as Map<String, dynamic>?);
          return const Scaffold(body: Text('Historial'));
        },
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      pacienteActivoProvider.overrideWith(
        (ref) => Stream<Paciente?>.value(paciente),
      ),
      registrosClinicosProvider.overrideWith(
        (ref) => Stream<List<RegistroClinico>>.value(registros),
      ),
      cuidadorProvider.overrideWith(
        (ref) => Stream<Map<String, dynamic>?>.value({'nombre': 'María'}),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _montar(
  WidgetTester tester,
  Paciente? paciente, {
  List<RegistroClinico> registros = const [],
  Size tamano = const Size(800, 1600),
  void Function(Map<String, dynamic>? extra)? alAbrirHistorial,
}) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    _pantalla(
      paciente: paciente,
      registros: registros,
      alAbrirHistorial: alAbrirHistorial,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sin paciente muestra bienvenida y botón para agregar', (
    tester,
  ) async {
    await _montar(tester, null);

    expect(find.text('Aún no tienes pacientes'), findsOneWidget);
    expect(find.text('Agregar paciente'), findsOneWidget);
    expect(find.byIcon(Icons.child_care_outlined), findsOneWidget);
    expect(
      find.textContaining('Hola, María'),
      findsOneWidget,
      reason: 'el nombre del cuidador viene de su perfil guardado',
    );
  });

  testWidgets(
    'con paciente sin registros muestra guiones, banner y estado normal',
    (tester) async {
      await _montar(tester, _paciente());

      expect(find.text('Hola, María'), findsOneWidget);
      expect(find.text('PACIENTE ACTIVO'), findsOneWidget);
      expect(find.text('Sin registros todavía'), findsOneWidget);
      expect(find.text('REGISTROS DE HOY'), findsOneWidget);
      expect(find.text('0/3'), findsOneWidget);
      expect(find.text('-- °C'), findsOneWidget);
      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Ver registros del día'), findsOneWidget);
    },
  );

  testWidgets(
    'con paciente y registros muestra signos, banners y estado crítico',
    (tester) async {
      await _montar(tester, _paciente(), registros: [_registroConSignos()]);

      expect(find.text('36.5 °C'), findsOneWidget);
      expect(find.text('98 %'), findsOneWidget);
      expect(find.text('1/3'), findsOneWidget);
      expect(find.text('Crítico'), findsOneWidget);
      expect(find.textContaining('hace 2 h'), findsOneWidget);
      expect(find.text('Ver registros del día'), findsOneWidget);
    },
  );

  testWidgets('la meta del contador es el máximo diario del paciente', (
    tester,
  ) async {
    final paciente = Paciente(
      id: 'paciente-1',
      nombreCompleto: 'Paciente Test',
      creadoEn: DateTime.now(),
      maximoRegistrosDia: 5,
    );
    await _montar(
      tester,
      paciente,
      registros: [
        _registroDeHoy('r1', 'programado'),
        _registroDeHoy('r2', 'programado'),
      ],
    );

    expect(find.text('2/5'), findsOneWidget);
    expect(find.text('2/3'), findsNothing);
  });

  testWidgets('los registros extra se indican aparte sin sumar al contador', (
    tester,
  ) async {
    await _montar(
      tester,
      _paciente(),
      registros: [
        _registroDeHoy('r1', 'programado'),
        _registroDeHoy('r2', 'programado'),
        _registroDeHoy('r3', 'programado'),
        _registroDeHoy('r4', 'extra'),
        _registroDeHoy('r5', 'extra'),
      ],
    );

    expect(find.text('3/3'), findsOneWidget);
    expect(find.text('+2 extra'), findsOneWidget);
    expect(find.text('5/3'), findsNothing);
  });

  testWidgets(
    'el botón "Ver registros del día" de la tarjeta abre el historial filtrando hoy',
    (tester) async {
      Map<String, dynamic>? extra;
      var visitado = false;

      await _montar(
        tester,
        _paciente(),
        registros: [_registroConSignos()],
        alAbrirHistorial: (e) {
          extra = e;
          visitado = true;
        },
      );

      await tester.ensureVisible(find.text('Ver registros del día'));
      await tester.tap(find.text('Ver registros del día'));
      await tester.pumpAndSettle();

      expect(visitado, isTrue, reason: 'el botón debe abrir el historial');
      expect(extra, isNotNull, reason: 'el botón debe filtrar por fecha');

      final hoy = DateTime.now();
      final filtro = extra!['filtroFecha'] as DateTime;
      expect(filtro.year, hoy.year);
      expect(filtro.month, hoy.month);
      expect(filtro.day, hoy.day);
    },
  );

  testWidgets('no desborda en pantalla pequeña con todos los datos', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _pantalla(paciente: _paciente(), registros: [_registroConSignos()]),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -1000),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('historial en acceso rápido no pasa filtro de fecha', (
    tester,
  ) async {
    Map<String, dynamic>? extra;
    var visitado = false;

    await _montar(
      tester,
      _paciente(),
      registros: [_registroConSignos()],
      alAbrirHistorial: (e) {
        extra = e;
        visitado = true;
      },
    );

    await tester.ensureVisible(find.text('Historial'));
    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();

    expect(visitado, isTrue, reason: 'la ruta /historial debe abrirse');
    expect(extra, isNull, reason: 'el acceso rápido no debe filtrar por fecha');
  });

  testWidgets('accesos rápidos muestran los títulos compactos', (tester) async {
    await _montar(tester, _paciente(), registros: [_registroConSignos()]);

    expect(find.text('Orientación'), findsOneWidget);
    expect(find.text('Recordatorios'), findsOneWidget);
    expect(find.text('FAQ'), findsOneWidget);
    expect(find.text('Biblioteca'), findsOneWidget);
    expect(find.text('Registro'), findsOneWidget);
    expect(find.text('Historial'), findsOneWidget);
  });
}
