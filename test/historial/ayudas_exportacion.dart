import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart' as xlsx;
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oncuidar/caracteristicas/historial/historial.dart';
import 'package:oncuidar/core/proveedores/proveedores.dart';
import 'package:oncuidar/core/servicios/servicio_base_datos.dart';
import 'package:oncuidar/core/servicios/servicio_cifrado.dart';
import 'package:oncuidar/modelos/paciente.dart';
import 'package:oncuidar/modelos/registro_clinico.dart';

const clavePrueba = 'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';
const uidPrueba = 'uid-1';

MockFirebaseAuth authPrueba() => MockFirebaseAuth(
  mockUser: MockUser(uid: uidPrueba, email: 'cuidador@test.cl'),
);

RegistroClinico registroDe(String id, String idPaciente, DateTime momento) =>
    RegistroClinico(
      id: id,
      pacienteId: idPaciente,
      fecha: momento,
      creadoEn: momento,
      tipoRegistro: 'programado',
      observaciones: 'obs-$id',
    );

Future<(ServicioBaseDatos, ServicioCifrado, String activo, String otro)>
baseConDosPacientes() async {
  final cifrado = ServicioCifrado(clavePrueba: clavePrueba);
  await cifrado.fijarClave(uidPrueba, clavePrueba);
  final base = ServicioBaseDatos(
    base: FakeFirebaseFirestore(),
    uidPrueba: uidPrueba,
    cifrado: cifrado,
  );
  await base.crearCuidador({
    'displayName': 'Ana Torres',
    'email': 'cuidador@test.cl',
    'phone': '+56 9 1111 1111',
    'relationship': 'Madre',
    'address': 'Av. Siempre Viva 742',
  });
  final activo = await base.crearPaciente(
    Paciente(id: '', fullName: 'Paciente A', createdAt: DateTime(2026, 1, 1)),
  );
  final otro = await base.crearPaciente(
    Paciente(id: '', fullName: 'Paciente B', createdAt: DateTime(2026, 1, 2)),
  );
  return (base, cifrado, activo, otro);
}

class PacienteActivoFijo extends SelectedPatientNotifier {
  PacienteActivoFijo(this.idActivo);

  final String? idActivo;

  @override
  String? build() => idActivo;
}

Widget pantallaHistorial(
  ServicioBaseDatos base,
  ServicioCifrado cifrado, {
  required String pacienteActivo,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (c, s) => const HistorialScreen()),
      GoRoute(
        path: '/dashboard',
        builder: (c, s) =>
            const Scaffold(body: Center(child: Text('Dashboard'))),
      ),
      GoRoute(
        path: '/registro-clinico',
        builder: (c, s) =>
            const Scaffold(body: Center(child: Text('Registro clínico abierto'))),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      firebaseAuthProvider.overrideWithValue(authPrueba()),
      servicioCifradoProvider.overrideWithValue(cifrado),
      servicioBaseDatosProvider.overrideWith((_) => base),
      selectedPatientIdProvider.overrideWith(
        () => PacienteActivoFijo(pacienteActivo),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void tallerDePrueba(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

List<String> instalarCanalesDeExportacion() {
  final compartidos = <String>[];
  final temporal = Directory.systemTemp.createTempSync('oncuidar_exportacion');
  sembrarFuentesEnDisco(temporal);

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => temporal.path,
      );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/share'),
        (call) async {
          final args = call.arguments as Map<Object?, Object?>;
          compartidos.addAll((args['paths'] as List<Object?>).cast<String>());
          return 'compartido';
        },
      );
  return compartidos;
}

void sembrarFuentesEnDisco(Directory destino) {
  for (final peso in _variantesDeNunito) {
    for (final hash in _hashesDeNunito) {
      File('${destino.path}${Platform.pathSeparator}Nunito_${peso}_$hash.ttf')
          .writeAsBytesSync(Uint8List.fromList([0, 1, 0, 0]));
    }
  }
}

const _variantesDeNunito = [
  'regular',
  'italic',
  '100',
  '100italic',
  '200',
  '200italic',
  '300',
  '300italic',
  '400',
  '400italic',
  '500',
  '500italic',
  '600',
  '600italic',
  '700',
  '700italic',
  '800',
  '800italic',
  '900',
  '900italic',
];

const _hashesDeNunito = [
  '8d32053d727702a77e28b4104b53fb30333f146ef22ed73ebae6a509f94d885c',
  '6f96017e762896b4cf3c2db345d41d7a72a3720a95698c3cd47020bf433db435',
  '1f6452d3509db129d3468088c1c952f1a844b6dc865703a09595fc53700a6251',
  'f165190d31319dc6384c83fdd014ed983630541b21d005b5caadf1d74fbd513d',
  '8148a236e4127dad38346ce596c544389aa2fdaaa9f311e589741de30d25ddb8',
  '43364ac2d05d1033b5e255ce77e4d84d2f6467bfadb5e5985ca4e688949e73bf',
  'a5ddd59da28c281984ae3bd12aa3b9af3b204e61156e50f1108d5fcf71aa5665',
  '00fe8a871f3548a3d11273596486ff1c30328c3e6853d2f43f0e72c75802b24a',
  'd49777748d078c1787b1f8e9d14317a0cf4510039c86ebee7b74a037d4758b00',
  'df3c491d67e881e1b0c6265a7a8364f07e38d7a25893e9b2beac1439e1c2efd9',
  '56984ce135b93b61a7e1176b810c8afbaafbcdce625fca628b73dc16139f7a7a',
  'a5337453969dd598f31a7bfd0bb8c66aece01b0f7d5bffa9f2d1d2eb020ae9f9',
  '1d9670625be9c432a93d3467f99c5aa3e5626181c27d6d9a27285781539dfd83',
  '170f35fc695e39b13b53b58452f1a9e334277f3633c4ab89346db743b6b4923f',
  '3fff73610e77b1bca1edd861e4830865d147de46cffc685fb253cb050b1148a5',
];

Future<Uint8List> exportarDesdeLaPantalla(
  WidgetTester tester,
  String boton,
  List<String> compartidos,
) async {
  await tester.tap(find.byTooltip(boton));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('botonCompartirExportacion')));
  for (var vuelta = 0; vuelta < 50 && compartidos.isEmpty; vuelta++) {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
  }
  expect(
    compartidos,
    hasLength(1),
    reason: 'debería haberse compartido un archivo',
  );
  final leido = await tester.runAsync(
    () => File(compartidos.single).readAsBytes(),
  );
  expect(leido, isNotNull);
  return leido!;
}

