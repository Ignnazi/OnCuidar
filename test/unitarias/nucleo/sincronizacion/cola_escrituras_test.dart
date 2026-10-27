import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/nucleo/sincronizacion/cola_escrituras.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../ayudas/offline.dart';

void main() {
  late ColaEscrituras cola;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cola = ColaEscrituras();
  });

  List<String> ids(List<EscrituraPendiente> lista) => [
    for (final e in lista) e.id,
  ];

  test('guarda las escrituras en el orden en que llegan', () async {
    for (final id in ['e1', 'e2', 'e3']) {
      await cola.encolar('u1', escrituraDe(id: id));
    }
    expect(ids(await cola.pendientes('u1')), ['e1', 'e2', 'e3']);
  });

  test('las escrituras siguen ahí al volver a abrir la app', () async {
    await cola.encolar('u1', escrituraDe(id: 'e1'));
    final otraSesion = ColaEscrituras();
    expect(ids(await otraSesion.pendientes('u1')), ['e1']);
  });

  test('cada usuario tiene su propia cola', () async {
    await cola.encolar('u1', escrituraDe(id: 'e1'));
    expect(await cola.pendientes('u2'), isEmpty);
  });

  test('no acepta datos clínicos sin cifrar', () {
    expect(
      () => cola.encolar(
        'u1',
        escrituraDe(datos: {'paciente_id': 'p1', 'observaciones': 'en claro'}),
      ),
      throwsArgumentError,
    );
  });

  test('quitar saca solo la escritura indicada', () async {
    await cola.encolar('u1', escrituraDe(id: 'e1'));
    await cola.encolar('u1', escrituraDe(id: 'e2'));
    await cola.quitar('u1', 'e1');
    expect(ids(await cola.pendientes('u1')), ['e2']);
  });

  test('cuenta los intentos de cada escritura', () async {
    await cola.encolar('u1', escrituraDe(id: 'e1'));
    expect(await cola.registrarIntento('u1', 'e1'), 1);
    expect(await cola.registrarIntento('u1', 'e1'), 2);
  });

  test('una escritura fallida se puede reintentar desde cero', () async {
    await cola.encolar('u1', escrituraDe(id: 'e1'));
    await cola.registrarIntento('u1', 'e1');
    await cola.moverAFallidas('u1', 'e1');
    expect(await cola.resumen('u1'), const ResumenCola(fallidas: 1));

    await cola.reintentarFallidas('u1');
    final pendientes = await cola.pendientes('u1');
    expect(ids(pendientes), ['e1']);
    expect(pendientes.single.intentos, 0);
  });

  test('al borrar un paciente se quitan sus escrituras', () async {
    await cola.encolar('u1', escrituraDe(id: 'e1', pacienteId: 'p1'));
    await cola.encolar('u1', escrituraDe(id: 'e2', pacienteId: 'p2'));
    await cola.quitarDePaciente('u1', 'p1');
    expect(ids(await cola.pendientes('u1')), ['e2']);
  });

  test('encolar varias escrituras a la vez no pierde ninguna', () async {
    await Future.wait([
      for (var i = 0; i < 20; i++) cola.encolar('u1', escrituraDe(id: 'e$i')),
    ]);
    expect(await cola.pendientes('u1'), hasLength(20));
  });
}
