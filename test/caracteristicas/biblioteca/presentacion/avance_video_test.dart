import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/biblioteca/datos/servicio_cache_contenido.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/pantalla_video.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('formatearDuracion', () {
    test('formatea cero, minutos y horas', () {
      expect(formatearDuracion(Duration.zero), '00:00');
      expect(formatearDuracion(const Duration(seconds: 65)), '01:05');
      expect(formatearDuracion(const Duration(seconds: 3599)), '59:59');
      expect(formatearDuracion(const Duration(seconds: 3661)), '1:01:01');
    });
  });

  group('Avance persistente del video (HU-21)', () {
    test('la clave es estable por ruta', () {
      expect(
        claveAvanceVideo('/videos/uno.mp4'),
        claveAvanceVideo('/videos/uno.mp4'),
      );
      expect(
        claveAvanceVideo('/videos/uno.mp4'),
        isNot(claveAvanceVideo('/videos/dos.mp4')),
      );
    });

    test('guarda y devuelve el avance entre sesiones', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await leerAvanceVideo('/videos/a.mp4'), 0);

      await guardarAvanceVideo(
        '/videos/a.mp4',
        const Duration(minutes: 4, seconds: 30),
      );
      expect(await leerAvanceVideo('/videos/a.mp4'), 270000);
    });

    test('posiciones triviales no se guardan', () async {
      SharedPreferences.setMockInitialValues({});
      await guardarAvanceVideo(
        '/videos/b.mp4',
        const Duration(milliseconds: 900),
      );
      expect(await leerAvanceVideo('/videos/b.mp4'), 0);
    });

    test('la pantalla retoma desde el avance guardado con su id', () async {
      SharedPreferences.setMockInitialValues({});
      await guardarAvanceVideo('video-1', const Duration(seconds: 30));
      expect(
        await posicionParaRetomar('video-1', const Duration(minutes: 5)),
        const Duration(seconds: 30),
      );
      expect(
        await posicionParaRetomar('video-2', const Duration(minutes: 5)),
        isNull,
      );
    });

    test('si quedó casi al final reinicia desde el principio', () async {
      SharedPreferences.setMockInitialValues({});
      await guardarAvanceVideo('video-1', const Duration(seconds: 299));
      expect(
        await posicionParaRetomar('video-1', const Duration(minutes: 5)),
        isNull,
      );
    });

    test('cada video mantiene su propio avance', () async {
      SharedPreferences.setMockInitialValues({});
      await guardarAvanceVideo('/videos/c.mp4', const Duration(seconds: 90));
      expect(await leerAvanceVideo('/videos/c.mp4'), 90000);
      expect(await leerAvanceVideo('/videos/d.mp4'), 0);
    });
  });
}
