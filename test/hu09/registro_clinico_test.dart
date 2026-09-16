import 'dart:convert';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/registro_clinico.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/widgets/selector_multi_sintoma.dart';
import 'package:oncuidar/core/catalogos/catalogo_sintomas.dart';
import 'package:oncuidar/core/proveedores/proveedores.dart';
import 'package:oncuidar/core/servicios/servicio_base_datos.dart';
import 'package:oncuidar/core/servicios/servicio_cifrado.dart';
import 'package:oncuidar/modelos/paciente.dart';
import 'package:oncuidar/modelos/registro_clinico.dart';

const _clavePrueba = 'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';
const _uid = 'uid-1';

MockFirebaseAuth _auth() => MockFirebaseAuth(
  mockUser: MockUser(uid: _uid, email: 'cuidador@test.cl'),
);

Future<(ServicioBaseDatos, FakeFirebaseFirestore)> _baseConDatos(
  ServicioCifrado cifrado, {
  bool conPaciente = true,
}) async {
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
  if (conPaciente) {
    await base.crearPaciente(
      Paciente(
        id: 'paciente',
        fullName: 'Paciente Test',
        createdAt: DateTime.now(),
      ),
    );
  }
  return (base, firestore);
}

Future<String> _idPacienteUnico(FakeFirebaseFirestore firestore) async {
  final docs = await firestore
      .collection('users')
      .doc(_uid)
      .collection('patients')
      .get();
  return docs.docs.single.id;
}

Future<List<Map<String, dynamic>>> _sintomasDescifrados(
  ServicioCifrado cifrado,
  Map<String, dynamic> doc,
) async {
  final cifradoTexto = doc['sintomas_cifrado'] as String;
  final texto = await cifrado.descifrar(_uid, cifradoTexto);
  return (jsonDecode(texto) as List<dynamic>).cast<Map<String, dynamic>>();
}

