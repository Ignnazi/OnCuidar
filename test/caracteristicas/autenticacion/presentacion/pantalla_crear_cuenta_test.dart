import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oncuidar/caracteristicas/autenticacion/datos/proveedores_autenticacion.dart';
import 'package:oncuidar/caracteristicas/autenticacion/datos/servicio_alta_cuenta.dart';
import 'package:oncuidar/caracteristicas/autenticacion/presentacion/pantalla_crear_cuenta.dart';
import 'package:oncuidar/caracteristicas/pacientes/datos/repositorio_pacientes.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/paciente.dart';
import 'package:oncuidar/caracteristicas/perfil/datos/repositorio_cuidador.dart';
import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
import 'package:oncuidar/nucleo/proveedores.dart';

const _clavePrueba = 'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';
const _uid = 'uid-test';

MockFirebaseAuth _authLimpio() => MockFirebaseAuth(
  mockUser: MockUser(uid: _uid, email: 'email@test.cl'),
);

ServicioCifrado _cifradoListo() => ServicioCifrado(clavePrueba: _clavePrueba);

Future<BaseDatosSegura> _crearBase(
  ServicioCifrado cifrado,
  MockFirebaseAuth auth,
) async {
  return BaseDatosSegura(
    base: FakeFirebaseFirestore(),
    auth: auth,
    cifrado: cifrado,
  );
}

