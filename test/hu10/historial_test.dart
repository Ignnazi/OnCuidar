import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oncuidar/caracteristicas/historial/historial.dart';
import 'package:oncuidar/core/proveedores/proveedores.dart';
import 'package:oncuidar/core/servicios/servicio_base_datos.dart';
import 'package:oncuidar/core/servicios/servicio_cifrado.dart';
import 'package:oncuidar/modelos/paciente.dart';
import 'package:oncuidar/modelos/registro_clinico.dart';

const _clavePrueba = 'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';
const _uid = 'uid-1';

MockFirebaseAuth _auth() => MockFirebaseAuth(
  mockUser: MockUser(uid: _uid, email: 'cuidador@test.cl'),
);

const _diasSemana = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

String _dd(int v) => v.toString().padLeft(2, '0');

String _etiquetaFecha(DateTime fecha) =>
    '${_diasSemana[fecha.weekday - 1]} ${_dd(fecha.day)}/${_dd(fecha.month)}/${fecha.year}';

Future<(ServicioBaseDatos, FakeFirebaseFirestore, String)> _baseConPaciente(
  ServicioCifrado cifrado,
) async {
  await cifrado.fijarClave(_uid, _clavePrueba);
  final firestore = FakeFirebaseFirestore();
  final base = ServicioBaseDatos(
    base: firestore,
    uidPrueba: _uid,
    cifrado: cifrado,
  );
  await base.crearCuidador({
    'displayName': 'Ana Torres',
    'email': 'cuidador@test.cl',
    'phone': '+56 9 1111 1111',
    'relationship': 'Madre',
    'address': 'Av. Siempre Viva 742',
  });
  final idPaciente = await base.crearPaciente(
    Paciente(
      id: 'paciente',
      fullName: 'Paciente Test',
      createdAt: DateTime.now(),
    ),
  );
  return (base, firestore, idPaciente);
}

