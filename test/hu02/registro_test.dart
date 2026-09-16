import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oncuidar/caracteristicas/onboarding/registro.dart';
import 'package:oncuidar/core/proveedores/proveedores.dart';
import 'package:oncuidar/core/servicios/servicio_base_datos.dart';
import 'package:oncuidar/core/servicios/servicio_cifrado.dart';
import 'package:oncuidar/core/servicios/servicio_registro.dart';
import 'package:oncuidar/modelos/paciente.dart';

const _clavePrueba = 'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';
const _uid = 'uid-test';

MockFirebaseAuth _authLimpio() => MockFirebaseAuth(
  mockUser: MockUser(uid: _uid, email: 'email@test.cl'),
);

ServicioCifrado _cifradoListo() => ServicioCifrado(clavePrueba: _clavePrueba);

Future<ServicioBaseDatos> _crearBase(
  ServicioCifrado cifrado,
  MockFirebaseAuth auth, {
  bool falla = false,
}) async {
  if (falla) return _ServicioFallido(cifrado: cifrado);
  return ServicioBaseDatos(
    base: FakeFirebaseFirestore(),
    auth: auth,
    cifrado: cifrado,
  );
}

Widget _pantalla(
  MockFirebaseAuth auth,
  ServicioBaseDatos base,
  ServicioCifrado cifrado,
) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const Registro()),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Dashboard'))),
      ),
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

Future<void> _pantallaAlta(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _rellenar(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextField, 'Nombre completo').first,
    'Ana Torres',
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'correo@ejemplo.com'),
    'ana@correo.cl',
  );
  await tester.enterText(
    find.widgetWithText(TextField, '+56 9 0000 0000'),
    '+56 9 1111 2222',
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'Dirección del cuidador'),
    'Av. Siempre Viva 123',
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'Para recuperar tu contraseña'),
    'respaldo@correo.cl',
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'Mínimo 6 caracteres'),
    'secreto123',
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'Repite tu contraseña'),
    'secreto123',
  );

  await tester.tap(find.byType(DropdownButtonFormField<String>).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Madre').last);
  await tester.pumpAndSettle();

  await tester.enterText(
    find.widgetWithText(TextField, 'Nombre completo').last,
    'Paciente Ana',
  );
  await tester.enterText(
    find.widgetWithText(TextField, '12.345.678-9'),
    '158448297',
  );
  await tester.enterText(find.widgetWithText(TextField, 'Años'), '12');
  await tester.enterText(
    find.widgetWithText(TextField, 'Tipo de cáncer / diagnóstico'),
    'Cancer de mama',
  );

  await tester.ensureVisible(
    find.byType(DropdownButtonFormField<String>).at(1),
  );
  await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Tratamiento').last);
  await tester.pumpAndSettle();

  await tester.enterText(
    find.widgetWithText(TextField, 'Nombre del centro'),
    'Hospital Clínico',
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'Dirección del centro'),
    'Av. Salud 456',
  );
  await tester.enterText(
    find.widgetWithText(TextField, '+56 2 0000 0000').first,
    '2 2123 4000',
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'Nombre de la persona'),
    'Juan Pérez',
  );
  await tester.enterText(
    find.widgetWithText(TextField, '+56 2 0000 0000').last,
    '2 2998 7654',
  );
}

Future<void> _rellenarConRelacionYFaseOtro(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextField, 'Nombre completo').first,
    'Ana Torres',
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'correo@ejemplo.com'),
    'ana@correo.cl',
  );
  await tester.enterText(
    find.widgetWithText(TextField, '+56 9 0000 0000'),
    '+56 9 1111 2222',
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'Dirección del cuidador'),
    'Av. Siempre Viva 123',
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'Para recuperar tu contraseña'),
    'respaldo@correo.cl',
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'Mínimo 6 caracteres'),
    'secreto123',
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'Repite tu contraseña'),
    'secreto123',
  );

  await tester.tap(find.byType(DropdownButtonFormField<String>).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Otro').last);
  await tester.pumpAndSettle();
  await tester.enterText(
    find.widgetWithText(TextField, 'Ej: Madrastra, Abuelo(a), Hermano(a)'),
    'Madrastra',
  );

  await tester.enterText(
    find.widgetWithText(TextField, 'Nombre completo').last,
    'Paciente Ana',
  );
  await tester.enterText(
    find.widgetWithText(TextField, '12.345.678-9'),
    '158448297',
  );
  await tester.enterText(find.widgetWithText(TextField, 'Años'), '12');
  await tester.enterText(
    find.widgetWithText(TextField, 'Tipo de cáncer / diagnóstico'),
    'Cancer de mama',
  );

  await tester.ensureVisible(
    find.byType(DropdownButtonFormField<String>).at(1),
  );
  await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Otro').last);
  await tester.pumpAndSettle();
  await tester.enterText(
    find.widgetWithText(TextField, 'Ej: Terapia de mantención, Control'),
    'Terapia de mantención',
  );

  await tester.enterText(
    find.widgetWithText(TextField, 'Nombre del centro'),
    'Hospital Clínico',
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'Dirección del centro'),
    'Av. Salud 456',
  );
  await tester.enterText(
    find.widgetWithText(TextField, '+56 2 0000 0000').first,
    '2 2123 4000',
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'Nombre de la persona'),
    'Juan Pérez',
  );
  await tester.enterText(
    find.widgetWithText(TextField, '+56 2 0000 0000').last,
    '2 2998 7654',
  );
}

