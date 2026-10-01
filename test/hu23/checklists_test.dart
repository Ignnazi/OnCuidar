import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oncuidar/caracteristicas/biblioteca/biblioteca.dart';
import 'package:oncuidar/core/proveedores/proveedores.dart';
import 'package:oncuidar/core/servicios/servicio_base_datos.dart';
import 'package:oncuidar/core/servicios/servicio_cache_contenido.dart';
import 'package:oncuidar/core/servicios/servicio_cache_metadata.dart';
import 'package:oncuidar/core/servicios/servicio_cifrado.dart';
import 'package:oncuidar/modelos/material_educativo.dart';
import 'package:oncuidar/modelos/paciente.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _clavePrueba = 'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';
const _uid = 'uid-1';

MockFirebaseAuth _auth() => MockFirebaseAuth(
  mockUser: MockUser(uid: _uid, email: 'cuidador@test.cl'),
);

MaterialEducativo _guia() => MaterialEducativo(
  id: 'guias-manual-de-control-de-sintomas',
  title: 'Manual de Control de Síntomas',
  category: 'Guías',
  topic: 'Cuidados Paliativos',
  body: 'Guía práctica.',
  createdAt: DateTime.utc(2026, 1, 2),
);

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

Future<(ServicioBaseDatos, FakeFirebaseFirestore, String)> _baseConPaciente(
  ServicioCifrado cifrado,
) async {
  await cifrado.fijarClave(_uid, _clavePrueba);
  final firestore = FakeFirebaseFirestore();
  final base = ServicioBaseDatos(
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
  await base.crearPaciente(
    Paciente(
      id: 'paciente',
      fullName: 'Paciente Test',
      createdAt: DateTime.now(),
    ),
  );
  final docs = await firestore
      .collection('users')
      .doc(_uid)
      .collection('patients')
      .get();
  return (base, firestore, docs.docs.single.id);
}

DocumentReference<Map<String, dynamic>> _docChecklist(
  FakeFirebaseFirestore firestore,
  String idPaciente,
  String idLista,
) => firestore
    .collection('users')
    .doc(_uid)
    .collection('patients')
    .doc(idPaciente)
    .collection('userChecklists')
    .doc(idLista);

Widget _pantalla(ServicioBaseDatos base, _CacheFalso cache) {
  final router = GoRouter(
    initialLocation: '/biblioteca',
    routes: [
      GoRoute(path: '/biblioteca', builder: (c, s) => const BibliotecaScreen()),
    ],
  );
  return ProviderScope(
    overrides: [
      firebaseAuthProvider.overrideWithValue(_auth()),
      servicioBaseDatosProvider.overrideWith((_) => base),
      servicioCacheContenidoProvider.overrideWithValue(cache),
      servicioCacheMetadataProvider.overrideWithValue(ServicioCacheMetadata()),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _montar(
  WidgetTester tester,
  ServicioBaseDatos base,
  _CacheFalso cache,
) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_pantalla(base, cache));
  await tester.pumpAndSettle();
}

Future<void> _sembrarMaterial(FakeFirebaseFirestore firestore) async {
  await firestore
      .collection('educationalContent')
      .doc(_guia().id)
      .set(_guia().toMap());
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ServicioBaseDatos — Mis Checklists', () {
    late ServicioCifrado cifrado;
    late ServicioBaseDatos base;
    late FakeFirebaseFirestore firestore;
    late String idPaciente;

    setUp(() async {
      cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
      (base, firestore, idPaciente) = await _baseConPaciente(cifrado);
    });

    test(
      'crear guarda el doc en userChecklists con indices vacíos y fecha',
      () async {
        final id = await base.crearListaChecklist(
          idPaciente,
          titulo: 'Rutina diaria',
          items: ['Preparar mochila', 'Llevar carnet'],
        );
        final doc = await _docChecklist(firestore, idPaciente, id).get();
        expect(doc.exists, isTrue);
        expect(doc.data()?['indicesMarcados'], isEmpty);
        expect(doc.data()?['creadoEn'], isNotNull);
      },
    );

    test('titulo e items se guardan cifrados y se descifran', () async {
      final id = await base.crearListaChecklist(
        idPaciente,
        titulo: 'Rutina diaria',
        items: ['Preparar mochila', 'Llevar carnet'],
      );
      final datos = (await _docChecklist(
        firestore,
        idPaciente,
        id,
      ).get()).data()!;
      expect(datos.containsKey('titulo'), isFalse);
      expect(datos.containsKey('items'), isFalse);
      expect(datos['titulo_cifrado'], isA<String>());
      expect(datos['titulo_cifrado'], isNot('Rutina diaria'));
      expect(datos['items_cifrado'], isA<String>());
      expect(
        await cifrado.descifrar(_uid, datos['titulo_cifrado'] as String),
        'Rutina diaria',
      );
      final items =
          jsonDecode(
                await cifrado.descifrar(_uid, datos['items_cifrado'] as String),
              )
              as List<dynamic>;
      expect(items, ['Preparar mochila', 'Llevar carnet']);
    });

    test('actualizar modifica indicesMarcados en claro', () async {
      final id = await base.crearListaChecklist(
        idPaciente,
        titulo: 'Rutina diaria',
        items: ['Preparar mochila', 'Llevar carnet'],
      );
      await base.actualizarListaChecklist(idPaciente, id, indicesMarcados: [1]);
      final datos = (await _docChecklist(
        firestore,
        idPaciente,
        id,
      ).get()).data()!;
      expect(datos['indicesMarcados'], [1]);
    });

    test('eliminar borra el documento', () async {
      final id = await base.crearListaChecklist(
        idPaciente,
        titulo: 'Rutina diaria',
        items: ['Preparar mochila'],
      );
      await base.eliminarListaChecklist(idPaciente, id);
      final doc = await _docChecklist(firestore, idPaciente, id).get();
      expect(doc.exists, isFalse);
    });

    test('el stream descifra las listas del paciente', () async {
      await base.crearListaChecklist(
        idPaciente,
        titulo: 'Rutina diaria',
        items: ['Preparar mochila', 'Llevar carnet'],
      );
      final listas = await base.listasChecklistTiempoReal(idPaciente).first;
      expect(listas, hasLength(1));
      expect(listas.single.titulo, 'Rutina diaria');
      expect(listas.single.items, ['Preparar mochila', 'Llevar carnet']);
      expect(listas.single.indicesMarcados, isEmpty);
    });
  });

  group('Biblioteca — Mis Checklists', () {
    testWidgets('una lista sembrada se ve como card con su progreso', (
      tester,
    ) async {
      final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
      final (base, firestore, idPaciente) = await _baseConPaciente(cifrado);
      await _sembrarMaterial(firestore);
      final id = await base.crearListaChecklist(
        idPaciente,
        titulo: 'Rutina diaria',
        items: ['Preparar mochila', 'Llevar carnet'],
      );
      await base.actualizarListaChecklist(idPaciente, id, indicesMarcados: [0]);

      await _montar(tester, base, _CacheFalso());

      expect(find.text('Mis Checklists'), findsOneWidget);
      expect(find.text('Rutina diaria'), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
    });

    testWidgets('crear desde el botón + agrega la card y guarda el doc', (
      tester,
    ) async {
      final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
      final (base, firestore, idPaciente) = await _baseConPaciente(cifrado);
      await _sembrarMaterial(firestore);

      await _montar(tester, base, _CacheFalso());

      await tester.tap(find.byKey(const Key('agregarChecklist')));
      await tester.pumpAndSettle();

      expect(find.text('Nuevo checklist'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'Rutina diaria');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Preparar mochila',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'Llevar carnet');
      await tester.tap(find.byKey(const Key('guardarChecklist')));
      await tester.pumpAndSettle();

      expect(find.text('Rutina diaria'), findsOneWidget);
      expect(find.text('0/2'), findsOneWidget);

      final docs = await (firestore
          .collection('users')
          .doc(_uid)
          .collection('patients')
          .doc(idPaciente)
          .collection('userChecklists')
          .get());
      expect(docs.docs, hasLength(1));
      expect(docs.docs.single.data()['indicesMarcados'], isEmpty);
      expect(docs.docs.single.data()['titulo_cifrado'], isA<String>());
    });

    testWidgets('marcar un ítem en la hoja persiste índices en Firestore', (
      tester,
    ) async {
      final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
      final (base, firestore, idPaciente) = await _baseConPaciente(cifrado);
      await _sembrarMaterial(firestore);
      final id = await base.crearListaChecklist(
        idPaciente,
        titulo: 'Rutina diaria',
        items: ['Preparar mochila', 'Llevar carnet'],
      );

      await _montar(tester, base, _CacheFalso());

      await tester.tap(find.byKey(Key('checklist_$id')));
      await tester.pumpAndSettle();

      expect(find.text('Preparar mochila'), findsOneWidget);

      await tester.tap(find.text('Preparar mochila'));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      final doc = await _docChecklist(firestore, idPaciente, id).get();
      expect(doc.data()?['indicesMarcados'], [0]);
    });

    testWidgets('eliminar desde opciones con confirmación quita la card', (
      tester,
    ) async {
      final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
      final (base, firestore, idPaciente) = await _baseConPaciente(cifrado);
      await _sembrarMaterial(firestore);
      final id = await base.crearListaChecklist(
        idPaciente,
        titulo: 'Rutina diaria',
        items: ['Preparar mochila'],
      );

      await _montar(tester, base, _CacheFalso());

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(find.text('Eliminar checklist'), findsOneWidget);

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(find.byKey(Key('checklist_$id')), findsNothing);
      final doc = await _docChecklist(firestore, idPaciente, id).get();
      expect(doc.exists, isFalse);
    });
  });
}
