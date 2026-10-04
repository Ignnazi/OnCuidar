import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/app/tema/tema.dart';
import 'package:oncuidar/caracteristicas/autenticacion/datos/proveedores_autenticacion.dart';
import 'package:oncuidar/caracteristicas/autenticacion/datos/servicio_alta_cuenta.dart';
import 'package:oncuidar/caracteristicas/autenticacion/presentacion/pantalla_crear_cuenta.dart';
import 'package:oncuidar/caracteristicas/autenticacion/presentacion/pantalla_iniciar_sesion.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/material_educativo.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/pantalla_biblioteca.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/proveedores_biblioteca.dart';
import 'package:oncuidar/caracteristicas/chat/presentacion/pantalla_chat.dart';
import 'package:oncuidar/caracteristicas/configuracion/dominio/escala_texto.dart';
import 'package:oncuidar/caracteristicas/configuracion/presentacion/seccion_configuracion.dart';
import 'package:oncuidar/caracteristicas/historial/presentacion/pantalla_historial.dart';
import 'package:oncuidar/caracteristicas/pacientes/datos/repositorio_pacientes.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/paciente.dart';
import 'package:oncuidar/caracteristicas/perfil/datos/repositorio_cuidador.dart';
import 'package:oncuidar/caracteristicas/perfil/presentacion/pantalla_perfil.dart';
import 'package:oncuidar/caracteristicas/preguntas_frecuentes/presentacion/pantalla_preguntas_frecuentes.dart';
import 'package:oncuidar/caracteristicas/recordatorios/datos/repositorio_recordatorios.dart';
import 'package:oncuidar/caracteristicas/recordatorios/dominio/recordatorio.dart';
import 'package:oncuidar/caracteristicas/recordatorios/presentacion/pantalla_recordatorios.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/datos/repositorio_registros_clinicos.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/presentacion/pantalla_registro_clinico.dart';
import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
import 'package:oncuidar/nucleo/proveedores.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _clavePrueba = 'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';
const _uid = 'uid-test';

const _viewports = [Size(360, 800), Size(320, 568)];

class _Entorno {
  _Entorno(this.auth, this.base, this.cifrado);

  final MockFirebaseAuth auth;
  final BaseDatosSegura base;
  final ServicioCifrado cifrado;
}

Future<_Entorno> _entorno() async {
  SharedPreferences.setMockInitialValues({});
  final auth = MockFirebaseAuth(
    mockUser: MockUser(uid: _uid, email: 'ana@correo.cl'),
  );
  final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
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
  final fecha = DateTime.now();
  final idPaciente = await RepositorioPacientes(base).crearPaciente(
    Paciente(
      id: 'auto',
      nombreCompleto: 'Anastasia Margarita Constanza del Carmen',
      rut: '25.123.456-7',
      edad: 8,
      diagnostico: 'Leucemia linfoblástica aguda de riesgo estándar',
      tratamientoFase: 'Quimioterapia de mantención ambulatoria',
      centroSaludNombre: 'Centro de Salud Familiar Dr. Salvador Allende Norte',
      centroSaludTelefono: '+56 9 1234 5678',
      contactoEmergenciaNombre: 'Carlos Eduardo Vejar Fuenzalida',
      contactoEmergenciaTelefono: '+56 9 8765 4321',
      creadoEn: fecha,
    ),
  );
  await RepositorioRecordatorios(base).agregarRecordatorio(
    idPaciente,
    Recordatorio(
      id: '',
      pacienteId: idPaciente,
      tipo: 'medicamento',
      titulo: 'Tomar paracetamol de 500 mg junto con una cena ligera',
      descripcion:
          'Recordatorio muy largo sobre la medicación para comprobar que el '
          'texto con elipsis no desborda en pantallas pequeñas.',
      fechaHora: fecha,
      diasRepeticion: const ['lun', 'mar', 'mie', 'jue', 'vie', 'sab', 'dom'],
      activo: true,
      creadoEn: fecha,
    ),
  );
  await RepositorioRegistrosClinicos(base).guardarRegistroClinico(
    idPaciente,
    RegistroClinico(
      id: 'detalle',
      pacienteId: idPaciente,
      fecha: fecha,
      creadoEn: fecha,
      tipoRegistro: 'programado',
      signosVitales: const SignosVitales(
        temperatura: 40,
        frecuenciaCardiaca: 120,
        saturacionOxigeno: 88,
        frecuenciaRespiratoria: 24,
      ),
      sintomas: const [EntradaSintoma(nombre: 'Fiebre', intensidad: 9)],
      observaciones:
          'Paciente con observaciones muy largas para comprobar que el '
          'detalle no se desborda horizontalmente en pantallas pequeñas.',
      nivelAlerta: NivelAlerta.critico,
    ),
  );
  return _Entorno(auth, base, cifrado);
}

