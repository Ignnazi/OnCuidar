import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oncuidar/app/enrutador/destino_aviso.dart';
import 'package:oncuidar/caracteristicas/autenticacion/presentacion/pantalla_carga.dart';
import 'package:oncuidar/caracteristicas/biblioteca/datos/proveedores_biblioteca.dart';
import 'package:oncuidar/caracteristicas/biblioteca/datos/servicio_cache_contenido.dart';
import 'package:oncuidar/caracteristicas/pacientes/datos/repositorio_pacientes.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/ciclo_de_vida_paciente.dart';
import 'package:oncuidar/caracteristicas/recordatorios/datos/repositorio_recordatorios.dart';
import 'package:oncuidar/caracteristicas/recordatorios/dominio/recordatorio.dart';
import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
import 'package:oncuidar/nucleo/notificaciones/servicio_notificaciones.dart';
import 'package:oncuidar/nucleo/proveedores.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../ayudas/ciclo_de_vida.dart';
import '../../../ayudas/recordatorios.dart';

class _AvisosQueFallan extends NotificacionesFalsas {
  @override
  Future<bool> solicitarPermiso() async {
    permisoSolicitado++;
    return false;
  }

  @override
  Future<void> programar({
    required int id,
    required String titulo,
    required String cuerpo,
    required DateTime fechaHora,
    List<String>? diasRepeticion,
    bool mensual = false,
    String? idPaciente,
  }) async {
    throw StateError('plugin_local_notifications no disponible');
  }

  @override
  Future<void> cancelarTodas() async {
    canceladasTodas++;
    throw StateError('plugin_local_notifications no disponible');
  }
}

class _CacheFalso implements ServicioCacheContenido {
  @override
  Future<File?> archivoEnCache(String url) async => null;

  @override
  Future<File> descargar(String url) async => File(url);

  @override
  Future<bool> archivoDescargado(String url) async => false;

