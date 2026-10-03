import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/core/proveedores/proveedores.dart';
import 'package:oncuidar/core/router/destino_aviso.dart';
import 'package:oncuidar/core/servicios/servicio_notificaciones.dart';
import 'package:oncuidar/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ayudas_recordatorios.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    EstadoArranque.reiniciar();
  });
  tearDown(EstadoArranque.reiniciar);

  testWidgets('la app engancha el toque y conserva el aviso que la abrió', (
    tester,
  ) async {
    final notif = NotificacionesFalsas()
      ..payloadLanzamiento = ServicioNotificaciones.rutaAviso;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(MockFirebaseAuth()),
          servicioNotificacionesProvider.overrideWithValue(notif),
        ],
        child: const OncuidarApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(EstadoArranque.destinoPendiente, '/recordatorios');
    expect(EstadoArranque.consumirDestino(), '/recordatorios');

    expect(notif.alTocar, isNotNull);

    notif.alTocar!(ServicioNotificaciones.rutaAviso);
    await tester.pumpAndSettle();
    expect(EstadoArranque.destinoPendiente, '/recordatorios');

    notif.alTocar!(null);
    notif.alTocar!('https://sitio-externo.cl');
    await tester.pumpAndSettle();
    expect(EstadoArranque.destinoPendiente, '/recordatorios');
    expect(tester.takeException(), isNull);
  });
}