Widget _pantalla(ServicioCifrado cifrado, ServicioBaseDatos base) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (c, s) => const RegistroClinicoScreen()),
      GoRoute(
        path: '/dashboard',
        builder: (c, s) =>
            const Scaffold(body: Center(child: Text('Dashboard'))),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      firebaseAuthProvider.overrideWithValue(_auth()),
      servicioCifradoProvider.overrideWithValue(cifrado),
      servicioBaseDatosProvider.overrideWith((_) => base),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void _taller(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _tocarGuardar(WidgetTester tester) async {
  final boton = find.text('Guardar registro');
  await tester.ensureVisible(boton);
  await tester.pumpAndSettle();
  await tester.tap(boton);
  await tester.pumpAndSettle();
}

Future<void> _abrirSelector(WidgetTester tester) async {
  if (find.byType(SelectorMultiSintoma).evaluate().isNotEmpty) return;
  final campo = find.byKey(const Key('campoSelectorSintomas'));
  await tester.ensureVisible(campo);
  await tester.pumpAndSettle();
  await tester.tap(campo);
  await tester.pumpAndSettle();
}

Future<void> _cerrarSelector(WidgetTester tester) async {
  final cerrar = find.byTooltip('Cerrar selector');
  await tester.ensureVisible(cerrar);
  await tester.pumpAndSettle();
  await tester.tap(cerrar);
  await tester.pumpAndSettle();
}

Future<void> _revelarEnLista(WidgetTester tester, Finder objetivo) async {
  final lista = find.descendant(
    of: find.byType(ListView),
    matching: find.byType(Scrollable),
  );
  await tester.scrollUntilVisible(objetivo, 120, scrollable: lista.first);
  await tester.ensureVisible(objetivo);
  await tester.pumpAndSettle();
}

Future<void> _irAInicioLista(WidgetTester tester) async {
  final lista = find.descendant(
    of: find.byType(ListView),
    matching: find.byType(Scrollable),
  );
  final estado = tester.state<ScrollableState>(lista.first);
  estado.position.jumpTo(0);
  await tester.pumpAndSettle();
}

Future<void> _marcarOpcion(WidgetTester tester, String nombre) async {
  final opcion = find.widgetWithText(CheckboxListTile, nombre);
  await _revelarEnLista(tester, opcion);
  await tester.tap(opcion);
  await tester.pumpAndSettle();
}

Future<void> _seleccionarEnDropdown(
  WidgetTester tester,
  List<String> nombres, {
  String filtro = 'Escala',
}) async {
  await _abrirSelector(tester);
  final chip = find.widgetWithText(ChoiceChip, filtro);
  await tester.ensureVisible(chip);
  await tester.pumpAndSettle();
  await tester.tap(chip);
  await tester.pumpAndSettle();
  for (final nombre in nombres) {
    await _marcarOpcion(tester, nombre);
  }
}

void main() {
  testWidgets('temperatura 40.0 muestra el indicador crítico en vivo', (
    tester,
  ) async {
    _taller(tester);
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    final (base, _) = await _baseConDatos(cifrado);
    await tester.pumpWidget(_pantalla(cifrado, base));
    await tester.pumpAndSettle();

    expect(find.text('Todo parece normal'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), '40.0');
    await tester.pumpAndSettle();

    expect(find.text('Se recomienda atención urgente'), findsOneWidget);
    expect(
      find.text('Contacta al equipo de salud inmediatamente'),
      findsOneWidget,
    );
    expect(find.text('• Fiebre alta (40.0°C)'), findsOneWidget);
  });

  testWidgets(
    'guardar cifra observaciones, conserva el nivel crítico y confirma',
    (tester) async {
      _taller(tester);
      final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
      final (base, firestore) = await _baseConDatos(cifrado);
      await tester.pumpWidget(_pantalla(cifrado, base));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), '40.0');
      await tester.enterText(find.byType(TextField).at(4), 'fiebre alta');
      await tester.pumpAndSettle();
      await _tocarGuardar(tester);

      expect(find.text('Guardado correctamente'), findsOneWidget);

      final idPaciente = await _idPacienteUnico(firestore);
      final registros = await firestore
          .collection('users')
          .doc(_uid)
          .collection('patients')
          .doc(idPaciente)
          .collection('clinicalRecords')
          .get();
      final doc = registros.docs.single.data();
      expect(doc['nivelAlerta'], 'critico');
      expect(
        doc.containsKey('observaciones'),
        isFalse,
        reason: 'las observaciones deben viajar cifradas',
      );
      final cifradoTexto = doc['contenido_registro_cifrado'] as String;
      expect(await cifrado.descifrar(_uid, cifradoTexto), 'fiebre alta');
      expect(
        doc.containsKey('signosVitales'),
        isFalse,
        reason: 'los signos vitales no deben viajar en claro',
      );
      expect(
        doc.containsKey('sintomas'),
        isFalse,
        reason: 'los síntomas no deben viajar en claro',
      );
      final signosCifrados = doc['signos_vitales_cifrado'] as String;
      final signosMapa = jsonDecode(
        await cifrado.descifrar(_uid, signosCifrados),
      ) as Map<String, dynamic>;
      expect(
        (signosMapa['temperature'] as num).toDouble(),
        40.0,
        reason: 'la temperatura debe hacer round-trip cifrada',
      );
      final sintomas = await _sintomasDescifrados(cifrado, doc);
      expect(sintomas, isEmpty, reason: 'sin síntomas no se persiste nada');
    },
  );

  testWidgets('sin paciente seleccionado avisa y no guarda', (tester) async {
    _taller(tester);
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    final (base, firestore) = await _baseConDatos(cifrado, conPaciente: false);
    await tester.pumpWidget(_pantalla(cifrado, base));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '38.0');
    await tester.pumpAndSettle();
    await _tocarGuardar(tester);

    expect(find.text('No hay paciente seleccionado'), findsOneWidget);
    final sinPacientes = await firestore
        .collection('users')
        .doc(_uid)
        .collection('patients')
        .get();
    expect(sinPacientes.docs, isEmpty);
  });

  testWidgets('con el tope diario alcanzado el guardado fuerza "extra"', (
    tester,
  ) async {
    _taller(tester);
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    final (base, firestore) = await _baseConDatos(cifrado);
    final idPaciente = await _idPacienteUnico(firestore);
    final ahora = DateTime.now();
    for (var i = 1; i <= 3; i++) {
      await base.guardarRegistroClinico(
        idPaciente,
        RegistroClinico(
          id: 'p$i',
          pacienteId: idPaciente,
          fecha: ahora,
          creadoEn: ahora,
          tipoRegistro: 'programado',
        ),
      );
    }
    await tester.pumpWidget(_pantalla(cifrado, base));
    await tester.pumpAndSettle();

    expect(
      find.text('Programado 3/3'),
      findsOneWidget,
      reason: 'el botón programado muestra el tope alcanzado',
    );

    await _tocarGuardar(tester);
    expect(find.text('Guardado correctamente'), findsOneWidget);

    final registros = await firestore
        .collection('users')
        .doc(_uid)
        .collection('patients')
        .doc(idPaciente)
        .collection('clinicalRecords')
        .get();
    final extras = registros.docs
        .where((d) => d.data()['tipoRegistro'] == 'extra')
        .toList();
    expect(
      extras,
      hasLength(1),
      reason: 'el cuarto registro del día debe quedar como "extra"',
    );
  });

  testWidgets('saturación sobre 100% no guarda y avisa del rango', (
    tester,
  ) async {
    _taller(tester);
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    final (base, firestore) = await _baseConDatos(cifrado);
    final idPaciente = await _idPacienteUnico(firestore);
    await tester.pumpWidget(_pantalla(cifrado, base));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(2), '105');
    await tester.pumpAndSettle();
    await _tocarGuardar(tester);

    expect(
      find.text('Saturación de O₂ debe estar entre 50 y 100%'),
      findsOneWidget,
      reason: 'el guardado debe bloquearse por rango inválido',
    );
    final registros = await firestore
        .collection('users')
        .doc(_uid)
        .collection('patients')
        .doc(idPaciente)
        .collection('clinicalRecords')
        .get();
    expect(registros.docs, isEmpty, reason: 'no debe guardarse nada');
  });

  testWidgets(
    'el cuestionario ESAS-r aparece con anclas y guarda también intensidad 0',
    (tester) async {
      _taller(tester);
      final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
      final (base, firestore) = await _baseConDatos(cifrado);
      final idPaciente = await _idPacienteUnico(firestore);
      await tester.pumpWidget(_pantalla(cifrado, base));
      await tester.pumpAndSettle();

      expect(find.text('Evaluación de síntomas (ESAS-r)'), findsOneWidget);

      await _seleccionarEnDropdown(tester, ['Dolor'], filtro: 'Escala');
      await _cerrarSelector(tester);

      expect(find.text('1 seleccionados'), findsOneWidget);
      expect(find.text('Nada de dolor'), findsOneWidget);
      expect(find.text('El peor dolor posible'), findsOneWidget);
      expect(
        find.text('Mínimo síntoma'),
        findsOneWidget,
        reason: 'la píldora resume icono + etiqueta + valor',
      );
      expect(
        find.text('0/10'),
        findsOneWidget,
        reason: 'la píldora resume icono + etiqueta + valor',
      );

      await _tocarGuardar(tester);
      expect(find.text('Guardado correctamente'), findsOneWidget);

      var registros = await firestore
          .collection('users')
          .doc(_uid)
          .collection('patients')
          .doc(idPaciente)
          .collection('clinicalRecords')
          .get();
      var doc = registros.docs.single.data();
      expect(
        doc.containsKey('sintomas'),
        isFalse,
        reason: 'los síntomas no deben viajar en claro',
      );
      expect(
        doc.containsKey('signosVitales'),
        isFalse,
        reason: 'sin signos ingresados no se escribe el campo',
      );
      var sintomas = await _sintomasDescifrados(cifrado, doc);
      var dolorGuardado =
          sintomas.singleWhere((s) => s['name'] == 'Dolor');
      expect(
        dolorGuardado['intensity'],
        0,
        reason: 'una intensidad 0 seleccionada también se persiste',
      );

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      await _seleccionarEnDropdown(tester, ['Dolor'], filtro: 'Escala');
      await _cerrarSelector(tester);

      final slider = find.byType(Slider).first;
      await tester.ensureVisible(slider);
      await tester.pumpAndSettle();
      final rect = tester.getRect(slider);
      await tester.tapAt(Offset(rect.right - 5, rect.center.dy));
      await tester.pumpAndSettle();

      await _tocarGuardar(tester);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      registros = await firestore
          .collection('users')
          .doc(_uid)
          .collection('patients')
          .doc(idPaciente)
          .collection('clinicalRecords')
          .get();
      final intensidades = <int>[];
      for (final r in registros.docs) {
        final lista = await _sintomasDescifrados(cifrado, r.data());
        for (final s in lista) {
          if (s['name'] == 'Dolor') {
            intensidades.add(s['intensity'] as int);
          }
        }
      }
      expect(
        intensidades,
        containsAll([0, 10]),
        reason: 'el primer registro guarda el 0 y el segundo el 10',
      );
    },
  );

  testWidgets('"Otro problema" guarda nombre personalizado en notes', (
    tester,
  ) async {
    _taller(tester);
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    final (base, firestore) = await _baseConDatos(cifrado);
    final idPaciente = await _idPacienteUnico(firestore);
    await tester.pumpWidget(_pantalla(cifrado, base));
    await tester.pumpAndSettle();

    await _seleccionarEnDropdown(tester, ['Otro problema'], filtro: 'Escala');
    await _cerrarSelector(tester);

    expect(find.text('1 seleccionados'), findsOneWidget);
    expect(
      find.text('Mínimo síntoma'),
      findsOneWidget,
      reason: '"Otro problema" arranca con intensidad 0 como cualquier síntoma',
    );
    expect(
      find.text('0/10'),
      findsOneWidget,
      reason: '"Otro problema" arranca con intensidad 0 como cualquier síntoma',
    );

    final campoOtro = find.widgetWithText(
      TextField,
      'Describe el problema (por ej: sequedad de boca)',
    );
    await tester.ensureVisible(campoOtro);
    await tester.pumpAndSettle();
    await tester.enterText(campoOtro, 'Sequedad de boca');
    await tester.pumpAndSettle();

    final sliderOtro = find.byType(Slider).first;
    await tester.ensureVisible(sliderOtro);
    await tester.pumpAndSettle();
    final rect = tester.getRect(sliderOtro);
    await tester.tapAt(Offset(rect.right - 5, rect.center.dy));
    await tester.pumpAndSettle();

    await _tocarGuardar(tester);
    expect(find.text('Guardado correctamente'), findsOneWidget);

    final registros = await firestore
        .collection('users')
        .doc(_uid)
        .collection('patients')
        .doc(idPaciente)
        .collection('clinicalRecords')
        .get();
    final doc = registros.docs.single.data();
    expect(
      doc.containsKey('sintomas'),
      isFalse,
      reason: 'los síntomas no deben viajar en claro',
    );
    final sintomas = await _sintomasDescifrados(cifrado, doc);
    final otro = sintomas.singleWhere((s) => s['name'] == 'Otro problema');
    expect(otro['intensity'], 10);
    expect(
      otro['notes'],
      'Sequedad de boca',
      reason: 'las notas viajan dentro del síntoma cifrado',
    );
  });

  testWidgets('"Otro problema" sin texto no se persiste', (tester) async {
    _taller(tester);
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    final (base, firestore) = await _baseConDatos(cifrado);
    final idPaciente = await _idPacienteUnico(firestore);
    await tester.pumpWidget(_pantalla(cifrado, base));
    await tester.pumpAndSettle();

    await _seleccionarEnDropdown(tester, ['Otro problema'], filtro: 'Escala');
    await _cerrarSelector(tester);
    await _tocarGuardar(tester);
    expect(find.text('Guardado correctamente'), findsOneWidget);

    final registros = await firestore
        .collection('users')
        .doc(_uid)
        .collection('patients')
        .doc(idPaciente)
        .collection('clinicalRecords')
        .get();
    final doc = registros.docs.single.data();
    final sintomas = await _sintomasDescifrados(cifrado, doc);
    expect(
      sintomas,
      isEmpty,
      reason: '"Otro problema" solo persiste con su texto de notas',
    );
  });

  testWidgets('"Agregar +" añade un síntoma personalizado y se persiste', (
    tester,
  ) async {
    _taller(tester);
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    final (base, firestore) = await _baseConDatos(cifrado);
    final idPaciente = await _idPacienteUnico(firestore);
    await tester.pumpWidget(_pantalla(cifrado, base));
    await tester.pumpAndSettle();

    await _abrirSelector(tester);

    final campoAgregar = find.widgetWithText(TextField, 'Agregar síntoma…');
    await tester.ensureVisible(campoAgregar);
    await tester.pumpAndSettle();
    await tester.enterText(campoAgregar, 'Comezón');
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    final fila = find.widgetWithText(CheckboxListTile, 'Comezón');
    await _revelarEnLista(tester, fila);
    expect(fila, findsOneWidget);
    expect(
      tester.widget<CheckboxListTile>(fila).value,
      isTrue,
      reason: 'el ítem agregado queda marcado en la lista del selector',
    );

    await _cerrarSelector(tester);

    expect(
      find.byType(Slider),
      findsOneWidget,
      reason: 'el síntoma personalizado genera su fila de intensidad',
    );
    expect(
      find.text('Comezón'),
      findsOneWidget,
      reason: 'la fila de intensidad muestra el nombre agregado',
    );

    await _tocarGuardar(tester);
    expect(find.text('Guardado correctamente'), findsOneWidget);

    final registros = await firestore
        .collection('users')
        .doc(_uid)
        .collection('patients')
        .doc(idPaciente)
        .collection('clinicalRecords')
        .get();
    final doc = registros.docs.single.data();
    expect(
      doc.containsKey('sintomas'),
      isFalse,
      reason: 'los síntomas no deben viajar en claro',
    );
    final sintomas = await _sintomasDescifrados(cifrado, doc);
    final comezon = sintomas.singleWhere((s) => s['name'] == 'Comezón');
    expect(comezon['intensity'], 0);
  });

  testWidgets('"Listo" cierra el selector y conserva la selección', (
    tester,
  ) async {
    _taller(tester);
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    final (base, _) = await _baseConDatos(cifrado);
    await tester.pumpWidget(_pantalla(cifrado, base));
    await tester.pumpAndSettle();

    await _seleccionarEnDropdown(tester, ['Dolor']);
    expect(find.byType(SelectorMultiSintoma), findsOneWidget);
    expect(find.text('Listo'), findsOneWidget);

    await tester.ensureVisible(find.text('Listo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();

    expect(find.byType(SelectorMultiSintoma), findsNothing);
    expect(find.text('1 seleccionados'), findsOneWidget);
  });

  testWidgets('el selector abre en "Generales" y cada chip filtra la lista', (
    tester,
  ) async {
    _taller(tester);
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    final (base, _) = await _baseConDatos(cifrado);
    await tester.pumpWidget(_pantalla(cifrado, base));
    await tester.pumpAndSettle();

    await _abrirSelector(tester);

    final chipGenerales = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Generales'),
    );
    expect(
      chipGenerales.selected,
      isTrue,
      reason: 'el filtro inicial debe ser "Generales"',
    );
    expect(find.text('Fatiga o cansancio'), findsOneWidget);
    expect(
      find.text('Vómitos'),
      findsNothing,
      reason: 'Vómitos solo pertenece a Tumores SNC y su nombre no se duplica',
    );

    final chipTodos = find.widgetWithText(ChoiceChip, 'Todos');
    await tester.ensureVisible(chipTodos);
    await tester.pumpAndSettle();
    await tester.tap(chipTodos);
    await tester.pumpAndSettle();

    expect(find.text('Dolor'), findsOneWidget);
    await _revelarEnLista(tester, find.text('Vómitos'));
    expect(find.text('Vómitos'), findsOneWidget);

    final chipEscala = find.widgetWithText(ChoiceChip, 'Escala');
    await tester.ensureVisible(chipEscala);
    await tester.pumpAndSettle();
    await tester.tap(chipEscala);
    await _irAInicioLista(tester);
    expect(
      find.byType(CheckboxListTile),
      findsNWidgets(11),
      reason: '"Escala" muestra exactamente los 11 ítems del ESAS-r',
    );
    await _revelarEnLista(tester, find.text('Dolor'));
    expect(find.text('Dolor'), findsOneWidget);
    await _revelarEnLista(tester, find.text('Otro problema'));
    expect(find.text('Otro problema'), findsOneWidget);
    expect(find.text('Vómitos'), findsNothing);

    final chipLla = find.widgetWithText(ChoiceChip, 'LLA');
    await tester.ensureVisible(chipLla);
    await tester.pumpAndSettle();
    await tester.tap(chipLla);
    await _irAInicioLista(tester);

    await _revelarEnLista(tester, find.text('Dolor de huesos y articulaciones'));
    expect(find.text('Dolor de huesos y articulaciones'), findsOneWidget);
    expect(find.text('Vómitos'), findsNothing);

    final chipLinfoma = find.widgetWithText(ChoiceChip, 'Linfoma');
    await tester.ensureVisible(chipLinfoma);
    await tester.pumpAndSettle();
    await tester.tap(chipLinfoma);
    await _irAInicioLista(tester);

    await _revelarEnLista(tester, find.text('Sudoración nocturna'));
    expect(find.text('Sudoración nocturna'), findsOneWidget);
    expect(find.text('Dolor de cabeza (cefalea)'), findsNothing);

    final chipTodosVuelta = find.widgetWithText(ChoiceChip, 'Todos');
    await tester.ensureVisible(chipTodosVuelta);
    await tester.pumpAndSettle();
    await tester.tap(chipTodosVuelta);
    await tester.pumpAndSettle();

    await _revelarEnLista(tester, find.text('Vómitos'));
    expect(find.text('Vómitos'), findsOneWidget);

    await _cerrarSelector(tester);
  });

  test(
    'catalogoUnificado no duplica nombres e incluye los 11 ESAS verbatim',
    () {
      final nombres = catalogoUnificado.map((s) => s.nombre).toList();
      expect(
        nombres.length,
        nombres.toSet().length,
        reason: 'no debe haber nombres duplicados',
      );

      final nombresEsas = catalogoEsasR.map((s) => s.nombre).toList();
      for (final nombre in nombresEsas) {
        expect(nombres, contains(nombre));
      }
      final primeros11 = nombres.take(11).toList();
      expect(primeros11, nombresEsas);

      expect(
        catalogoUnificado.where((s) => s.nombre == 'Dolor'),
        hasLength(1),
        reason: 'Dolor solo puede aparecer una vez',
      );
      expect(
        catalogoUnificado.where((s) => s.nombre == 'Náuseas'),
        hasLength(1),
        reason: 'Náuseas solo puede aparecer una vez',
      );
      final otro = catalogoUnificado.singleWhere(
        (s) => s.nombre == 'Otro problema',
      );
      expect(otro.esOtro, isTrue);
    },
  );

  testWidgets('el campo resume la selección como "{n} seleccionados"', (
    tester,
  ) async {
    _taller(tester);
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    final (base, _) = await _baseConDatos(cifrado);
    await tester.pumpWidget(_pantalla(cifrado, base));
    await tester.pumpAndSettle();

    expect(find.text('Selecciona los síntomas…'), findsOneWidget);

    await _seleccionarEnDropdown(tester, ['Dolor', 'Cansancio']);
    await _cerrarSelector(tester);

    expect(find.text('2 seleccionados'), findsOneWidget);

    expect(
      find.text('Selecciona los síntomas…'),
      findsNothing,
      reason: 'el campo muestra el resumen en lugar del placeholder',
    );
    expect(
      find.byType(SelectorMultiSintoma),
      findsNothing,
      reason: 'el selector es un modal y al cerrarse sale del árbol',
    );
  });

  group('EntradaSintoma.iconoPara', () {
    test('mapea la intensidad a un emoticono por tramo', () {
      expect(EntradaSintoma.iconoPara(0), Icons.sentiment_very_satisfied);
      expect(EntradaSintoma.iconoPara(2), Icons.sentiment_satisfied);
      expect(EntradaSintoma.iconoPara(3), Icons.sentiment_dissatisfied);
      expect(EntradaSintoma.iconoPara(5), Icons.sentiment_very_dissatisfied);
      expect(EntradaSintoma.iconoPara(8), Icons.sentiment_very_dissatisfied);
      expect(EntradaSintoma.iconoPara(10), Icons.sentiment_very_dissatisfied);
    });
  });
}
