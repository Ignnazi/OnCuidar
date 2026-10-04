import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/chat/dominio/conversacion.dart';
import 'package:oncuidar/caracteristicas/chat/presentacion/widgets/burbujas_chat.dart';

Widget _envolver(Widget hijo) => MaterialApp(home: Scaffold(body: hijo));

void main() {
  testWidgets('la burbuja muestra la hora de envío', (tester) async {
    await tester.pumpWidget(
      _envolver(
        BurbujaMensaje(
          mensaje: MensajeConversacion(
            texto: 'Hola',
            delUsuario: true,
            enviadoEn: DateTime(2026, 10, 4, 21, 5),
          ),
        ),
      ),
    );

    expect(find.text('9:05 PM'), findsOneWidget);
  });

  testWidgets('sin hora de envío no muestra marca de hora', (tester) async {
    await tester.pumpWidget(
      _envolver(
        const BurbujaMensaje(
          mensaje: MensajeConversacion(texto: 'Antiguo', delUsuario: false),
        ),
      ),
    );

    expect(find.byKey(const Key('horaMensajeChat')), findsNothing);
  });

  testWidgets('la respuesta con material ofrece abrirlo', (tester) async {
    var abierto = false;
    await tester.pumpWidget(
      _envolver(
        BurbujaMensaje(
          mensaje: const MensajeConversacion(
            texto: 'Respuesta',
            delUsuario: false,
            materialId: 'm1',
          ),
          alAbrirMaterial: () => abierto = true,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('verMaterialChat')));

    expect(abierto, isTrue);
  });

  testWidgets('el mensaje del usuario nunca ofrece material', (tester) async {
    await tester.pumpWidget(
      _envolver(
        BurbujaMensaje(
          mensaje: const MensajeConversacion(texto: 'Hola', delUsuario: true),
          alAbrirMaterial: () {},
        ),
      ),
    );

    expect(find.byKey(const Key('verMaterialChat')), findsNothing);
  });

  testWidgets('la sugerencia de consulta aparece solo si corresponde', (
    tester,
  ) async {
    await tester.pumpWidget(
      _envolver(
        const BurbujaMensaje(
          mensaje: MensajeConversacion(
            texto: 'Respuesta',
            delUsuario: false,
            sugerenciaConsulta: true,
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('sugerenciaConsultaChat')), findsOneWidget);

    await tester.pumpWidget(
      _envolver(
        const BurbujaMensaje(
          mensaje: MensajeConversacion(texto: 'Respuesta', delUsuario: false),
        ),
      ),
    );
    expect(find.byKey(const Key('sugerenciaConsultaChat')), findsNothing);
  });

  testWidgets('mantener pulsado copia el texto del mensaje', (tester) async {
    String? copiado;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (llamada) async {
        if (llamada.method == 'Clipboard.setData') {
          copiado = (llamada.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      _envolver(
        const BurbujaMensaje(
          mensaje: MensajeConversacion(
            texto: 'Texto a copiar',
            delUsuario: false,
          ),
        ),
      ),
    );

    await tester.longPress(find.byKey(const Key('burbujaMensajeChat')));
    await tester.pump();

    expect(copiado, 'Texto a copiar');
    expect(find.text('Mensaje copiado'), findsOneWidget);
  });

  testWidgets('el separador nombra el día', (tester) async {
    await tester.pumpWidget(
      _envolver(
        SeparadorDia(
          fecha: DateTime(2026, 10, 3, 9),
          ahora: DateTime(2026, 10, 4, 9),
        ),
      ),
    );

    expect(find.text('Ayer'), findsOneWidget);
  });
}