Widget _pantalla(
  MockFirebaseAuth auth,
  BaseDatosSegura base,
  ServicioCifrado cifrado, {
  RepositorioCuidador? repositorioCuidador,
}) {
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
      baseDatosSeguraProvider.overrideWith((ref) => base),
      servicioRegistroProvider.overrideWith(
        (ref) => ServicioRegistro(
          auth: auth,
          cifrado: cifrado,
          repositorioPacientes: RepositorioPacientes(base),
          repositorioCuidador: repositorioCuidador ?? RepositorioCuidador(base),
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
  group('Datos inválidos bloquean el alta (CA-02.2)', () {
    Future<MockFirebaseAuth> montar(WidgetTester tester) async {
      await _pantallaAlta(tester);
      final auth = _authLimpio();
      final cifrado = _cifradoListo();
      final base = await _crearBase(cifrado, auth);
      await tester.pumpWidget(_pantalla(auth, base, cifrado));
      await tester.pumpAndSettle();
      return auth;
    }

    Future<void> guardar(WidgetTester tester) async {
      final boton = find.text('Guardar y continuar');
      await tester.ensureVisible(boton);
      await tester.pumpAndSettle();
      await tester.tap(boton);
      await tester.pumpAndSettle();
    }

    testWidgets('con campos vacíos se ven los errores y no se crea', (
      tester,
    ) async {
      final auth = await montar(tester);

      await guardar(tester);

      expect(find.text('Ingresa tu nombre'), findsOneWidget);
      expect(find.text('Ingresa tu correo'), findsWidgets);
      expect(find.text('Ingresa el RUT del paciente'), findsOneWidget);
      expect(auth.currentUser, isNull);
      expect(find.text('Dashboard'), findsNothing);
    });

    testWidgets('un correo inválido impide crear la cuenta', (tester) async {
      final auth = await montar(tester);
      await _rellenar(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'ana@correo.cl'),
        'ana@correo',
      );

      await guardar(tester);

      expect(find.text('Ingresa un correo válido'), findsOneWidget);
      expect(auth.currentUser, isNull);
      expect(find.text('Dashboard'), findsNothing);
    });

    testWidgets('un RUT inválido impide crear la cuenta', (tester) async {
      final auth = await montar(tester);
      await _rellenar(tester);
      await tester.enterText(
        find.widgetWithText(TextField, '15.844.829-7'),
        '158448290',
      );

      await guardar(tester);

      expect(find.text('RUT no válido'), findsOneWidget);
      expect(auth.currentUser, isNull);
      expect(find.text('Dashboard'), findsNothing);
    });
  });

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
    final base = await _crearBase(cifrado, auth);
    await tester.pumpWidget(
      _pantalla(
        auth,
        base,
        cifrado,
        repositorioCuidador: _RepositorioCuidadorFallido(base),
      ),
    );
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
    final base = BaseDatosSegura(base: firestore, auth: auth, cifrado: cifrado);
    await tester.pumpWidget(_pantalla(auth, base, cifrado));
    await tester.pumpAndSettle();

    await _rellenarConRelacionYFaseOtro(tester);

    await tester.tap(find.text('Guardar y continuar'));
    await tester.pumpAndSettle();

    expect(auth.currentUser, isNotNull);
    final uid = auth.currentUser!.uid;

    final datosUsuario = (await firestore.collection('usuarios').doc(uid).get())
        .data()!;
    final relacionCifrada = datosUsuario['relacion_cifrada'] as String;
    expect(await cifrado.descifrar(uid, relacionCifrada), 'Madrastra');

    final pacientes = await firestore
        .collection('usuarios')
        .doc(uid)
        .collection('pacientes')
        .get();
    final datosPaciente = pacientes.docs.single.data();
    final faseCifrada = datosPaciente['fase_tratamiento_cifrado'] as String;
    expect(await cifrado.descifrar(uid, faseCifrada), 'Terapia de mantención');
  });

  test(
    'registro con respaldo normaliza, llama al callable y NO escribe el hash',
    () async {
      final auth = _authLimpio();
      final cifrado = _cifradoListo();
      final base = FakeFirebaseFirestore();
      final baseDatos = BaseDatosSegura(
        base: base,
        auth: auth,
        cifrado: cifrado,
      );

      String? emailRegistrado;
      final servicio = ServicioRegistro(
        auth: auth,
        cifrado: cifrado,
        repositorioPacientes: RepositorioPacientes(baseDatos),
        repositorioCuidador: RepositorioCuidador(baseDatos),
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
            nombreCompleto: 'Paciente Ana',
            rut: '12.345.678-9',
            diagnostico: 'Cancer de mama',
            tratamientoFase: 'Tratamiento',
            creadoEn: DateTime.now(),
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
      final doc = (await base.collection('usuarios').doc(uidCreado).get())
          .data()!;
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

  test(
    'alta fallida borra primero el documento y después el usuario de Auth',
    () async {
      final eventos = <String>[];
      final auth = _AuthQueRegistra(eventos);
      final firestore = FakeFirebaseFirestore();
      final bd = BaseDatosSegura(
        base: firestore,
        auth: auth,
        cifrado: _cifradoListo(),
      );
      final servicio = ServicioRegistro(
        auth: auth,
        cifrado: _cifradoListo(),
        repositorioPacientes: _RepositorioPacientesQueFalla(bd),
        repositorioCuidador: _RepositorioCuidadorQueRegistra(
          bd,
          auth: auth,
          eventos: eventos,
        ),
        registrarCorreoRespaldo: (_) async {},
      );

      final resultado = await servicio.registrar(
        DatosRegistro(
          nombre: 'Ana Torres',
          correo: 'ana@correo.cl',
          telefono: '+56 9 1111 2222',
          relacion: 'Madre',
          contrasena: 'secreto123',
          paciente: Paciente(
            id: 'auto',
            nombreCompleto: 'Paciente Ana',
            creadoEn: DateTime.now(),
          ),
        ),
      );

      expect(resultado, isA<RegistroFallido>());
      expect(eventos, ['firestore', 'auth']);
      final usuarios = await firestore.collection('usuarios').get();
      expect(
        usuarios.docs,
        isEmpty,
        reason: 'el documento del alta fallida no debe quedar huérfano',
      );
    },
  );
}

class _RepositorioCuidadorFallido extends RepositorioCuidador {
  _RepositorioCuidadorFallido(super.bd);

  @override
  Future<void> crearCuidador(Map<String, dynamic> datos) async {
    throw Exception('fallo firestore');
  }
}

// ignore: must_be_immutable
class _UsuarioQueRegistra extends MockUser {
  _UsuarioQueRegistra({required super.uid, required this.alBorrar})
    : super(email: 'ana@correo.cl');

  final Future<void> Function() alBorrar;

  @override
  Future<void> delete() => alBorrar();
}

class _Credencial implements UserCredential {
  _Credencial(this.user);

  @override
  final User user;

  @override
  AdditionalUserInfo? get additionalUserInfo => null;

  @override
  AuthCredential? get credential => null;
}

class _AuthQueRegistra extends MockFirebaseAuth {
  _AuthQueRegistra(this.eventos);

  final List<String> eventos;

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await super.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _Credencial(
      _UsuarioQueRegistra(
        uid: currentUser!.uid,
        alBorrar: () async {
          eventos.add('auth');
          await signOut();
        },
      ),
    );
  }
}

class _RepositorioPacientesQueFalla extends RepositorioPacientes {
  _RepositorioPacientesQueFalla(super.bd);

  @override
  Future<String> crearPaciente(Paciente paciente) async {
    throw Exception('fallo firestore');
  }
}

class _RepositorioCuidadorQueRegistra extends RepositorioCuidador {
  _RepositorioCuidadorQueRegistra(
    super.bd, {
    required this.auth,
    required this.eventos,
  });

  final FirebaseAuth auth;
  final List<String> eventos;

  @override
  Future<void> limpiarRegistro(String uid) async {
    if (auth.currentUser == null) {
      eventos.add('firestore-sin-sesion');
      return;
    }
    eventos.add('firestore');
    await super.limpiarRegistro(uid);
  }
}