  @override
  Future<void> eliminar(String url) async {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    EstadoArranque.reiniciar();
  });
  tearDown(EstadoArranque.reiniciar);

  group('reagendarNotificaciones sin soporte de avisos', () {
    test('no propaga el fallo del plugin ni al cancelar', () async {
      final (base, _) = await baseRecordatorios();
      final idPaciente = await crearPacienteRecordatorios(base);
      await RepositorioRecordatorios(
        base,
      ).agregarRecordatorio(idPaciente, recordatorioDe(idPaciente));
      final notif = _AvisosQueFallan();

      await expectLater(
        cicloDeVida(base, notif).reagendarNotificaciones(),
        completes,
      );
      expect(notif.canceladasTodas, 1);
      expect(notif.programados, isEmpty);
    });
  });

  group('reagendarNotificaciones sin clave de datos', () {
    test('no lanza ni programa avisos ilegibles', () async {
      final (baseOrigen, firestore) = await baseRecordatorios();
      final idPaciente = await crearPacienteRecordatorios(baseOrigen);
      await RepositorioRecordatorios(baseOrigen).agregarRecordatorio(
        idPaciente,
        recordatorioDe(idPaciente, titulo: 'Tomar jarabe'),
      );
      final baseSinClave = BaseDatosSegura(
        base: firestore,
        uidPrueba: uidRecordatorios,
        cifrado: ServicioCifrado(clavePrueba: clavePruebaRecordatorios),
      );
      final notif = NotificacionesFalsas();

      await expectLater(
        cicloDeVida(baseSinClave, notif).reagendarNotificaciones(),
        completes,
      );
      expect(notif.programados, isEmpty);
    });
  });

  group('reagendarAvisosEnSegundoPlano', () {
    test('traga el fallo del servicio de avisos', () async {
      final (base, _) = await baseRecordatorios();
      final idPaciente = await crearPacienteRecordatorios(base);
      await RepositorioRecordatorios(
        base,
      ).agregarRecordatorio(idPaciente, recordatorioDe(idPaciente));

      reagendarAvisosEnSegundoPlano(cicloDeVida(base, _AvisosQueFallan()));
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });

    test('traga el fallo de la base de datos', () async {
      reagendarAvisosEnSegundoPlano(
        cicloDeVida(
          _BaseSinDocumentos(firestore: FakeFirebaseFirestore()),
          NotificacionesFalsas(),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
  });

  group('El Splash no queda bloqueado por los avisos', () {
    testWidgets('con sesión y plugin caído igual entra al panel', (
      tester,
    ) async {
      final (base, _) = await baseRecordatorios();
      final idPaciente = await crearPacienteRecordatorios(base);
      await RepositorioRecordatorios(
        base,
      ).agregarRecordatorio(idPaciente, recordatorioDe(idPaciente));
      final notif = _AvisosQueFallan();

      await tester.pumpWidget(
        _appSplash([
          firebaseAuthProvider.overrideWithValue(
            MockFirebaseAuth(
              signedIn: true,
              mockUser: MockUser(uid: uidRecordatorios),
            ),
          ),
          servicioCifradoProvider.overrideWithValue(
            ServicioCifrado(clavePrueba: clavePruebaRecordatorios),
          ),
          baseDatosSeguraProvider.overrideWith((_) => base),
          servicioNotificacionesProvider.overrideWithValue(notif),
          servicioCacheContenidoProvider.overrideWithValue(_CacheFalso()),
        ]),
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Dashboard'), findsOneWidget);
      expect(EstadoArranque.completado, isTrue);
      expect(tester.takeException(), isNull);
    });
  });

  group('reagendarNotificaciones', () {
    test('no reprograma uno de una sola vez que ya venció', () async {
      final (base, _) = await baseRecordatorios();
      final idPaciente = await crearPacienteRecordatorios(base);
      await RepositorioRecordatorios(base).agregarRecordatorio(
        idPaciente,
        recordatorioDe(
          idPaciente,
          titulo: 'Vencido',
          fechaHora: DateTime.now().subtract(const Duration(days: 1)),
        ),
      );
      await RepositorioRecordatorios(base).agregarRecordatorio(
        idPaciente,
        recordatorioDe(idPaciente, titulo: 'Vigente'),
      );
      final notif = NotificacionesFalsas();
      await cicloDeVida(base, notif).reagendarNotificaciones();
      expect(notif.programados.map((p) => p['cuerpo']), ['Vigente']);
    });

    test('el aviso incluye la descripción y nombra al cuidador', () async {
      final (base, _) = await baseRecordatorios();
      final idPaciente = await crearPacienteRecordatorios(base);
      await RepositorioRecordatorios(base).agregarRecordatorio(
        idPaciente,
        recordatorioDe(
          idPaciente,
          titulo: 'Control',
          descripcion: 'Llevar exámenes',
          asignadoA: Recordatorio.asignadoACuidador,
        ),
      );
      final notif = NotificacionesFalsas();
      await cicloDeVida(base, notif).reagendarNotificaciones();
      expect(notif.programados.single['cuerpo'], 'Control · Llevar exámenes');
      expect(notif.programados.single['titulo'], 'Cuidador · Medicamento');
    });

    test(
      'reagendarNotificaciones cancela todo y reprograma solo activos',
      () async {
        final (base, _) = await baseRecordatorios();
        final idPaciente = await crearPacienteRecordatorios(base);
        final fecha = DateTime(2026, 9, 21, 9, 0);
        await RepositorioRecordatorios(base).agregarRecordatorio(
          idPaciente,
          Recordatorio(
            id: '',
            pacienteId: idPaciente,
            tipo: 'medicamento',
            titulo: 'Diario',
            fechaHora: fecha,
            diasRepeticion: const ['lun', 'mie'],
            activo: true,
            creadoEn: fecha,
          ),
        );
        await RepositorioRecordatorios(base).agregarRecordatorio(
          idPaciente,
          Recordatorio(
            id: '',
            pacienteId: idPaciente,
            tipo: 'cita',
            titulo: 'Control del mes',
            fechaHora: fecha,
            activo: true,
            creadoEn: fecha,
            recurrencia: 'mensual',
          ),
        );
        await RepositorioRecordatorios(base).agregarRecordatorio(
          idPaciente,
          Recordatorio(
            id: '',
            pacienteId: idPaciente,
            tipo: 'otro',
            titulo: 'Apagado',
            fechaHora: fecha,
            activo: false,
            creadoEn: fecha,
          ),
        );
        final notif = NotificacionesFalsas();
        await cicloDeVida(base, notif).reagendarNotificaciones();

        expect(notif.canceladasTodas, 1);
        expect(notif.programados, hasLength(2));
        expect(notif.programados.map((p) => p['mensual']).toSet(), {
          false,
          true,
        });
        expect(notif.programados.map((p) => p['titulo']).toSet(), {
          'Paciente Test · Medicamento',
          'Paciente Test · Cita médica',
        });
      },
    );
  });

  group('Avisos al archivar, restaurar y eliminar un paciente', () {
    test('archivar cancela los avisos de sus recordatorios', () async {
      final (base, _) = await baseRecordatorios();
      final idPaciente = await crearPacienteRecordatorios(base);
      final id1 = await RepositorioRecordatorios(base).agregarRecordatorio(
        idPaciente,
        recordatorioDe(idPaciente, titulo: 'Uno'),
      );
      final id2 = await RepositorioRecordatorios(base).agregarRecordatorio(
        idPaciente,
        recordatorioDe(idPaciente, titulo: 'Dos'),
      );
      final notif = NotificacionesFalsas();
      await cicloDeVida(base, notif).archivar(idPaciente);
      expect(
        notif.cancelados,
        containsAll([
          ServicioNotificaciones.idSeguro(id1),
          ServicioNotificaciones.idSeguro(id2),
        ]),
      );
    });

    test('archivar no toca los avisos de otro paciente', () async {
      final (base, _) = await baseRecordatorios();
      final a = await crearPacienteRecordatorios(base, nombre: 'Paciente A');
      final b = await crearPacienteRecordatorios(base, nombre: 'Paciente B');
      await RepositorioRecordatorios(
        base,
      ).agregarRecordatorio(a, recordatorioDe(a, titulo: 'De A'));
      final idB = await RepositorioRecordatorios(
        base,
      ).agregarRecordatorio(b, recordatorioDe(b, titulo: 'De B'));
      final notif = NotificacionesFalsas();
      await cicloDeVida(base, notif).archivar(a);
      expect(
        notif.cancelados,
        isNot(contains(ServicioNotificaciones.idSeguro(idB))),
      );
    });

    test('restaurar vuelve a programar los avisos', () async {
      final (base, _) = await baseRecordatorios();
      final idPaciente = await crearPacienteRecordatorios(base);
      await RepositorioRecordatorios(base).agregarRecordatorio(
        idPaciente,
        recordatorioDe(idPaciente, titulo: 'Jarabe'),
      );
      await RepositorioPacientes(base).archivarPaciente(idPaciente);
      final notif = NotificacionesFalsas();
      await cicloDeVida(base, notif).desarchivar(idPaciente);
      expect(notif.programados.map((p) => p['cuerpo']), ['Jarabe']);
    });

    test('un paciente archivado no se reprograma al iniciar sesión', () async {
      final (base, _) = await baseRecordatorios();
      final idPaciente = await crearPacienteRecordatorios(base);
      await RepositorioRecordatorios(base).agregarRecordatorio(
        idPaciente,
        recordatorioDe(idPaciente, titulo: 'Jarabe'),
      );
      await RepositorioPacientes(base).archivarPaciente(idPaciente);
      final notif = NotificacionesFalsas();
      await cicloDeVida(base, notif).reagendarNotificaciones();
      expect(notif.programados, isEmpty);
    });

    test('eliminar cancela los avisos antes de borrar al paciente', () async {
      final (base, _) = await baseRecordatorios();
      final idPaciente = await crearPacienteRecordatorios(base);
      final id = await RepositorioRecordatorios(
        base,
      ).agregarRecordatorio(idPaciente, recordatorioDe(idPaciente));
      final notif = NotificacionesFalsas();
      await cicloDeVida(base, notif).eliminar(idPaciente);
      expect(notif.cancelados, contains(ServicioNotificaciones.idSeguro(id)));
      expect(
        await RepositorioPacientes(base).pacientesEnTiempoReal().first,
        isEmpty,
      );
    });
  });
}

class _BaseSinDocumentos extends BaseDatosSegura {
  _BaseSinDocumentos({required FakeFirebaseFirestore firestore})
    : super(
        base: firestore,
        uidPrueba: uidRecordatorios,
        cifrado: ServicioCifrado(clavePrueba: clavePruebaRecordatorios),
      );
}

Widget _appSplash(List<Override> overrides) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (c, s) => Splash(alFinalizar: () => c.go('/bienvenida')),
      ),
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
    overrides: overrides,
    child: MaterialApp.router(routerConfig: router),
  );
}
