import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oncuidar/caracteristicas/biblioteca/biblioteca.dart';
import 'package:oncuidar/caracteristicas/biblioteca/hoja_checklist_usuario.dart';
import 'package:oncuidar/caracteristicas/biblioteca/hoja_editor_checklist.dart';
import 'package:oncuidar/core/proveedores/proveedores.dart';
import 'package:oncuidar/core/servicios/servicio_base_datos.dart';
import 'package:oncuidar/core/servicios/servicio_cache_contenido.dart';
import 'package:oncuidar/core/servicios/servicio_cache_metadata.dart';
import 'package:oncuidar/core/servicios/servicio_cifrado.dart';
import 'package:oncuidar/modelos/paciente.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _clavePrueba = 'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';
const _uid = 'uid-1';

MockFirebaseAuth _auth() => MockFirebaseAuth(
  mockUser: MockUser(uid: _uid, email: 'cuidador@test.cl'),
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
    Paciente(id: 'paciente', fullName: 'Paciente Test', createdAt: DateTime.now()),
  );
  final docs = await firestore
      .collection('users')
      .doc(_uid)
      .collection('patients')
      .get();
  return (base, firestore, docs.docs.single.id);
}

CollectionReference<Map<String, dynamic>> _colleccion(
  FakeFirebaseFirestore firestore,
  String idPaciente,
) => firestore
    .collection('users')
    .doc(_uid)
    .collection('patients')
    .doc(idPaciente)
    .collection('userChecklists');

Future<void> _sembrarMaterial(FakeFirebaseFirestore firestore) async {
  await firestore.collection('educationalContent').doc('g1').set({
    'id': 'g1',
    'title': 'Manual de Control de Síntomas',
    'category': 'Guías',
    'topic': 'Cuidados Paliativos',
    'body': 'Guía práctica.',
    'createdAt': DateTime.utc(2026, 1, 2),
  });
}

