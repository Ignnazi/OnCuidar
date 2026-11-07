import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/biblioteca/datos/proveedores_biblioteca.dart';
import 'package:oncuidar/caracteristicas/biblioteca/datos/servicio_cache_contenido.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/estado_descarga_contenido.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/material_educativo.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/proveedores_biblioteca.dart';
import 'package:oncuidar/nucleo/proveedores.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CacheQueFalla implements ServicioCacheContenido {
  int intentos = 0;

  @override
  Future<bool> archivoDescargado(String url) async => false;

  @override
  Future<File> descargar(
    String url, {
    int? tamanoBytes,
    void Function(int descargado, int? total)? alProgresar,
  }) async {
    intentos++;
    throw const HttpException('404');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MaterialEducativo _material(String url) => MaterialEducativo(
  id: 'm1',
  titulo: 'Manual',
  categoria: 'Guías',
  tema: 'General',
  cuerpo: '',
  urlArchivo: url,
  creadoEn: DateTime(2026),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('el aviso de archivos pendientes se oculta solo', (tester) async {
    final contenedor = ProviderContainer(
      overrides: [
        servicioCacheContenidoProvider.overrideWithValue(_CacheQueFalla()),
        estadoConexionProvider.overrideWith((ref) => Stream.value(true)),
        estadoAutenticacionProvider.overrideWith((ref) => Stream.value(null)),
      ],
    );
    addTearDown(contenedor.dispose);
    final notificador = contenedor.read(
      sincronizacionBibliotecaProvider.notifier,
    );

    await notificador.sincronizar([_material('https://x/manual.pdf')]);
    expect(
      contenedor.read(sincronizacionBibliotecaProvider).fase,
      FaseDescarga.conErrores,
    );

    await tester.pump(const Duration(seconds: 10));
    final estado = contenedor.read(sincronizacionBibliotecaProvider);
    expect(estado.fase, FaseDescarga.ninguna);
    expect(estado.fallidas, 1);
  });

  testWidgets('reintenta los pendientes al reconectar tras ocultar el aviso', (
    tester,
  ) async {
    final cache = _CacheQueFalla();
    final conexion = StreamController<bool>();
    addTearDown(conexion.close);
    final contenedor = ProviderContainer(
      overrides: [
        servicioCacheContenidoProvider.overrideWithValue(cache),
        estadoConexionProvider.overrideWith((ref) => conexion.stream),
        estadoAutenticacionProvider.overrideWith((ref) => Stream.value(null)),
      ],
    );
    addTearDown(contenedor.dispose);
    final notificador = contenedor.read(
      sincronizacionBibliotecaProvider.notifier,
    );
    contenedor.listen(estadoConexionProvider, (_, _) {});

    await notificador.sincronizar([_material('https://x/manual.pdf')]);
    await tester.pump(const Duration(seconds: 10));
    expect(
      contenedor.read(sincronizacionBibliotecaProvider).fase,
      FaseDescarga.ninguna,
    );
    expect(cache.intentos, 1);

    conexion.add(false);
    await tester.pump();
    conexion.add(true);
    await tester.pump();
    await tester.pump();

    expect(cache.intentos, 2);
    await tester.pump(const Duration(seconds: 10));
  });
}
