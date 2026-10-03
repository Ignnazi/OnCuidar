import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/perfil/perfil.dart';
import 'package:oncuidar/caracteristicas/recordatorios/recordatorios.dart';
import 'package:oncuidar/core/proveedores/proveedores.dart';
import 'package:oncuidar/core/servicios/cola_escrituras.dart';
import 'package:oncuidar/core/servicios/orquestador_sincronizacion.dart';
import 'package:oncuidar/core/servicios/servicio_base_datos.dart';
import 'package:oncuidar/core/servicios/servicio_cifrado.dart';
import 'package:oncuidar/modelos/recordatorio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ayudas_offline.dart';

const _clavePrueba = 'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';
const _uid = 'uid-orden';

class _Entorno {
  _Entorno(this.firestore, this.cola, this.red, this.base, this.orquestador);

  final FakeFirebaseFirestore firestore;
  final ColaEscrituras cola;
  final ConectividadFalsa red;
  final ServicioBaseDatos base;
  final OrquestadorSincronizacion orquestador;

  CollectionReference<Map<String, dynamic>> coleccion(String nombre) =>
      firestore
          .collection('users')
          .doc(_uid)
          .collection('patients')
          .doc('p1')
          .collection(nombre);
}

Future<_Entorno> _crearEntorno({bool enLinea = true}) async {
  SharedPreferences.setMockInitialValues({});
  final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
  await cifrado.fijarClave(_uid, _clavePrueba);
  final firestore = FakeFirebaseFirestore();
  final cola = ColaEscrituras();
  final red = ConectividadFalsa(enLinea: enLinea);
  final base = ServicioBaseDatos(
    base: firestore,
    uidPrueba: _uid,
    cifrado: cifrado,
    cola: cola,
    conectividad: red,
  );
  final orquestador = OrquestadorSincronizacion(
    cola: cola,
    base: base,
    conectividad: red,
    uidActual: () => _uid,
    retardoBase: const Duration(milliseconds: 1),
  );
  addTearDown(orquestador.dispose);
  return _Entorno(firestore, cola, red, base, orquestador);
}

Recordatorio _recordatorio(String titulo, {String paciente = 'p1'}) =>
    Recordatorio(
      id: '',
      pacienteId: paciente,
      tipo: 'medicamento',
      titulo: titulo,
      fechaHora: DateTime(2026, 10, 1, 8),
      creadoEn: DateTime(2026, 10, 1),
    );

void main() {
  group('Un borrado nunca se deshace al sincronizar', () {
    test('crear sin red, volver la red y borrar antes de drenar', () async {
      final ent = await _crearEntorno(enLinea: false);
      final id = await ent.base.agregarRecordatorio('p1', _recordatorio('A'));

      ent.red.fijar(true);
      await ent.base.eliminarRecordatorio('p1', id);

      final cola = await ent.cola.pendientes(_uid);
      expect(cola.map((e) => e.operacion), [
        OperacionPendiente.crear,
        OperacionPendiente.borrar,
      ]);

      await ent.orquestador.drenar();

      expect(
        (await ent.coleccion('recordatorios').doc(id).get()).exists,
        isFalse,
        reason: 'el borrado va detrás del crear y gana',
      );
      expect(await ent.cola.pendientes(_uid), isEmpty);
    });

    test(
      'editar un documento ya borrado en el servidor no lo revive',
      () async {
        final ent = await _crearEntorno();
        final id = await ent.base.agregarRecordatorio('p1', _recordatorio('Turno'));
        await ent.coleccion('recordatorios').doc(id).delete();

        await ent.base.actualizarRecordatorio('p1', id, activo: false);

        expect(
          (await ent.coleccion('recordatorios').doc(id).get()).exists,
          isFalse,
        );
      },
    );

    test(
      'una actualización encolada de un documento borrado se descarta',
      () async {
        final ent = await _crearEntorno();
        final id = await ent.base.agregarRecordatorio('p1', _recordatorio('Turno'));
        ent.red.fijar(false);
        await ent.base.actualizarRecordatorio('p1', id, activo: false);
        await ent.coleccion('recordatorios').doc(id).delete();

        ent.red.fijar(true);
        await ent.orquestador.drenar();

        expect(
          (await ent.coleccion('recordatorios').doc(id).get()).exists,
          isFalse,
        );
        expect(await ent.cola.pendientes(_uid), isEmpty);
      },
    );
  });

  group('Una edición nueva no se pisa con una vieja', () {
    test('con pendientes del mismo documento la nueva va detrás', () async {
      final ent = await _crearEntorno();
      final id = await ent.base.agregarRecordatorio('p1', _recordatorio('Turno'));
      ent.red.fijar(false);
      await ent.base.actualizarRecordatorio('p1', id, activo: false);

      ent.red.fijar(true);
      await ent.base.actualizarRecordatorio('p1', id, activo: true);

      expect(await ent.cola.pendientes(_uid), hasLength(2));

      await ent.orquestador.drenar();

      final doc = await ent.coleccion('recordatorios').doc(id).get();
      expect(doc.data()!['activo'], isTrue);
    });

    test('sin pendientes la escritura va directa al servidor', () async {
      final ent = await _crearEntorno();
      final id = await ent.base.agregarRecordatorio('p1', _recordatorio('Turno'));
      await ent.base.actualizarRecordatorio('p1', id, activo: false);

      expect(await ent.cola.pendientes(_uid), isEmpty);
      final doc = await ent.coleccion('recordatorios').doc(id).get();
      expect(doc.data()!['activo'], isFalse);
    });
  });

  test(
    'un recordatorio de otro paciente se rechaza antes de escribir',
    () async {
      final ent = await _crearEntorno();
      expect(
        () => ent.base.agregarRecordatorio(
          'p1',
          _recordatorio('A', paciente: 'p2'),
        ),
        throwsArgumentError,
      );
      expect((await ent.coleccion('recordatorios').get()).docs, isEmpty);
    },
  );

  group('Reintentar', () {
    test('devolver las fallidas avisa al orquestador', () async {
      final cola = ColaEscrituras();
      await cola.encolar(_uid, escrituraDe(id: 'a'));
      await cola.moverAFallidas(_uid, 'a');
      var avisos = 0;
      final suscripcion = cola.encolados.listen((_) => avisos++);
      addTearDown(suscripcion.cancel);

      await cola.reintentarFallidas(_uid);
      await Future<void>.delayed(Duration.zero);

      expect(avisos, 1);
      expect(await cola.fallidas(_uid), isEmpty);
      expect(await cola.pendientes(_uid), hasLength(1));
    });
  });

  group('Las pantallas no duplican el aviso de conexión', () {
    Future<void> mostrar(WidgetTester tester, Widget pantalla) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firebaseAuthProvider.overrideWithValue(
              MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: _uid)),
            ),
            estadoConexionProvider.overrideWith((_) => Stream.value(false)),
            resumenColaProvider.overrideWith(
              (_) => Stream.value(ResumenCola.vacio),
            ),
          ],
          child: MaterialApp(home: pantalla),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('recordatorios', (tester) async {
      await mostrar(tester, const RecordatoriosScreen());
      expect(find.byKey(const Key('banner_conexion')), findsNothing);
    });

    testWidgets('perfil', (tester) async {
      await mostrar(tester, const Perfil());
      expect(find.byKey(const Key('banner_conexion')), findsNothing);
    });
  });
}