void main() {
  testWidgets('registro crea cuenta, guarda y redirige', (tester) async {
    await _pantallaAlta(tester);
    final auth = _authLimpio();
    final cifrado = _cifradoListo();
    final base = await _crearBase(cifrado, auth);
    await tester.pumpWidget(_pantalla(auth, base, cifrado));
    await tester.pumpAndSettle();

    await _rellenar(tester);

    await tester.tap(find.text('Guardar y continuar'));
    await tester.pumpAndSettle();

    expect(auth.currentUser, isNotNull);
    expect(auth.currentUser!.email, 'ana@correo.cl');
    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets('fallo en Firestore corta el flujo y no navega', (tester) async {
    await _pantallaAlta(tester);
    final auth = _authLimpio();
    final cifrado = _cifradoListo();
    final base = await _crearBase(cifrado, auth, falla: true);
    await tester.pumpWidget(_pantalla(auth, base, cifrado));
    await tester.pumpAndSettle();

    await _rellenar(tester);

    await tester.tap(find.text('Guardar y continuar'));
    await tester.pumpAndSettle();

    expect(
      find.text('Dashboard'),
      findsNothing,
      reason: 'fallo en Firestore impide navegar',
    );
    expect(find.text('Error inesperado. Intenta de nuevo.'), findsOneWidget);
  });

  testWidgets('relación y fase personalizadas guardan el texto libre', (
    tester,
  ) async {
    await _pantallaAlta(tester);
    final auth = _authLimpio();
    final cifrado = _cifradoListo();
    final firestore = FakeFirebaseFirestore();
    final base = ServicioBaseDatos(
      base: firestore,
      auth: auth,
      cifrado: cifrado,
    );
    await tester.pumpWidget(_pantalla(auth, base, cifrado));
    await tester.pumpAndSettle();

    await _rellenarConRelacionYFaseOtro(tester);

    await tester.tap(find.text('Guardar y continuar'));
    await tester.pumpAndSettle();

    expect(auth.currentUser, isNotNull);
    final uid = auth.currentUser!.uid;

    final userData = (await firestore.collection('users').doc(uid).get())
        .data()!;
    final relacionCifrada = userData['relacion_cifrada'] as String;
    expect(await cifrado.descifrar(uid, relacionCifrada), 'Madrastra');

    final patients = await firestore
        .collection('users')
        .doc(uid)
        .collection('patients')
        .get();
    final patientData = patients.docs.single.data();
    final faseCifrada = patientData['fase_tratamiento_cifrado'] as String;
    expect(await cifrado.descifrar(uid, faseCifrada), 'Terapia de mantención');
  });

  test(
    'registro con respaldo normaliza, llama al callable y NO escribe el hash',
    () async {
      final auth = _authLimpio();
      final cifrado = _cifradoListo();
      final base = FakeFirebaseFirestore();
      final baseDatos = ServicioBaseDatos(
        base: base,
        auth: auth,
        cifrado: cifrado,
      );

      String? emailRegistrado;
      final servicio = ServicioRegistro(
        auth: auth,
        cifrado: cifrado,
        baseDatos: baseDatos,
        registrarCorreoRespaldo: (email) async => emailRegistrado = email,
      );

      final resultado = await servicio.registrar(
        DatosRegistro(
          nombre: 'Ana Torres',
          correo: 'ana@correo.cl',
          telefono: '+56 9 1111 2222',
          relacion: 'Madre',
          correoRespaldo: '  Respaldo@Ejemplo.cl ',
          contrasena: 'secreto123',
          paciente: Paciente(
            id: 'auto',
            fullName: 'Paciente Ana',
            rut: '12.345.678-9',
            diagnosis: 'Cancer de mama',
            tratamientoFase: 'Tratamiento',
            createdAt: DateTime.now(),
          ),
        ),
      );

      expect(resultado, isA<RegistroExitoso>());
      expect(
        emailRegistrado,
        'respaldo@ejemplo.cl',
        reason: 'el respaldo se normaliza en minúsculas antes del callable',
      );
      final uidCreado = auth.currentUser!.uid;
      final doc = (await base.collection('users').doc(uidCreado).get()).data()!;
      expect(
        doc.containsKey('correo_respaldo_hash'),
        isFalse,
        reason: 'el cliente nunca escribe el hash; lo registra el servidor',
      );
      final cifradoRespaldo = doc['correo_respaldo_cifrado'] as String;
      expect(
        await cifrado.descifrar(uidCreado, cifradoRespaldo),
        'respaldo@ejemplo.cl',
      );
    },
  );
}

class _ServicioFallido extends ServicioBaseDatos {
  _ServicioFallido({required super.cifrado})
    : super(base: FakeFirebaseFirestore(), uidPrueba: _uid);

  @override
  Future<void> crearCuidador(Map<String, dynamic> datos) async {
    throw Exception('fallo firestore');
  }
}
