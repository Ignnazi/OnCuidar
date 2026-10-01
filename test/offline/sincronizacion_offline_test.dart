import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/core/servicios/cola_escrituras.dart';
import 'package:oncuidar/core/servicios/orquestador_sincronizacion.dart';
import 'package:oncuidar/core/servicios/servicio_base_datos.dart';
import 'package:oncuidar/core/servicios/servicio_cifrado.dart';
import 'package:oncuidar/core/servicios/servicio_conectividad.dart';
import 'package:oncuidar/modelos/recordatorio.dart';
import 'package:oncuidar/modelos/registro_clinico.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ayudas_offline.dart';

const _clavePrueba = 'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';
const _uid = 'uid-offline';

class _BaseConFallos extends ServicioBaseDatos {
  _BaseConFallos({
    required FirebaseFirestore base,
    required super.cifrado,
    required ColaEscrituras cola,
    required ServicioConectividad conectividad,
  }) : super(
         base: base,
         uidPrueba: _uid,
         cola: cola,
         conectividad: conectividad,
       );

  Object? Function(EscrituraPendiente escritura)? falla;
  final aplicadas = <String>[];

  @override
  Future<void> aplicarEscrituraPendiente(EscrituraPendiente escritura) async {
    final error = falla?.call(escritura);
    if (error != null) throw error;
    await super.aplicarEscrituraPendiente(escritura);
    aplicadas.add(escritura.ruta);
  }
}

class _Entorno {
  _Entorno({
    required this.firestore,
    required this.cola,
    required this.red,
    required this.base,
    required this.orquestador,
  });

  final FakeFirebaseFirestore firestore;
  final ColaEscrituras cola;
  final ConectividadFalsa red;
  final _BaseConFallos base;
  final OrquestadorSincronizacion orquestador;

  CollectionReference<Map<String, dynamic>> coleccion(
    String paciente,
    String nombre,
  ) => firestore
      .collection('users')
      .doc(_uid)
      .collection('patients')
      .doc(paciente)
      .collection(nombre);

  Future<List<EscrituraPendiente>> pendientes() => cola.pendientes(_uid);
}

Future<_Entorno> _crearEntorno({
  bool enLinea = false,
  Duration retardoBase = const Duration(hours: 1),
  int maxIntentos = 8,
}) async {
  final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
  await cifrado.fijarClave(_uid, _clavePrueba);
  final firestore = FakeFirebaseFirestore();
  final cola = ColaEscrituras();
  final red = ConectividadFalsa(enLinea: enLinea);
  final base = _BaseConFallos(
    base: firestore,
    cifrado: cifrado,
    cola: cola,
    conectividad: red,
  );
  final orquestador = OrquestadorSincronizacion(
    cola: cola,
    base: base,
    conectividad: red,
    uidActual: () => _uid,
    retardoBase: retardoBase,
    maxIntentosPorEscritura: maxIntentos,
  );
  addTearDown(orquestador.dispose);
  return _Entorno(
    firestore: firestore,
    cola: cola,
    red: red,
    base: base,
    orquestador: orquestador,
  );
}

RegistroClinico _registro(String id, String paciente) => RegistroClinico(
  id: id,
  pacienteId: paciente,
  fecha: DateTime(2026, 10, 1, 9),
  creadoEn: DateTime(2026, 10, 1, 9),
  tipoRegistro: 'diario',
  signosVitales: const SignosVitales(temperature: 37.2),
  sintomas: const [EntradaSintoma(name: 'Dolor', intensity: 3)],
  observaciones: 'Observación reservada',
);