String textoPdf(Uint8List bytes) => fragmentosPdf(bytes).join();

List<String> fragmentosPdf(Uint8List bytes) {
  final palabras = <String>[];
  for (final trozo in _trozosDelPdf(bytes)) {
    for (final operador in RegExp(
      r'\[(.*?)\]\s*TJ|\((?:\\.|[^\\()])*\)\s*Tj',
      dotAll: true,
    ).allMatches(trozo)) {
      if (operador.group(1) == null) {
        palabras.add(_sinParentesis(operador.group(0)!));
        continue;
      }
      for (final palabra in RegExp(
        r'\((?:\\.|[^\\()])*\)',
      ).allMatches(operador.group(1)!)) {
        palabras.add(_sinParentesis(palabra.group(0)!));
      }
    }
  }
  return palabras;
}

List<String> _trozosDelPdf(Uint8List bytes) {
  final crudo = latin1.decode(bytes, allowInvalid: true);
  final trozos = <String>[crudo];
  for (final bloque in RegExp(
    r'stream\r?\n(.*?)endstream',
    dotAll: true,
  ).allMatches(crudo)) {
    try {
      final inflado = zlib.decode(latin1.encode(bloque.group(1)!));
      trozos.add(latin1.decode(inflado, allowInvalid: true));
    } catch (_) {
      continue;
    }
  }
  return trozos;
}

String _sinParentesis(String operandos) {
  final limites = operandos.indexOf('(');
  final cuerpo = limites < 0
      ? operandos
      : operandos.substring(limites + 1, operandos.lastIndexOf(')'));
  return cuerpo
      .replaceAll(r'\(', '(')
      .replaceAll(r'\)', ')')
      .replaceAll(r'\\', r'\');
}

List<String> observacionesPdf(Uint8List bytes, {required String prefijo}) {
  final patron = RegExp('^$prefijo-[A-Za-z0-9-]+\$');
  return [
    for (final fragmento in fragmentosPdf(bytes))
      if (patron.hasMatch(fragmento.trim())) fragmento.trim(),
  ];
}

List<String> fechasEsperadasEnPdf(Uint8List bytes, Set<String> esperadas) {
  final etiqueta = RegExp(r'^[A-Za-z]+-\d{4}-\d{2}-\d{2}$');
  final texto = fragmentosPdf(
    bytes,
  ).map((f) => etiqueta.hasMatch(f.trim()) ? ' ' : f).join();
  return RegExp(r'\d{2}-\d{2}-\d{4}')
      .allMatches(texto)
      .map((m) => m.group(0)!)
      .where(esperadas.contains)
      .toList();
}

List<String> observacionesExcel(Uint8List bytes) {
  final hoja = xlsx.Excel.decodeBytes(bytes)['Historial'];
  final filas = hoja.rows;
  final encabezado = filas.indexWhere(
    (f) => f.isNotEmpty && f.first?.value.toString() == 'Fecha',
  );
  return [
    for (final fila in filas.skip(encabezado + 1))
      if (fila.length > 9 && fila[9] != null) fila[9]!.value.toString(),
  ];
}
