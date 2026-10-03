import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/autenticacion/presentacion/pantalla_recuperar_acceso.dart';

const _mensajeEnviado =
    'Si ese correo de respaldo está asociado a una cuenta, te enviamos un enlace para restablecer la contraseña. Revisa tu bandeja de entrada (y el spam).';
const _mensajeNoEncontrado =
    'Ese correo de respaldo no está asociado a ninguna cuenta. Verifica e intenta de nuevo.';
const _mensajeSinConexion =
    'Sin conexión. Verifica tu internet e intenta de nuevo.';
const _mensajeErrorServidor = 'No se pudo completar. Intenta de nuevo.';

class _ErrorConectividad extends FirebaseFunctionsException {
  _ErrorConectividad()
    : super(code: 'unavailable', message: 'Unavailable (simulado)');
}

class _ErrorServidor extends FirebaseFunctionsException {
  _ErrorServidor() : super(code: 'internal', message: 'Internal (simulado)');
}

Future<void> _pantallaAlta(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _pantalla(RecuperarAcceso pantalla) => MaterialApp(home: pantalla);

Future<void> _ingresarCorreoYEnviar(
  WidgetTester tester, {
  required String email,
}) async {
  await tester.enterText(
    find.widgetWithText(TextField, 'correo@ejemplo.com'),
    email,
  );
  await tester.tap(find.widgetWithText(ElevatedButton, 'Enviar enlace'));
  await tester.pumpAndSettle();
}

bool _botonDeshabilitado(WidgetTester tester) {
  final boton = tester.widget<ElevatedButton>(
    find.widgetWithText(ElevatedButton, 'Enlace enviado'),
  );
  return boton.onPressed == null;
}

bool _campoDeshabilitado(WidgetTester tester) {
  final campo = tester.widget<TextField>(find.byType(TextField));
  return campo.enabled == false;
}

void main() {
  group('interpretarRespuestaRecuperacion', () {
    test('la respuesta anti-enumeracion {ok: true} es exito', () {
      expect(interpretarRespuestaRecuperacion({'ok': true}), isTrue);
    });

    test('no depende del campo found', () {
      expect(
        interpretarRespuestaRecuperacion({'ok': true, 'found': false}),
        isTrue,
      );
    });

    test('una respuesta sin ok o vacia no es exito', () {
      expect(interpretarRespuestaRecuperacion(null), isFalse);
      expect(interpretarRespuestaRecuperacion('ok'), isFalse);
      expect(interpretarRespuestaRecuperacion({'ok': false}), isFalse);
    });
  });

  testWidgets('envio sin error muestra mensaje neutro y bloquea el reenvio', (
    tester,
  ) async {
    await _pantallaAlta(tester);
    final emailsEnviados = <String>[];
    await tester.pumpWidget(
      _pantalla(
        RecuperarAcceso(onSubmit: (email) async => emailsEnviados.add(email)),
      ),
    );
    await tester.pumpAndSettle();

    await _ingresarCorreoYEnviar(tester, email: 'ana@correo.cl');

    expect(emailsEnviados, ['ana@correo.cl']);
    expect(find.text(_mensajeEnviado), findsOneWidget);
    expect(find.text(_mensajeNoEncontrado), findsNothing);
    expect(
      find.byType(TextField),
      findsOneWidget,
    ); // El formulario NO desaparece
    expect(_botonDeshabilitado(tester), isTrue);
    expect(_campoDeshabilitado(tester), isTrue);
  });

  testWidgets(
    'falla de conectividad muestra error de red y permite reintentar',
    (tester) async {
      await _pantallaAlta(tester);
      await tester.pumpWidget(
        _pantalla(
          RecuperarAcceso(onSubmit: (_) async => throw _ErrorConectividad()),
        ),
      );
      await tester.pumpAndSettle();

      await _ingresarCorreoYEnviar(tester, email: 'ana@correo.cl');

      expect(find.text(_mensajeSinConexion), findsOneWidget);
      expect(find.text(_mensajeEnviado), findsNothing);
      expect(find.text(_mensajeNoEncontrado), findsNothing);
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Enviar enlace'),
            )
            .onPressed,
        isNotNull,
      );
      expect(_campoDeshabilitado(tester), isFalse);
    },
  );

  testWidgets('error de servidor muestra mensaje de error reintentable', (
    tester,
  ) async {
    await _pantallaAlta(tester);
    await tester.pumpWidget(
      _pantalla(RecuperarAcceso(onSubmit: (_) async => throw _ErrorServidor())),
    );
    await tester.pumpAndSettle();

    await _ingresarCorreoYEnviar(tester, email: 'ana@correo.cl');

    expect(find.text(_mensajeErrorServidor), findsOneWidget);
    expect(find.text(_mensajeEnviado), findsNothing);
    expect(find.text(_mensajeNoEncontrado), findsNothing);
  });

  testWidgets('correo invalido no envia y muestra el error del validador', (
    tester,
  ) async {
    await _pantallaAlta(tester);
    var enviado = false;
    await tester.pumpWidget(
      _pantalla(RecuperarAcceso(onSubmit: (_) async => enviado = true)),
    );
    await tester.pumpAndSettle();

    await _ingresarCorreoYEnviar(tester, email: 'correo-invalido');

    expect(enviado, isFalse);
    expect(find.text('Ingresa un correo válido'), findsOneWidget);
    expect(find.text(_mensajeEnviado), findsNothing);
  });
}