Recordatorio _recordatorio(String paciente) => Recordatorio(
  id: '',
  pacienteId: paciente,
  tipo: 'medicamento',
  titulo: 'Dar paracetamol',
  descripcion: '500 mg',
  fechaHora: DateTime(2026, 10, 1, 20),
  activo: true,
  creadoEn: DateTime(2026, 10, 1, 8),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Escritura sin conexión', () {
    test(
      'un checklist creado sin red se ve de inmediato y queda en la cola',
      () async {
        final e = await _crearEntorno();
        final id = await e.base.crearListaChecklist(
          'pacienteA',
          titulo: 'Rutina diaria',
          items: ['Preparar mochila'],
        );

        expect(id, isNotEmpty);
        expect(
          (await e.coleccion('pacienteA', 'userChecklists').get()).docs,
          hasLength(1),
          reason: 'sin red la lista debe mostrar lo recién creado',
        );
        final visibles = await e.base
            .listasChecklistTiempoReal('pacienteA')
            .first;
        expect(visibles.map((l) => l.titulo), ['Rutina diaria']);
        final pendiente = (await e.pendientes()).single;
        expect(pendiente.ruta, endsWith('userChecklists/$id'));
        expect(pendiente.operacion, OperacionPendiente.crear);
      },
    );

    test(
      'lo encolado declara el paciente y no lleva datos clínicos en claro',
      () async {
        final e = await _crearEntorno();
        await e.base.crearListaChecklist(
          'pacienteA',
          titulo: 'Secreto',
          items: ['x'],
        );
        await e.base.guardarRegistroClinico(
          'pacienteA',
          _registro('r1', 'pacienteA'),
        );
        await e.base.agregarRecordatorio(
          'pacienteA',
          _recordatorio('pacienteA'),
        );

        final pendientes = await e.pendientes();
        expect(pendientes, hasLength(3));
        final todo = pendientes.map((p) => p.datos.toString()).join();
        for (final secreto in [
          'Secreto',
          'Observación reservada',
          'Dolor',
          'Dar paracetamol',
          '500 mg',
        ]) {
          expect(todo, isNot(contains(secreto)), reason: secreto);
        }
        expect(pendientes[0].datos['paciente_id'], 'pacienteA');
        expect(pendientes[1].datos['paciente_id'], 'pacienteA');
        expect(pendientes[2].datos['pacienteId'], 'pacienteA');
      },
    );

    test('con conexión se escribe directo y la cola queda vacía', () async {
      final e = await _crearEntorno(enLinea: true);
      final id = await e.base.crearListaChecklist(
        'pacienteA',
        titulo: 'Rutina',
        items: ['x'],
      );
      final doc = await e
          .coleccion('pacienteA', 'userChecklists')
          .doc(id)
          .get();
      expect(doc.exists, isTrue);
      expect(await e.pendientes(), isEmpty);
    });
  });

  group('Drenaje al recuperar la red', () {
    test('envía registro, checklist y recordatorio con su paciente', () async {
      final e = await _crearEntorno();
      await e.base.guardarRegistroClinico(
        'pacienteA',
        _registro('r1', 'pacienteA'),
      );
      final idLista = await e.base.crearListaChecklist(
        'pacienteA',
        titulo: 'Rutina',
        items: ['x'],
      );
      final idRec = await e.base.agregarRecordatorio(
        'pacienteA',
        _recordatorio('pacienteA'),
      );

      e.red.fijar(true);
      await e.orquestador.drenar();

      final registro = await e
          .coleccion('pacienteA', 'clinicalRecords')
          .doc('r1')
          .get();
      final lista = await e
          .coleccion('pacienteA', 'userChecklists')
          .doc(idLista)
          .get();
      final rec = await e
          .coleccion('pacienteA', 'recordatorios')
          .doc(idRec)
          .get();
      expect(registro.data()?['paciente_id'], 'pacienteA');
      expect(registro.data()?['sintomas_cifrado'], isNotNull);
      expect(registro.data()?['creadoEn'], isNotNull);
      expect(lista.data()?['paciente_id'], 'pacienteA');
      expect(rec.data()?['pacienteId'], 'pacienteA');
      expect(await e.pendientes(), isEmpty);
    });

    test('sin red no envía nada y conserva la cola', () async {
      final e = await _crearEntorno();
      await e.base.crearListaChecklist(
        'pacienteA',
        titulo: 'Rutina',
        items: ['x'],
      );
      await e.orquestador.drenar();
      expect(await e.pendientes(), hasLength(1));
      expect(e.base.aplicadas, isEmpty);
    });

    test('drenar dos veces no duplica documentos', () async {
      final e = await _crearEntorno();
      await e.base.crearListaChecklist(
        'pacienteA',
        titulo: 'Rutina',
        items: ['x'],
      );
      e.red.fijar(true);
      await Future.wait([e.orquestador.drenar(), e.orquestador.drenar()]);
      await e.orquestador.drenar();
      expect(
        (await e.coleccion('pacienteA', 'userChecklists').get()).docs,
        hasLength(1),
      );
    });

    test('reenviar una escritura ya aplicada es idempotente', () async {
      final e = await _crearEntorno(enLinea: true);
      await e.base.crearListaChecklist(
        'pacienteA',
        titulo: 'Rutina',
        items: ['x'],
      );
      final doc =
          (await e.coleccion('pacienteA', 'userChecklists').get()).docs.single;
      final escritura = escrituraDe(
        ruta: 'users/$_uid/patients/pacienteA/userChecklists/${doc.id}',
        pacienteId: 'pacienteA',
        datos: CodecPayload.codificar(doc.data()) as Map<String, dynamic>,
      );
      await e.base.aplicarEscrituraPendiente(escritura);
      await e.base.aplicarEscrituraPendiente(escritura);
      expect(
        (await e.coleccion('pacienteA', 'userChecklists').get()).docs,
        hasLength(1),
      );
    });

    test(
      'aplica en orden: crear y luego actualizar el mismo checklist',
      () async {
        final e = await _crearEntorno();
        final id = await e.base.crearListaChecklist(
          'pacienteA',
          titulo: 'Rutina',
          items: ['a', 'b'],
        );
        await e.base.actualizarListaChecklist(
          'pacienteA',
          id,
          indicesMarcados: [1],
        );
        e.red.fijar(true);
        await e.orquestador.drenar();

        final doc = await e
            .coleccion('pacienteA', 'userChecklists')
            .doc(id)
            .get();
        expect(doc.data()?['indicesMarcados'], [1]);
        expect(doc.data()?['paciente_id'], 'pacienteA');
      },
    );

    test(
      'se drena sola al volver la red cuando el orquestador está activo',
      () async {
        final e = await _crearEntorno();
        e.orquestador.iniciar();
        await e.base.crearListaChecklist(
          'pacienteA',
          titulo: 'Rutina',
          items: ['x'],
        );
        expect(await e.pendientes(), hasLength(1));

        e.red.fijar(true);
        await esperarHasta(() async => (await e.pendientes()).isEmpty);
        expect(
          (await e.coleccion('pacienteA', 'userChecklists').get()).docs,
          hasLength(1),
        );
      },
    );

    test(
      'la cola sobrevive al cierre de la app y se envía al reabrir',
      () async {
        final e = await _crearEntorno();
        await e.base.crearListaChecklist(
          'pacienteA',
          titulo: 'Rutina',
          items: ['x'],
        );

        final prefs = await SharedPreferences.getInstance();
        SharedPreferences.setMockInitialValues({
          for (final k in prefs.getKeys()) k: prefs.getString(k)!,
        });

        final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
        final cola = ColaEscrituras();
        final red = ConectividadFalsa(enLinea: true);
        final base = _BaseConFallos(
          base: e.firestore,
          cifrado: cifrado,
          cola: cola,
          conectividad: red,
        );
        final orquestador = OrquestadorSincronizacion(
          cola: cola,
          base: base,
          conectividad: red,
          uidActual: () => _uid,
        );
        addTearDown(orquestador.dispose);

        await orquestador.drenar();
        expect(
          (await e.coleccion('pacienteA', 'userChecklists').get()).docs,
          hasLength(1),
        );
        expect(await cola.pendientes(_uid), isEmpty);
      },
    );
  });

  group('Reconciliación de conflictos', () {
    test(
      'un borrado en el servidor gana sobre una actualización encolada',
      () async {
        final e = await _crearEntorno(enLinea: true);
        final id = await e.base.crearListaChecklist(
          'pacienteA',
          titulo: 'Rutina',
          items: ['x'],
        );
        e.red.fijar(false);
        await e.base.actualizarListaChecklist(
          'pacienteA',
          id,
          indicesMarcados: [0],
        );
        await e.coleccion('pacienteA', 'userChecklists').doc(id).delete();

        e.red.fijar(true);
        await e.orquestador.drenar();

        final doc = await e
            .coleccion('pacienteA', 'userChecklists')
            .doc(id)
            .get();
        expect(doc.exists, isFalse);
        expect(await e.pendientes(), isEmpty);
        expect(await e.cola.fallidas(_uid), isEmpty);
      },
    );

    test('la última escritura encolada gana campo a campo', () async {
      final e = await _crearEntorno(enLinea: true);
      final id = await e.base.crearListaChecklist(
        'pacienteA',
        titulo: 'Rutina',
        items: ['x', 'y'],
      );
      e.red.fijar(false);
      await e.base.actualizarListaChecklist(
        'pacienteA',
        id,
        indicesMarcados: [0],
      );
      await e.base.actualizarListaChecklist(
        'pacienteA',
        id,
        indicesMarcados: [0, 1],
      );

      e.red.fijar(true);
      await e.orquestador.drenar();

      final doc = await e
          .coleccion('pacienteA', 'userChecklists')
          .doc(id)
          .get();
      expect(doc.data()?['indicesMarcados'], [0, 1]);
      expect(doc.data()?['paciente_id'], 'pacienteA');
    });
  });

  group('Fallos durante el drenaje', () {
    test('un fallo transitorio a mitad no pierde ninguna escritura', () async {
      final e = await _crearEntorno();
      await e.base.crearListaChecklist(
        'pacienteA',
        titulo: 'Uno',
        items: ['x'],
      );
      await e.base.agregarRecordatorio('pacienteA', _recordatorio('pacienteA'));
      await e.base.guardarRegistroClinico(
        'pacienteA',
        _registro('r1', 'pacienteA'),
      );

      e.base.falla = (escritura) => escritura.ruta.contains('recordatorios')
          ? FirebaseException(plugin: 'cloud_firestore', code: 'unavailable')
          : null;
      e.red.fijar(true);
      await e.orquestador.drenar();

      final restantes = await e.pendientes();
      expect(restantes, hasLength(2));
      expect(restantes.first.ruta, contains('recordatorios'));
      expect(restantes.first.intentos, 1);
      expect(
        (await e.coleccion('pacienteA', 'userChecklists').get()).docs,
        hasLength(1),
      );

      e.base.falla = null;
      await e.orquestador.drenar();
      expect(await e.pendientes(), isEmpty);
      expect(
        (await e.coleccion('pacienteA', 'recordatorios').get()).docs,
        hasLength(1),
      );
      expect(
        (await e.coleccion('pacienteA', 'clinicalRecords').get()).docs,
        hasLength(1),
      );
    });

    test('reintenta solo con retroceso hasta lograrlo', () async {
      final e = await _crearEntorno(
        retardoBase: const Duration(milliseconds: 10),
      );
      await e.base.crearListaChecklist(
        'pacienteA',
        titulo: 'Uno',
        items: ['x'],
      );
      var fallos = 0;
      e.base.falla = (_) {
        if (fallos >= 2) return null;
        fallos++;
        return FirebaseException(
          plugin: 'cloud_firestore',
          code: 'unavailable',
        );
      };
      e.red.fijar(true);
      await e.orquestador.drenar();
      expect(await e.pendientes(), hasLength(1));

      await esperarHasta(() async => (await e.pendientes()).isEmpty);
      expect(fallos, 2);
      expect(
        (await e.coleccion('pacienteA', 'userChecklists').get()).docs,
        hasLength(1),
      );
    });

    test('un error permanente va a fallidas y no bloquea al resto', () async {
      final e = await _crearEntorno();
      await e.base.crearListaChecklist(
        'pacienteA',
        titulo: 'Uno',
        items: ['x'],
      );
      await e.base.agregarRecordatorio('pacienteA', _recordatorio('pacienteA'));
      e.base.falla = (escritura) => escritura.ruta.contains('userChecklists')
          ? FirebaseException(
              plugin: 'cloud_firestore',
              code: 'permission-denied',
            )
          : null;

      e.red.fijar(true);
      await e.orquestador.drenar();

      expect(await e.pendientes(), isEmpty);
      expect(await e.cola.fallidas(_uid), hasLength(1));
      expect(
        (await e.coleccion('pacienteA', 'recordatorios').get()).docs,
        hasLength(1),
      );
    });

    test('tras agotar los intentos la escritura pasa a fallidas', () async {
      final e = await _crearEntorno(maxIntentos: 2);
      await e.base.crearListaChecklist(
        'pacienteA',
        titulo: 'Uno',
        items: ['x'],
      );
      e.base.falla = (_) =>
          FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
      e.red.fijar(true);

      await e.orquestador.drenar();
      expect(await e.pendientes(), hasLength(1));
      await e.orquestador.drenar();
      expect(await e.pendientes(), isEmpty);
      expect(await e.cola.fallidas(_uid), hasLength(1));
    });
  });

  group('Aislamiento por paciente', () {
    test('no envía una escritura cuya ruta es de otro paciente', () async {
      final e = await _crearEntorno(enLinea: true);
      await e.cola.encolar(
        _uid,
        escrituraDe(
          ruta: 'users/$_uid/patients/pacienteB/userChecklists/c1',
          pacienteId: 'pacienteA',
        ),
      );
      await e.orquestador.drenar();

      expect(
        (await e.coleccion('pacienteB', 'userChecklists').get()).docs,
        isEmpty,
      );
      expect(await e.cola.fallidas(_uid), hasLength(1));
    });

    test('no envía una escritura de la ruta de otro cuidador', () async {
      final e = await _crearEntorno(enLinea: true);
      await e.cola.encolar(
        _uid,
        escrituraDe(
          ruta: 'users/otro-cuidador/patients/pacienteA/userChecklists/c1',
          pacienteId: 'pacienteA',
        ),
      );
      await e.orquestador.drenar();
      expect(await e.cola.fallidas(_uid), hasLength(1));
      final ajeno = await e.firestore
          .collection('users')
          .doc('otro-cuidador')
          .collection('patients')
          .doc('pacienteA')
          .collection('userChecklists')
          .get();
      expect(ajeno.docs, isEmpty);
    });
  });
}
