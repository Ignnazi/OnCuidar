import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/nucleo/notificaciones/servicio_notificaciones.dart';

void main() {
  test('el aviso es privado en la pantalla bloqueada', () {
    final android = ServicioNotificaciones.detallesAviso.android!;
    expect(android.visibility, NotificationVisibility.private);
    expect(android.channelId, 'recordatorios_channel');
    expect(android.importance, Importance.high);
    expect(android.category, AndroidNotificationCategory.reminder);
  });

  test('en iOS el aviso sigue mostrando alerta, globo y sonido', () {
    final ios = ServicioNotificaciones.detallesAviso.iOS!;
    expect(ios.presentAlert, isTrue);
    expect(ios.presentBadge, isTrue);
    expect(ios.presentSound, isTrue);
  });
}
