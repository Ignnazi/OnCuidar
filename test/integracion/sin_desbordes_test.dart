import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oncuidar/caracteristicas/autenticacion/datos/proveedores_autenticacion.dart';
import 'package:oncuidar/caracteristicas/autenticacion/datos/servicio_alta_cuenta.dart';
import 'package:oncuidar/caracteristicas/pacientes/datos/repositorio_pacientes.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/paciente.dart';
import 'package:oncuidar/caracteristicas/perfil/datos/repositorio_cuidador.dart';
import 'package:oncuidar/caracteristicas/perfil/presentacion/pantalla_perfil.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/presentacion/pantalla_registro_clinico.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/presentacion/widgets/selector_multi_sintoma.dart';
import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
import 'package:oncuidar/nucleo/proveedores.dart';

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

Future<BaseDatosSegura> _baseConCuidador(ServicioCifrado cifrado) async {
  await cifrado.fijarClave(_uid, _clavePrueba);
  final base = BaseDatosSegura(
    base: FakeFirebaseFirestore(),
    uidPrueba: _uid,
    cifrado: cifrado,
  );
  await RepositorioCuidador(base).crearCuidador({
    'nombre': 'Ana Torres',
    'correo': 'ana@correo.cl',
    'telefono': '+56 9 1111 1111',
    'relacion': 'Madre',
    'direccion': 'Av. Siempre Viva 742',
  });
  return base;
}

Widget _pantalla(
  MockFirebaseAuth auth,
  BaseDatosSegura base,
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
      baseDatosSeguraProvider.overrideWith((ref) => base),
      servicioRegistroProvider.overrideWith(
        (ref) => ServicioRegistro(
          auth: auth,
          cifrado: cifrado,
          repositorioPacientes: RepositorioPacientes(base),
          repositorioCuidador: RepositorioCuidador(base),
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
  testWidgets(
    'detalle de paciente activo no desborda en 360x800 con textos largos',
    (tester) async {
      _viewportCompacto(tester, const Size(360, 800));
      final auth = _authConSesion();
      final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
      await cifrado.restaurarClave(_uid);
      final base = BaseDatosSegura(
        base: FakeFirebaseFirestore(),
        uidPrueba: _uid,
        cifrado: cifrado,
      );
      await RepositorioCuidador(base).crearCuidador({
        'nombre': 'Ana Torres',
        'correo': 'ana@correo.cl',
        'telefono': '+56 9 1111 1111',
        'relacion': 'Madre',
        'direccion': 'Av. Siempre Viva 742',
      });
      await RepositorioPacientes(base).crearPaciente(
        Paciente(
          id: 'auto',
          nombreCompleto:
              'Anastasia Margarita Constanza del Carmen de los Andes',
          rut: '25.123.456-7',
          edad: 87,
          diagnostico:
              'Cuidados paliativos avanzados con comorbilidades múltiples',
          tratamientoFase: 'Tratamiento paliativo ambulatorio especializado',
          centroSaludNombre:
              'Centro de Salud Familiar Dr. Salvador Allende Norte',
          centroSaludTelefono: '+56 9 1234 5678',
          contactoEmergenciaNombre: 'Carlos Eduardo Vejar Fuenzalida',
          contactoEmergenciaTelefono: '+56 9 8765 4321',
          creadoEn: DateTime.now(),
        ),
      );
      await tester.pumpWidget(_pantalla(auth, base, cifrado, const Perfil()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await _scrollHastaElFinal(tester);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('selector de síntomas abierto no desborda en 360x800', (
    tester,
  ) async {
    _viewportCompacto(tester, const Size(360, 800));
    final auth = _authConSesion();
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    final base = await _baseConCuidador(cifrado);
    await RepositorioPacientes(base).crearPaciente(
      Paciente(
        id: 'auto',
        nombreCompleto: 'Paciente Test',
        creadoEn: DateTime.now(),
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
}