final _materiales = [
  for (final (indice, categoria) in ['Videos', 'Guías', 'Infografías'].indexed)
    MaterialEducativo(
      id: 'material-$indice',
      titulo:
          'Cómo cuidar el catéter central en casa paso a paso y sin errores',
      categoria: categoria,
      tema: 'Cuidados generales del paciente oncológico pediátrico',
      cuerpo: 'Texto de apoyo.',
      creadoEn: DateTime.utc(2026, 1, 1),
    ),
];

Widget _app(_Entorno entorno, Widget inicio, double factor) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (c, s) => inicio),
      GoRoute(
        path: '/bienvenida',
        builder: (c, s) => const Scaffold(body: Text('Bienvenida')),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (c, s) => const Scaffold(body: Text('Dashboard')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      firebaseAuthProvider.overrideWithValue(entorno.auth),
      servicioCifradoProvider.overrideWithValue(entorno.cifrado),
      baseDatosSeguraProvider.overrideWith((ref) => entorno.base),
      contenidosEducativosProvider.overrideWith(
        (_) => Stream.value(_materiales),
      ),
      servicioRegistroProvider.overrideWith(
        (ref) => ServicioRegistro(
          auth: entorno.auth,
          cifrado: entorno.cifrado,
          repositorioPacientes: RepositorioPacientes(entorno.base),
          repositorioCuidador: RepositorioCuidador(entorno.base),
          alDesbloquear: () =>
              ref.read(bloqueoCifradoProvider.notifier).fijarDesbloqueado(true),
          registrarCorreoRespaldo: (email) async {},
        ),
      ),
    ],
    child: MaterialApp.router(
      theme: Tema.obtener(),
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(factor)),
        child: child!,
      ),
    ),
  );
}

Future<void> _alFinal(WidgetTester tester) async {
  final lista = find.byType(Scrollable);
  if (lista.evaluate().isEmpty) return;
  await tester.drag(lista.first, const Offset(0, -4000));
  await tester.pumpAndSettle();
}

final _errores = <String>[];

Future<void> _conDeteccion(Future<void> Function() cuerpo) async {
  final previo = FlutterError.onError;
  _errores.clear();
  FlutterError.onError = (d) => _errores.add(d.toString());
  try {
    await cuerpo();
  } finally {
    FlutterError.onError = previo;
    _errores.clear();
  }
}

Future<void> _verificar(WidgetTester tester, String donde) async {
  tester.takeException();
  if (_errores.isEmpty) return;
  final detalle = _errores.join('\n---\n');
  _errores.clear();
  fail('Desborde o error en: $donde\n$detalle');
}

