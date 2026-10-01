import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/core/proveedores/proveedores.dart';
import 'package:oncuidar/core/servicios/servicio_conectividad.dart';

import 'ayudas_offline.dart';

void main() {
  group('ServicioConectividad', () {
    test('sin interfaces de red está sin conexión', () async {
      final servicio = ServicioConectividad(
        consultar: () async => [ConnectivityResult.none],
      );
      expect(await servicio.estaEnLinea(), isFalse);
    });

    test('con wifi o datos móviles está en línea', () async {
      for (final tipo in [ConnectivityResult.wifi, ConnectivityResult.mobile]) {
        final servicio = ServicioConectividad(consultar: () async => [tipo]);
        expect(await servicio.estaEnLinea(), isTrue);
      }
    });

    test('basta una interfaz activa entre varias', () async {
      final servicio = ServicioConectividad(
        consultar: () async => [
          ConnectivityResult.none,
          ConnectivityResult.wifi,
        ],
      );
      expect(await servicio.estaEnLinea(), isTrue);
    });

    test('si la consulta falla se asume en línea para no bloquear', () async {
      final servicio = ServicioConectividad(
        consultar: () async => throw StateError('plugin no disponible'),
      );
      expect(await servicio.estaEnLinea(), isTrue);
    });

    test('el stream emite solo los cambios reales', () async {
      final fuente = StreamController<List<ConnectivityResult>>();
      final servicio = ServicioConectividad(cambios: () => fuente.stream);
      final emitidos = <bool>[];
      final suscripcion = servicio.enLinea().listen(emitidos.add);
      fuente
        ..add([ConnectivityResult.wifi])
        ..add([ConnectivityResult.mobile])
        ..add([ConnectivityResult.none])
        ..add([ConnectivityResult.none])
        ..add([ConnectivityResult.wifi]);
      await Future<void>.delayed(Duration.zero);
      expect(emitidos, [true, false, true]);
      await suscripcion.cancel();
      await fuente.close();
    });
  });

  group('estadoConexionProvider', () {
    test('entrega el estado inicial y sigue los cambios', () async {
      final red = ConectividadFalsa(enLinea: true);
      final contenedor = ProviderContainer(
        overrides: [servicioConectividadProvider.overrideWithValue(red)],
      );
      addTearDown(contenedor.dispose);
      final suscripcion = contenedor.listen(estadoConexionProvider, (_, _) {});
      addTearDown(suscripcion.close);

      await esperarHasta(() async => suscripcion.read().value == true);
      red.fijar(false);
      await esperarHasta(() async => suscripcion.read().value == false);
      red.fijar(true);
      await esperarHasta(() async => suscripcion.read().value == true);
    });
  });
}