Future<void> _montar(
  WidgetTester tester,
  ServicioBaseDatos base, {
  Size tamano = const Size(800, 1600),
}) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(
    initialLocation: '/biblioteca',
    routes: [
      GoRoute(path: '/biblioteca', builder: (c, s) => const BibliotecaScreen()),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        firebaseAuthProvider.overrideWithValue(_auth()),
        servicioBaseDatosProvider.overrideWith((_) => base),
        servicioCacheContenidoProvider.overrideWithValue(_CacheFalso()),
        servicioCacheMetadataProvider.overrideWithValue(ServicioCacheMetadata()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _abrirHoja(WidgetTester tester, String idLista) async {
  await tester.tap(find.byKey(Key('checklist_$idLista')));
  await tester.pumpAndSettle();
  expect(find.byType(HojaChecklistUsuario), findsOneWidget);
}

Future<void> _esperarGuardado(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('marcando todos los ítems se registra completadaEn', (
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

    await _montar(tester, base);
    await _abrirHoja(tester, id);

    await tester.tap(find.text('Preparar mochila'));
    await tester.tap(find.text('Llevar carnet'));
    await _esperarGuardado(tester);

    final datos = (await _colleccion(firestore, idPaciente).doc(id).get()).data()!;
    expect(datos['indicesMarcados'], [0, 1]);
    expect(datos['completadaEn'], isNotNull);
    expect(find.textContaining('Completada el'), findsOneWidget);
  });

  testWidgets('desmarcar un ítem borra completadaEn y vuelve a pendiente', (
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
    await base.actualizarListaChecklist(
      idPaciente,
      id,
      indicesMarcados: [0, 1],
      completadaEn: DateTime(2026, 9, 30, 10),
    );

    await _montar(tester, base);
    await _abrirHoja(tester, id);
    expect(find.textContaining('Completada el'), findsOneWidget);

    await tester.tap(find.text('Preparar mochila'));
    await _esperarGuardado(tester);

    final datos = (await _colleccion(firestore, idPaciente).doc(id).get()).data()!;
    expect(datos['indicesMarcados'], [1]);
    expect(datos.containsKey('completadaEn'), isFalse);
    expect(find.text('Pendiente: 1 de 2'), findsOneWidget);
  });

  testWidgets('una lista a medias muestra Pendiente: n de total', (
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
    await base.actualizarListaChecklist(idPaciente, id, indicesMarcados: [1]);

    await _montar(tester, base);
    await _abrirHoja(tester, id);

    expect(find.text('Pendiente: 1 de 2'), findsOneWidget);
    expect(find.textContaining('Completada el'), findsNothing);
    expect(find.byKey(const Key('reiniciarChecklist')), findsOneWidget);
  });

  testWidgets('sin marcas no hay acción Reiniciar y la fecha aún no existe', (
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

    await _montar(tester, base);
    await _abrirHoja(tester, id);

    expect(find.text('Pendiente: 0 de 1'), findsOneWidget);
    expect(find.byKey(const Key('reiniciarChecklist')), findsNothing);
    expect(find.byKey(const Key('duplicarChecklist')), findsOneWidget);
  });

  testWidgets('cerrar la hoja con el debounce pendiente guarda la última marca', (
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

    await _montar(tester, base);
    await _abrirHoja(tester, id);

    await tester.tap(find.text('Preparar mochila'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();

    final datos = (await _colleccion(firestore, idPaciente).doc(id).get()).data()!;
    expect(datos['indicesMarcados'], [0]);
  });

  testWidgets('Reiniciar pide confirmación y cancelar no borra nada', (
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
    await base.actualizarListaChecklist(idPaciente, id, indicesMarcados: [0, 1]);

    await _montar(tester, base);
    await _abrirHoja(tester, id);

    await tester.tap(find.byKey(const Key('reiniciarChecklist')));
    await tester.pumpAndSettle();
    expect(find.text('Reiniciar lista'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancelar'));
    await tester.pumpAndSettle();
    await _esperarGuardado(tester);

    final trasCancelar = (await _colleccion(
      firestore,
      idPaciente,
    ).doc(id).get()).data()!;
    expect(trasCancelar['indicesMarcados'], [0, 1]);

    await tester.tap(find.byKey(const Key('reiniciarChecklist')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Reiniciar'));
    await _esperarGuardado(tester);

    final datos = (await _colleccion(firestore, idPaciente).doc(id).get()).data()!;
    expect(datos['indicesMarcados'], isEmpty);
    expect(find.text('Pendiente: 0 de 2'), findsOneWidget);
  });

  testWidgets('Duplicar crea una copia sin marcas con el mismo contenido', (
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
    await base.actualizarListaChecklist(
      idPaciente,
      id,
      indicesMarcados: [0, 1],
      completadaEn: DateTime(2026, 9, 30, 10),
    );

    await _montar(tester, base);
    await _abrirHoja(tester, id);

    await tester.tap(find.byKey(const Key('duplicarChecklist')));
    await tester.pumpAndSettle();

    final docs = await _colleccion(firestore, idPaciente).get();
    expect(docs.docs, hasLength(2));
    final copia = docs.docs.firstWhere((d) => d.id != id);
    final datosCopia = copia.data();
    expect(datosCopia['titulo_cifrado'], isNotNull);
    expect(datosCopia['items_cifrado'], isNotNull);
    expect(datosCopia['indicesMarcados'], isEmpty);
    expect(datosCopia.containsKey('completadaEn'), isFalse);
    expect(datosCopia['paciente_id'], idPaciente);
  });

  testWidgets('el editor reubica las marcas al quitar un ítem marcado', (
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
    await base.actualizarListaChecklist(idPaciente, id, indicesMarcados: [1]);

    await _montar(tester, base);

    await tester.tap(
      find
          .descendant(
            of: find.byKey(Key('checklist_$id')),
            matching: find.byIcon(Icons.more_vert),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar').first);
    await tester.pumpAndSettle();
    expect(find.byType(HojaEditorChecklist), findsOneWidget);

    await tester.tap(
      find
          .descendant(
            of: find.byType(HojaEditorChecklist),
            matching: find.byIcon(Icons.remove),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('guardarChecklist')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    final datos = (await _colleccion(firestore, idPaciente).doc(id).get()).data()!;
    expect(datos['indicesMarcados'], [0]);
    expect(datos['items_cifrado'], isNotNull);
  });

  testWidgets('la hoja abierta no desborda en 320x568', (tester) async {
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    final (base, firestore, idPaciente) = await _baseConPaciente(cifrado);
    await _sembrarMaterial(firestore);
    final id = await base.crearListaChecklist(
      idPaciente,
      titulo: 'Rutina de la mañana con un nombre muy largo para probar el ancho',
      items: [
        'Preparar la mochila con la medicación semanal',
        'Llevar el carnet de controles al hospital',
      ],
    );
    await base.actualizarListaChecklist(idPaciente, id, indicesMarcados: [1]);

    await _montar(tester, base, tamano: const Size(320, 568));
    await _abrirHoja(tester, id);

    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Preparar la mochila con la medicación semanal'));
    await _esperarGuardado(tester);
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Completada el'), findsOneWidget);
  });
}