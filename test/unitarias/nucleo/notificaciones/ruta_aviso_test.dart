import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/app/enrutador/destino_aviso.dart';
import 'package:oncuidar/nucleo/notificaciones/servicio_notificaciones.dart';

void main() {
  test('el aviso lleva al paciente que lo generó', () {
    final ruta = ServicioNotificaciones.rutaAvisoDe('p 1');
    expect(ruta, '/recordatorios?paciente=p+1');
    expect(destinoInternoSeguro(ruta), ruta);
    expect(Uri.parse(ruta).queryParameters['paciente'], 'p 1');
  });

  test('sin paciente sigue abriendo los recordatorios', () {
    expect(ServicioNotificaciones.rutaAvisoDe(null), '/recordatorios');
  });
}
