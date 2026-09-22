import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oncuidar/caracteristicas/historial/historial.dart';
import 'package:oncuidar/caracteristicas/onboarding/iniciar_sesion.dart';
import 'package:oncuidar/caracteristicas/onboarding/registro.dart';
import 'package:oncuidar/caracteristicas/perfil/perfil.dart';
import 'package:oncuidar/caracteristicas/recordatorios/recordatorios.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/registro_clinico.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/widgets/selector_multi_sintoma.dart';
import 'package:oncuidar/core/proveedores/proveedores.dart';
import 'package:oncuidar/core/servicios/servicio_base_datos.dart';
import 'package:oncuidar/core/servicios/servicio_cifrado.dart';
import 'package:oncuidar/core/servicios/servicio_registro.dart';
import 'package:oncuidar/modelos/paciente.dart';
import 'package:oncuidar/modelos/recordatorio.dart';
import 'package:oncuidar/modelos/registro_clinico.dart';

const _clavePrueba = 'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';
const _uid = 'uid-test';

void _viewportCompacto(WidgetTester tester, Size tamano) {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

MockFirebaseAuth _authConSesion() => MockFirebaseAuth(
  mockUser: MockUser(uid: _uid, email: 'ana@correo.cl'),
);

Future<ServicioBaseDatos> _baseConCuidador(ServicioCifrado cifrado) async {
  await cifrado.fijarClave(_uid, _clavePrueba);
  final base = ServicioBaseDatos(
    base: FakeFirebaseFirestore(),
    uidPrueba: _uid,
    cifrado: cifrado,
  );
  await base.crearCuidador({
    'displayName': 'Ana Torres',
    'email': 'ana@correo.cl',
    'phone': '+56 9 1111 1111',
    'relationship': 'Madre',
    'address': 'Av. Siempre Viva 742',
  });
  return base;
}

Widget _pantalla(
  MockFirebaseAuth auth,
  ServicioBaseDatos base,
  ServicioCifrado cifrado,
  Widget inicio, {
  List<GoRoute> rutasExtra = const [],
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (c, s) => inicio),
      GoRoute(
        path: '/bienvenida',
        builder: (c, s) =>
            const Scaffold(body: Center(child: Text('Bienvenida'))),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (c, s) =>
            const Scaffold(body: Center(child: Text('Dashboard'))),
      ),
      ...rutasExtra,
    ],
  );
  return ProviderScope(
    overrides: [
      firebaseAuthProvider.overrideWithValue(auth),
      servicioCifradoProvider.overrideWithValue(cifrado),
      servicioBaseDatosProvider.overrideWith((ref) => base),
      servicioRegistroProvider.overrideWith(
        (ref) => ServicioRegistro(
          auth: auth,
          cifrado: cifrado,
          baseDatos: base,
          alDesbloquear: () =>
              ref.read(bloqueoCifradoProvider.notifier).fijarDesbloqueado(true),
          registrarCorreoRespaldo: (email) async {},
        ),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _scrollHastaElFinal(WidgetTester tester) async {
  await tester.drag(
    find.byType(SingleChildScrollView).first,
    const Offset(0, -3000),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('registro no desborda en 360x800', (tester) async {
    _viewportCompacto(tester, const Size(360, 800));
    final auth = _authConSesion();
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    final base = await _baseConCuidador(cifrado);
    await tester.pumpWidget(_pantalla(auth, base, cifrado, const Registro()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _scrollHastaElFinal(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('registro no desborda en 320x568', (tester) async {
    _viewportCompacto(tester, const Size(320, 568));
    final auth = _authConSesion();
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    final base = await _baseConCuidador(cifrado);
    await tester.pumpWidget(_pantalla(auth, base, cifrado, const Registro()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _scrollHastaElFinal(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('iniciar sesión no desborda en 320x568', (tester) async {
    _viewportCompacto(tester, const Size(320, 568));
    final auth = _authConSesion();
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    final base = await _baseConCuidador(cifrado);
    await tester.pumpWidget(
      _pantalla(auth, base, cifrado, const IniciarSesion()),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _scrollHastaElFinal(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('perfil (pacientes + mi perfil) no desborda en 360x800', (
    tester,
  ) async {
    _viewportCompacto(tester, const Size(360, 800));
    final auth = _authConSesion();
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    final base = await _baseConCuidador(cifrado);
    await tester.pumpWidget(_pantalla(auth, base, cifrado, const Perfil()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _scrollHastaElFinal(tester);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Mi perfil'));
    await tester.pumpAndSettle();
    await _scrollHastaElFinal(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'detalle de paciente activo no desborda en 360x800 con textos largos',
    (tester) async {
      _viewportCompacto(tester, const Size(360, 800));
      final auth = _authConSesion();
      final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
      await cifrado.restaurarClave(_uid);
      final base = ServicioBaseDatos(
        base: FakeFirebaseFirestore(),
        uidPrueba: _uid,
        cifrado: cifrado,
      );
      await base.crearCuidador({
        'displayName': 'Ana Torres',
        'email': 'ana@correo.cl',
        'phone': '+56 9 1111 1111',
        'relationship': 'Madre',
        'address': 'Av. Siempre Viva 742',
      });
      await base.crearPaciente(
        Paciente(
          id: 'auto',
          fullName: 'Anastasia Margarita Constanza del Carmen de los Andes',
          rut: '25.123.456-7',
          age: 87,
          diagnosis:
              'Cuidados paliativos avanzados con comorbilidades múltiples',
          tratamientoFase: 'Tratamiento paliativo ambulatorio especializado',
          centroSaludNombre:
              'Centro de Salud Familiar Dr. Salvador Allende Norte',
          centroSaludTelefono: '+56 9 1234 5678',
          contactoEmergenciaNombre: 'Carlos Eduardo Vejar Fuenzalida',
          contactoEmergenciaTelefono: '+56 9 8765 4321',
          createdAt: DateTime.now(),
        ),
      );
      await tester.pumpWidget(_pantalla(auth, base, cifrado, const Perfil()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await _scrollHastaElFinal(tester);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('registro clínico no desborda en 320x568', (tester) async {
    _viewportCompacto(tester, const Size(320, 568));
    final auth = _authConSesion();
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    final base = await _baseConCuidador(cifrado);
    await base.crearPaciente(
      Paciente(
        id: 'auto',
        fullName: 'Paciente Test',
        createdAt: DateTime.now(),
      ),
    );
    await tester.pumpWidget(
      _pantalla(auth, base, cifrado, const RegistroClinicoScreen()),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final campo = find.byKey(const Key('campoSelectorSintomas'));
    await tester.ensureVisible(campo);
    await tester.pumpAndSettle();
    await tester.tap(campo);
    await tester.pumpAndSettle();
    expect(
      find.byType(SelectorMultiSintoma),
      findsOneWidget,
      reason: 'el selector debe abrirse como modal bottom sheet',
    );

    Future<void> marcar(String nombre) async {
      final opcion = find.widgetWithText(CheckboxListTile, nombre);
      final lista = find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      );
      var marcado = false;
      for (var intento = 0; intento < 4 && !marcado; intento++) {
        if (opcion.evaluate().isEmpty && lista.evaluate().isNotEmpty) {
          await tester.scrollUntilVisible(
            opcion,
            100,
            scrollable: lista.first,
            maxScrolls: 40,
          );
          await tester.pumpAndSettle();
        }
        if (opcion.evaluate().isEmpty) continue;
        final tile = tester.widget<CheckboxListTile>(opcion);
        marcado = tile.value ?? false;
        tile.onChanged?.call(true);
        await tester.pumpAndSettle();
        if (opcion.evaluate().isNotEmpty) {
          marcado = tester.widget<CheckboxListTile>(opcion).value ?? false;
        }
      }
      expect(marcado, isTrue, reason: 'No se pudo marcar "$nombre" en el panel');
    }

    await marcar('Falta de apetito (anorexia)');
    await marcar('Mucositis');

    final chipSnc = find.widgetWithText(ChoiceChip, 'Tumores SNC');
    await tester.ensureVisible(chipSnc);
    await tester.pumpAndSettle();
    await tester.tap(chipSnc);
    await tester.pumpAndSettle();

    await marcar('Dolor de cabeza (cefalea)');
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Cerrar selector'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await _scrollHastaElFinal(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selector de síntomas abierto no desborda en 360x800', (
    tester,
  ) async {
    _viewportCompacto(tester, const Size(360, 800));
    final auth = _authConSesion();
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    final base = await _baseConCuidador(cifrado);
    await base.crearPaciente(
      Paciente(
        id: 'auto',
        fullName: 'Paciente Test',
        createdAt: DateTime.now(),
      ),
    );
    await tester.pumpWidget(
      _pantalla(auth, base, cifrado, const RegistroClinicoScreen()),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final campo = find.byKey(const Key('campoSelectorSintomas'));
    await tester.ensureVisible(campo);
    await tester.pumpAndSettle();
    await tester.tap(campo);
    await tester.pumpAndSettle();
    expect(find.byType(SelectorMultiSintoma), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('historial no desborda en 320x568 con detalle expandido', (
    tester,
  ) async {
    _viewportCompacto(tester, const Size(320, 568));
    final auth = _authConSesion();
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    final base = await _baseConCuidador(cifrado);
    final fecha = DateTime.now();
    final idPaciente = await base.crearPaciente(
      Paciente(id: 'auto', fullName: 'Paciente Test', createdAt: fecha),
    );
    await base.guardarRegistroClinico(
      idPaciente,
      RegistroClinico(
        id: 'detalle',
        pacienteId: idPaciente,
        fecha: fecha,
        creadoEn: fecha,
        tipoRegistro: 'programado',
        signosVitales: SignosVitales(
          temperature: 40,
          heartRate: 120,
          oxygenSaturation: 88,
          respiratoryRate: 24,
        ),
        sintomas: const [EntradaSintoma(name: 'Fiebre', intensity: 9)],
        observaciones:
            'Paciente con observaciones muy largas para comprobar que el '
            'detalle no se desborda horizontalmente en pantallas pequeñas.',
        nivelAlerta: NivelAlerta.critico,
      ),
    );
    await tester.pumpWidget(
      _pantalla(auth, base, cifrado, const HistorialScreen()),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final tarjeta = find.text('Click para ver registro completo');
    await tester.ensureVisible(tarjeta);
    await tester.tap(tarjeta);
    await tester.pumpAndSettle();
    expect(
      tester.takeException(),
      isNull,
      reason: 'el detalle expandido no debe desbordar',
    );

    await _scrollHastaElFinal(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('recordatorios no desborda en 360x800', (tester) async {
    _viewportCompacto(tester, const Size(360, 800));
    final auth = _authConSesion();
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    final base = await _baseConCuidador(cifrado);
    final idPaciente = await base.crearPaciente(
      Paciente(id: 'auto', fullName: 'Paciente Test', createdAt: DateTime.now()),
    );
    final fecha = DateTime.now();
    await base.agregarRecordatorio(
      idPaciente,
      Recordatorio(
        id: '',
        pacienteId: idPaciente,
        tipo: 'medicamento',
        titulo: 'Tomar paracetamol de 500 mg junto con una cena ligera',
        descripcion:
            'Recordatorio muy largo sobre la medicación para comprobar que '
            'el texto con elipsis no desborda en pantallas pequeñas.',
        fechaHora: fecha,
        diasRepeticion: const ['lun', 'mar', 'mie', 'jue', 'vie', 'sab', 'dom'],
        activo: true,
        creadoEn: fecha,
      ),
    );
    await tester.pumpWidget(
      _pantalla(auth, base, cifrado, const RecordatoriosScreen()),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _scrollHastaElFinal(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('recordatorios no desborda en 320x568', (tester) async {
    _viewportCompacto(tester, const Size(320, 568));
    final auth = _authConSesion();
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    final base = await _baseConCuidador(cifrado);
    await base.crearPaciente(
      Paciente(id: 'auto', fullName: 'Paciente Test', createdAt: DateTime.now()),
    );
    await tester.pumpWidget(
      _pantalla(auth, base, cifrado, const RecordatoriosScreen()),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _scrollHastaElFinal(tester);
    expect(tester.takeException(), isNull);
  });
}
