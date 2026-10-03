import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/core/proveedores/proveedores.dart';
import 'package:oncuidar/core/servicios/servicio_base_datos.dart';
import 'package:oncuidar/core/servicios/servicio_cache_metadata.dart';
import 'package:oncuidar/core/servicios/servicio_cifrado.dart';
import 'package:oncuidar/modelos/conversacion.dart';
import 'package:oncuidar/modelos/material_educativo.dart';
import 'package:oncuidar/modelos/paciente.dart';
import 'package:oncuidar/modelos/recordatorio.dart';
import 'package:oncuidar/modelos/registro_clinico.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _clavePrueba = 'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';
const _uid = 'uid-transversal';

Future<void> _esperar(bool Function() condicion) async {
  for (var i = 0; i < 200; i++) {
    if (condicion()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('La condición no se cumplió a tiempo');
}

void main() {
  late FakeFirebaseFirestore firestore;
  late ServicioBaseDatos base;
  late ProviderContainer contenedor;
  late String idA;
  late String idB;

  Future<String> crearPaciente(String nombre) => base.crearPaciente(
    Paciente(id: '', fullName: nombre, createdAt: DateTime.now()),
  );

  Future<void> sembrarPorPaciente(String id, String etiqueta) async {
    final ahora = DateTime.now();
    await base.guardarRegistroClinico(
      id,
      RegistroClinico(
        id: 'registro-$etiqueta',
        pacienteId: id,
        fecha: ahora,
        creadoEn: ahora,
        tipoRegistro: 'diario',
        observaciones: 'obs $etiqueta',
      ),
    );
    await base.agregarRecordatorio(
      id,
      Recordatorio(
        id: '',
        pacienteId: id,
        tipo: 'medicamento',
        titulo: 'recordatorio $etiqueta',
        fechaHora: ahora,
        diasRepeticion: const [],
        activo: true,
        creadoEn: ahora,
      ),
    );
  }

  List<E> Function() observar<E>(StreamProvider<List<E>> provider) {
    final suscripcion = contenedor.listen(provider, (_, _) {});
    addTearDown(suscripcion.close);
    return () => suscripcion.read().value ?? <E>[];
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    await cifrado.fijarClave(_uid, _clavePrueba);
    firestore = FakeFirebaseFirestore();
    base = ServicioBaseDatos(
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
    idA = await crearPaciente('Paciente A');
    idB = await crearPaciente('Paciente B');
    await sembrarPorPaciente(idA, 'A');
    await sembrarPorPaciente(idB, 'B');
    await firestore
        .collection('educationalContent')
        .doc('guia-1')
        .set(
          MaterialEducativo(
            id: 'guia-1',
            title: 'Guía de síntomas',
            category: 'Guías',
            topic: 'Cuidados',
            body: 'Texto',
            createdAt: DateTime.utc(2026, 1, 2),
          ).toMap(),
        );
    await base.alternarFavorito('guia-1');
    await base.crearConversacion(
      titulo: 'Consulta de prueba',
      mensajes: const [MensajeConversacion(texto: 'Hola', delUsuario: true)],
    );

    contenedor = ProviderContainer(
      overrides: [
        servicioBaseDatosProvider.overrideWith((_) => base),
        servicioCacheMetadataProvider.overrideWithValue(
          ServicioCacheMetadata(),
        ),
      ],
    );
    addTearDown(contenedor.dispose);
  });

  Future<void> seleccionar(String id) async {
    await contenedor.read(selectedPatientIdProvider.notifier).select(id);
  }

  group('Datos por paciente activo', () {
    test('al cambiar de paciente cambian registros y recordatorios', () async {
      await seleccionar(idA);
      final registros = observar(registrosClinicosProvider);
      final recordatorios = observar(recordatoriosProvider);

      await _esperar(
        () => registros().isNotEmpty && registros().first.pacienteId == idA,
      );
      expect(registros().map((r) => r.observaciones), ['obs A']);
      await _esperar(() => recordatorios().isNotEmpty);
      expect(recordatorios().map((r) => r.titulo), ['recordatorio A']);

      await seleccionar(idB);
      await _esperar(
        () => registros().isNotEmpty && registros().first.pacienteId == idB,
      );
      expect(registros().map((r) => r.observaciones), ['obs B']);
      await _esperar(
        () =>
            recordatorios().isNotEmpty &&
            recordatorios().first.titulo == 'recordatorio B',
      );
      expect(recordatorios().map((r) => r.titulo), ['recordatorio B']);
    });

    test('volver al paciente anterior recupera solo sus datos', () async {
      await seleccionar(idA);
      final recordatorios = observar(recordatoriosProvider);
      await _esperar(
        () =>
            recordatorios().isNotEmpty &&
            recordatorios().first.titulo == 'recordatorio A',
      );
      await seleccionar(idB);
      await _esperar(
        () =>
            recordatorios().isNotEmpty &&
            recordatorios().first.titulo == 'recordatorio B',
      );
      await seleccionar(idA);
      await _esperar(
        () =>
            recordatorios().isNotEmpty &&
            recordatorios().first.titulo == 'recordatorio A',
      );
      expect(recordatorios(), hasLength(1));
    });

    test('ninguna lista mezcla datos de los dos pacientes', () async {
      for (final id in [idA, idB]) {
        await seleccionar(id);
        final registros = observar(registrosClinicosProvider);
        await _esperar(
          () => registros().isNotEmpty && registros().first.pacienteId == id,
        );
        expect(registros().every((r) => r.pacienteId == id), isTrue);
      }
    });
  });

  group('Datos compartidos del cuidador', () {
    test('el chat no cambia ni se duplica al cambiar de paciente', () async {
      await seleccionar(idA);
      final conversaciones = observar(conversacionesProvider);
      await _esperar(() => conversaciones().isNotEmpty);
      final antes = conversaciones().map((c) => c.id).toList();
      expect(antes, hasLength(1));

      await seleccionar(idB);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(conversaciones().map((c) => c.id).toList(), antes);
      expect(conversaciones().single.titulo, 'Consulta de prueba');
    });

    test(
      'la biblioteca y los favoritos no cambian al cambiar de paciente',
      () async {
        await seleccionar(idA);
        final contenidos = observar(contenidosEducativosProvider);
        final favoritos = observar(idsFavoritosProvider);
        await _esperar(() => contenidos().isNotEmpty);
        await _esperar(() => favoritos().isNotEmpty);
        final idsAntes = contenidos().map((m) => m.id).toList();
        expect(idsAntes, ['guia-1']);
        expect(favoritos(), ['guia-1']);

        await seleccionar(idB);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(contenidos().map((m) => m.id).toList(), idsAntes);
        expect(favoritos(), ['guia-1']);
      },
    );

    test(
      'los documentos del chat y la biblioteca no declaran paciente',
      () async {
        final chat = await firestore
            .collection('users')
            .doc(_uid)
            .collection('conversations')
            .get();
        for (final doc in chat.docs) {
          expect(doc.data().keys, isNot(contains('paciente_id')));
          expect(doc.data().keys, isNot(contains('pacienteId')));
        }
        final biblioteca = await firestore
            .collection('educationalContent')
            .get();
        for (final doc in biblioteca.docs) {
          expect(doc.data().keys, isNot(contains('paciente_id')));
          expect(doc.data().keys, isNot(contains('pacienteId')));
        }
      },
    );
  });
}
