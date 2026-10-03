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
import 'package:oncuidar/caracteristicas/pacientes/dominio/ciclo_de_vida_paciente.dart';
import 'package:oncuidar/caracteristicas/recordatorios/datos/repositorio_recordatorios.dart';
import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
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
