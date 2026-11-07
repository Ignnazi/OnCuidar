import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/perfil/presentacion/cerrar_sesion.dart';

void main() {
  test('sin pendientes solo pide confirmar', () {
    expect(mensajeCerrarSesion(0), '¿Seguro que deseas cerrar tu sesión?');
  });

  test('con pendientes avisa que se enviarán al volver a entrar', () {
    expect(
      mensajeCerrarSesion(1),
      '¿Seguro que deseas cerrar tu sesión?\n\n'
      'Tienes 1 cambio sin enviar. Queda guardado en el teléfono y se enviará '
      'cuando vuelvas a entrar con esta cuenta.',
    );
    expect(
      mensajeCerrarSesion(3),
      '¿Seguro que deseas cerrar tu sesión?\n\n'
      'Tienes 3 cambios sin enviar. Quedan guardados en el teléfono y se '
      'enviarán cuando vuelvas a entrar con esta cuenta.',
    );
  });
}