final _casos =
    <(String, Widget Function(), Future<void> Function(WidgetTester))>[
      (
        'registro',
        () => const Registro(),
        (t) async {
          await _alFinal(t);
        },
      ),
      (
        'iniciar sesión',
        () => const IniciarSesion(),
        (t) async {
          await _alFinal(t);
        },
      ),
      (
        'perfil',
        () => const Perfil(),
        (t) async {
          await _verificar(t, 'perfil / pacientes');
          await _alFinal(t);
          await _verificar(t, 'perfil / pacientes (final)');
          await t.tap(find.text('Mi perfil'));
          await t.pumpAndSettle();
          await _alFinal(t);
          await _verificar(t, 'mi perfil (final)');
          final abrir = find.byKey(const Key('abrirConfiguracion'));
          await t.ensureVisible(abrir);
          await t.pumpAndSettle();
          await t.tap(abrir);
          await t.pumpAndSettle();
          await _verificar(t, 'hoja de configuración');
          await t.drag(
            find.byType(SingleChildScrollView).last,
            const Offset(0, -2000),
          );
          await t.pumpAndSettle();
        },
      ),
      (
        'registro clínico',
        () => const RegistroClinicoScreen(),
        (t) async {
          await _alFinal(t);
        },
      ),
      (
        'historial',
        () => const HistorialScreen(),
        (t) async {
          final tarjeta = find.text('Click para ver registro completo');
          await t.ensureVisible(tarjeta);
          await t.tap(tarjeta);
          await t.pumpAndSettle();
          await _alFinal(t);
        },
      ),
      (
        'recordatorios',
        () => const RecordatoriosScreen(),
        (t) async {
          await _verificar(t, 'recordatorios');
          await _alFinal(t);
          await _verificar(t, 'recordatorios (final)');
          await t.tap(find.byKey(const Key('tarjetaRapida_medicamento')));
          await t.pumpAndSettle();
          await _verificar(t, 'formulario de recordatorio');
          await t.drag(
            find.byType(SingleChildScrollView).last,
            const Offset(0, -4000),
          );
          await t.pumpAndSettle();
        },
      ),
      (
        'chat',
        () => const ChatScreen(),
        (t) async {
          await _verificar(t, 'chat inicial');
          await t.tap(find.byKey(const Key('sugerencia_fiebre')));
          await t.pump(const Duration(milliseconds: 1000));
          await t.pumpAndSettle();
          await _verificar(t, 'chat con respuesta');
          await t.tap(find.byKey(const Key('botonConversacionesChat')));
          await t.pumpAndSettle();
        },
      ),
      (
        'preguntas frecuentes',
        () => const FaqScreen(),
        (t) async {
          await _verificar(t, 'preguntas frecuentes');
          await t.tap(find.byKey(const Key('faq_fiebre')));
          await t.pumpAndSettle();
          await _alFinal(t);
        },
      ),
      (
        'biblioteca',
        () => const BibliotecaScreen(),
        (t) async {
          await _alFinal(t);
        },
      ),
      (
        'configuración',
        () => const Scaffold(
          body: SingleChildScrollView(child: SeccionConfiguracion()),
        ),
        (t) async {
          await _alFinal(t);
        },
      ),
    ];

void main() {
  for (final escala in EscalaTexto.values) {
    for (final tamano in _viewports) {
      for (final (nombre, pantalla, accion) in _casos) {
        testWidgets('$nombre · texto ${escala.etiqueta} · '
            '${tamano.width.toInt()}x${tamano.height.toInt()}', (tester) async {
          tester.view.physicalSize = tamano;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final entorno = await _entorno();

          await _conDeteccion(() async {
            await tester.pumpWidget(_app(entorno, pantalla(), escala.factor));
            await tester.pumpAndSettle();
            await _verificar(tester, '$nombre al abrir');

            await accion(tester);
            await _verificar(tester, nombre);
          });
        });
      }
    }
  }

  group('modo oscuro', () {
    setUp(() => Paleta.usar(coloresOscuros));
    tearDown(() => Paleta.usar(coloresClaros));

    for (final (nombre, pantalla, accion) in _casos) {
      testWidgets('$nombre · oscuro · Muy grande · 320x568', (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final entorno = await _entorno();

        await _conDeteccion(() async {
          await tester.pumpWidget(
            _app(entorno, pantalla(), EscalaTexto.muyGrande.factor),
          );
          await tester.pumpAndSettle();
          await _verificar(tester, '$nombre al abrir (oscuro)');
          final fondo = tester
              .widgetList<Scaffold>(find.byType(Scaffold))
              .first
              .backgroundColor;
          expect(
            fondo,
            anyOf(isNull, coloresOscuros.crema),
            reason: 'el fondo de $nombre debe ser el oscuro',
          );

          await accion(tester);
          await _verificar(tester, '$nombre (oscuro)');
        });
      });
    }
  });

  testWidgets('el detector falla ante un desborde real', (tester) async {
    await _conDeteccion(() async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: SizedBox(
              width: 100,
              child: Row(children: [SizedBox(width: 300, height: 10)]),
            ),
          ),
        ),
      );
      await expectLater(
        _verificar(tester, 'fila forzada'),
        throwsA(isA<TestFailure>()),
      );
    });
  });
}