Widget _pantalla(
  ServicioCifrado cifrado,
  ServicioBaseDatos base, {
  DateTime? filtroFecha,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (c, s) => HistorialScreen(filtroFechaInicial: filtroFecha),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (c, s) =>
            const Scaffold(body: Center(child: Text('Dashboard'))),
      ),
      GoRoute(
        path: '/registro-clinico',
        builder: (c, s) =>
            const Scaffold(body: Center(child: Text('Registro clínico abierto'))),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      firebaseAuthProvider.overrideWithValue(_auth()),
      servicioCifradoProvider.overrideWithValue(cifrado),
      servicioBaseDatosProvider.overrideWith((_) => base),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void _taller(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

RegistroClinico _registro(
  String id,
  String idPaciente, {
  DateTime? fecha,
  NivelAlerta nivel = NivelAlerta.normal,
}) {
  final momento = fecha ?? DateTime.now();
  return RegistroClinico(
    id: id,
    pacienteId: idPaciente,
    fecha: momento,
    creadoEn: momento,
    tipoRegistro: 'programado',
    nivelAlerta: nivel,
  );
}

void main() {
  testWidgets('lista del más reciente al más antiguo', (tester) async {
    _taller(tester);
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    final (base, _, idPaciente) = await _baseConPaciente(cifrado);
    final ahora = DateTime.now();
    final ayer = ahora.subtract(const Duration(days: 1));
    await base.guardarRegistroClinico(
      idPaciente,
      _registro('hoy', idPaciente, fecha: ahora),
    );
    await base.guardarRegistroClinico(
      idPaciente,
      _registro('ayer', idPaciente, fecha: ayer),
    );
    await tester.pumpWidget(_pantalla(cifrado, base));
    await tester.pumpAndSettle();

    final etiquetaHoy = _etiquetaFecha(ahora);
    final etiquetaAyer = _etiquetaFecha(ayer);
    expect(find.text(etiquetaHoy), findsOneWidget);
    expect(find.text(etiquetaAyer), findsOneWidget);
    expect(find.text('No hay registros aún'), findsNothing);

    final dyHoy = tester.getTopLeft(find.text(etiquetaHoy)).dy;
    final dyAyer = tester.getTopLeft(find.text(etiquetaAyer)).dy;
    expect(
      dyHoy,
      lessThan(dyAyer),
      reason: 'el registro de hoy debe aparecer antes que el de ayer',
    );
  });

  testWidgets('expandir muestra síntomas y observaciones descifradas', (
    tester,
  ) async {
    _taller(tester);
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    final (base, _, idPaciente) = await _baseConPaciente(cifrado);
    final ahora = DateTime.now();
    await base.guardarRegistroClinico(
      idPaciente,
      RegistroClinico(
        id: 'detalle',
        pacienteId: idPaciente,
        fecha: ahora,
        creadoEn: ahora,
        tipoRegistro: 'programado',
        signosVitales: SignosVitales(
          temperature: 38.5,
          heartRate: 110,
          oxygenSaturation: 92,
          respiratoryRate: 22,
        ),
        sintomas: const [EntradaSintoma(name: 'Fiebre', intensity: 8)],
        observaciones: 'Paciente estable',
        nivelAlerta: NivelAlerta.alerta,
      ),
    );
    await tester.pumpWidget(_pantalla(cifrado, base));
    await tester.pumpAndSettle();

    expect(
      find.text('Paciente estable'),
      findsNothing,
      reason: 'el detalle debe estar oculto hasta expandir',
    );

    await tester.ensureVisible(find.text('Click para ver registro completo'));
    await tester.tap(find.text('Click para ver registro completo'));
    await tester.pumpAndSettle();

    expect(find.text('Fiebre · Intenso (8/10)'), findsOneWidget);
    expect(find.text('Observaciones'), findsOneWidget);
    expect(find.text('Paciente estable'), findsOneWidget);
  });

  testWidgets('historial muestra un síntoma guardado con intensidad 0', (
    tester,
  ) async {
    _taller(tester);
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    final (base, _, idPaciente) = await _baseConPaciente(cifrado);
    final ahora = DateTime.now();
    await base.guardarRegistroClinico(
      idPaciente,
      RegistroClinico(
        id: 'cero',
        pacienteId: idPaciente,
        fecha: ahora,
        creadoEn: ahora,
        tipoRegistro: 'programado',
        sintomas: const [EntradaSintoma(name: 'Fiebre', intensity: 0)],
      ),
    );
    await tester.pumpWidget(_pantalla(cifrado, base));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Click para ver registro completo'));
    await tester.tap(find.text('Click para ver registro completo'));
    await tester.pumpAndSettle();

    expect(find.text('Fiebre · Mínimo síntoma (0/10)'), findsOneWidget);
  });

  testWidgets('filtro por estado muestra solo los registros coincidentes', (
    tester,
  ) async {
    _taller(tester);
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    final (base, _, idPaciente) = await _baseConPaciente(cifrado);
    final ahora = DateTime.now();
    await base.guardarRegistroClinico(
      idPaciente,
      _registro('normal', idPaciente, fecha: ahora, nivel: NivelAlerta.normal),
    );
    await base.guardarRegistroClinico(
      idPaciente,
      _registro(
        'critico',
        idPaciente,
        fecha: ahora,
        nivel: NivelAlerta.critico,
      ),
    );
    await tester.pumpWidget(_pantalla(cifrado, base));
    await tester.pumpAndSettle();

    final etiqueta = _etiquetaFecha(ahora);
    expect(find.text(etiqueta), findsNWidgets(2));

    await tester.tap(find.text('Crítico').first);
    await tester.pumpAndSettle();

    expect(
      find.text(etiqueta),
      findsOneWidget,
      reason: 'solo sigue visible el registro crítico',
    );
  });

  testWidgets('rango de fechas deja ver solo ese día', (tester) async {
    _taller(tester);
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    final (base, _, idPaciente) = await _baseConPaciente(cifrado);
    final ahora = DateTime.now();
    final ayer = ahora.subtract(const Duration(days: 1));
    await base.guardarRegistroClinico(
      idPaciente,
      _registro('hoy', idPaciente, fecha: ahora),
    );
    await base.guardarRegistroClinico(
      idPaciente,
      _registro('ayer', idPaciente, fecha: ayer),
    );
    await tester.pumpWidget(_pantalla(cifrado, base));
    await tester.pumpAndSettle();

    final etiquetaHoy = _etiquetaFecha(ahora);
    final etiquetaAyer = _etiquetaFecha(ayer);
    expect(find.text(etiquetaHoy), findsOneWidget);
    expect(find.text(etiquetaAyer), findsOneWidget);

    await tester.tap(find.text('Filtrar fecha'));
    await tester.pumpAndSettle();

    final textoFecha =
        '${_dd(ahora.day)}/${_dd(ahora.month)}/${ahora.year}';
    await tester.enterText(
      find.byKey(const Key('campoFechaDesde')),
      textoFecha,
    );
    await tester.enterText(
      find.byKey(const Key('campoFechaHasta')),
      textoFecha,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    expect(find.text(etiquetaHoy), findsOneWidget);
    expect(
      find.text(etiquetaAyer),
      findsNothing,
      reason: 'el rango de un solo día deja fuera el registro de ayer',
    );
  });

  testWidgets('filtro de fecha inicial del inicio filtra ese día', (
    tester,
  ) async {
    _taller(tester);
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    final (base, _, idPaciente) = await _baseConPaciente(cifrado);
    final ahora = DateTime.now();
    final ayer = ahora.subtract(const Duration(days: 1));
    final inicioDeHoy = DateTime(ahora.year, ahora.month, ahora.day);
    await base.guardarRegistroClinico(
      idPaciente,
      _registro('hoy', idPaciente, fecha: ahora),
    );
    await base.guardarRegistroClinico(
      idPaciente,
      _registro('ayer', idPaciente, fecha: ayer),
    );
    await tester.pumpWidget(_pantalla(cifrado, base, filtroFecha: inicioDeHoy));
    await tester.pumpAndSettle();

    expect(find.text(_etiquetaFecha(ahora)), findsOneWidget);
    expect(find.text(_etiquetaFecha(ayer)), findsNothing);
  });

  testWidgets('al subir el tope diario el historial renunera las etiquetas', (
    tester,
  ) async {
    _taller(tester);
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    final (base, _, idPaciente) = await _baseConPaciente(cifrado);
    final ahora = DateTime.now();
    final inicioDeHoy = DateTime(ahora.year, ahora.month, ahora.day);
    for (var i = 1; i <= 3; i++) {
      final momento = inicioDeHoy.add(Duration(hours: 4 - i));
      await base.guardarRegistroClinico(
        idPaciente,
        RegistroClinico(
          id: 'p$i',
          pacienteId: idPaciente,
          fecha: momento,
          creadoEn: momento,
          tipoRegistro: 'programado',
        ),
      );
    }
    final momentoExtra = inicioDeHoy.add(const Duration(hours: 4));
    await base.guardarRegistroClinico(
      idPaciente,
      RegistroClinico(
        id: 'extra',
        pacienteId: idPaciente,
        fecha: momentoExtra,
        creadoEn: momentoExtra,
        tipoRegistro: 'extra',
      ),
    );

    await tester.pumpWidget(_pantalla(cifrado, base));
    await tester.pumpAndSettle();

    expect(find.textContaining('Registro 1/3'), findsOneWidget);
    expect(find.textContaining('Registro 3/3'), findsOneWidget);
    expect(find.textContaining('· Registro extra'), findsOneWidget);

    await base.actualizarPaciente(idPaciente, {'maximo_registros_dia': 4});
    await tester.pumpAndSettle();

    expect(find.textContaining('Registro 4/4'), findsOneWidget);
    expect(find.textContaining('· Registro extra'), findsNothing);
  });

  testWidgets('sin registros muestra el estado vacío', (tester) async {
    _taller(tester);
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    final (base, _, _) = await _baseConPaciente(cifrado);
    await tester.pumpWidget(_pantalla(cifrado, base));
    await tester.pumpAndSettle();

    expect(find.text('No hay registros aún'), findsOneWidget);
    expect(
      find.text('Crea el primer registro desde el botón de abajo.'),
      findsOneWidget,
    );
  });

  testWidgets('el botón "Nuevo registro" abre la pantalla de registro', (
    tester,
  ) async {
    _taller(tester);
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    final (base, _, _) = await _baseConPaciente(cifrado);
    await tester.pumpWidget(_pantalla(cifrado, base));
    await tester.pumpAndSettle();

    expect(find.text('Nuevo registro'), findsOneWidget);

    await tester.tap(find.text('Nuevo registro'));
    await tester.pumpAndSettle();

    expect(find.text('Registro clínico abierto'), findsOneWidget);
  });
}
