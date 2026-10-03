import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/core/servicios/cola_escrituras.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ayudas_offline.dart';

void main() {
  late ColaEscrituras cola;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cola = ColaEscrituras();
  });

  group('Persistencia', () {
    test('las escrituras sobreviven al reinicio de la app', () async {
      await cola.encolar('u1', escrituraDe(id: 'a'));
      await cola.encolar('u1', escrituraDe(id: 'b', encoladoEn: 2));

      final prefs = await SharedPreferences.getInstance();
      final guardado = {
        for (final clave in prefs.getKeys()) clave: prefs.getString(clave)!,
      };
      SharedPreferences.setMockInitialValues(guardado);
      final despuesDelReinicio = ColaEscrituras();

      final pendientes = await despuesDelReinicio.pendientes('u1');
      expect(pendientes.map((e) => e.id), ['a', 'b']);
      expect(pendientes.first.ruta, 'users/u1/patients/p1/recordatorios/c1');
    });

    test('conserva el orden de llegada', () async {
      for (final id in ['1', '2', '3']) {
        await cola.encolar('u1', escrituraDe(id: id));
      }
      expect((await cola.pendientes('u1')).map((e) => e.id), ['1', '2', '3']);
    });

    test('quitar elimina solo la escritura indicada', () async {
      await cola.encolar('u1', escrituraDe(id: 'a'));
      await cola.encolar('u1', escrituraDe(id: 'b'));
      await cola.quitar('u1', 'a');
      expect((await cola.pendientes('u1')).map((e) => e.id), ['b']);
    });

    test('encolar en paralelo no pierde elementos', () async {
      await Future.wait([
        for (var i = 0; i < 20; i++) cola.encolar('u1', escrituraDe(id: 'e$i')),
      ]);
      expect(await cola.pendientes('u1'), hasLength(20));
    });

    test('los intentos se acumulan y persisten', () async {
      await cola.encolar('u1', escrituraDe(id: 'a'));
      expect(await cola.registrarIntento('u1', 'a'), 1);
      expect(await cola.registrarIntento('u1', 'a'), 2);
      expect((await cola.pendientes('u1')).single.intentos, 2);
    });
  });

  group('Aislamiento por cuidador', () {
    test('cada cuidador ve solo su propia cola', () async {
      await cola.encolar('u1', escrituraDe(id: 'de-u1'));
      await cola.encolar('u2', escrituraDe(id: 'de-u2'));
      expect((await cola.pendientes('u1')).map((e) => e.id), ['de-u1']);
      expect((await cola.pendientes('u2')).map((e) => e.id), ['de-u2']);
    });
  });

  group('Fallidas', () {
    test('moverAFallidas saca la escritura de la cola sin perderla', () async {
      await cola.encolar('u1', escrituraDe(id: 'a'));
      await cola.moverAFallidas('u1', 'a');
      expect(await cola.pendientes('u1'), isEmpty);
      expect((await cola.fallidas('u1')).map((e) => e.id), ['a']);
      expect(
        await cola.resumen('u1'),
        const ResumenCola(pendientes: 0, fallidas: 1),
      );
    });

    test('descartarFallidas las elimina', () async {
      await cola.encolar('u1', escrituraDe(id: 'a'));
      await cola.moverAFallidas('u1', 'a');
      await cola.descartarFallidas('u1');
      expect(await cola.fallidas('u1'), isEmpty);
    });
  });

  group('Sin datos clínicos en claro', () {
    test('rechaza campos clínicos sin cifrar', () async {
      for (final campo in ['titulo', 'observaciones', 'sintomas']) {
        await expectLater(
          cola.encolar(
            'u1',
            escrituraDe(datos: {'paciente_id': 'p1', campo: 'texto en claro'}),
          ),
          throwsArgumentError,
          reason: campo,
        );
      }
      expect(await cola.pendientes('u1'), isEmpty);
    });

    test('acepta campos cifrados y permite borrar campos antiguos', () async {
      await cola.encolar(
        'u1',
        escrituraDe(
          operacion: OperacionPendiente.fusionar,
          datos:
              CodecPayload.codificar({
                    'titulo_cifrado': 'a.b.c',
                    'tipo': FieldValue.delete(),
                    'fechaHora': FieldValue.delete(),
                  })
                  as Map<String, dynamic>,
        ),
      );
      expect(await cola.pendientes('u1'), hasLength(1));
    });
  });

  group('CodecPayload', () {
    test('conserva fechas, borrados y estructuras anidadas', () {
      final fecha = DateTime.utc(2026, 10, 1, 8, 30);
      final original = {
        'creadoEn': fecha,
        'signos_vitales_cifrado': FieldValue.delete(),
        'indicesMarcados': [0, 2],
        'anidado': {'fecha': fecha},
      };
      final ida = CodecPayload.codificar(original);
      final vuelta = CodecPayload.decodificar(ida) as Map<String, dynamic>;

      expect(vuelta['creadoEn'], fecha);
      expect(vuelta['signos_vitales_cifrado'], isA<FieldValue>());
      expect(vuelta['indicesMarcados'], [0, 2]);
      expect((vuelta['anidado'] as Map)['fecha'], fecha);
    });
  });
}
