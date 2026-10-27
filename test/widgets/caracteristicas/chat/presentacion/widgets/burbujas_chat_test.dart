import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

    final hora = tester.widget<Text>(find.byKey(const Key('horaMensajeChat')));
    expect(hora.data, '9:05 PM');
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

  group('hora al estilo WhatsApp', () {
    Future<void> montar(
      WidgetTester tester,
      MensajeConversacion mensaje, {
      Size tamano = const Size(360, 4000),
      double escala = 1.0,
    }) async {
      tester.view.physicalSize = tamano;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, hijo) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(escala)),
            child: hijo!,
          ),
          home: Scaffold(body: BurbujaMensaje(mensaje: mensaje)),
        ),
      );
    }

    MensajeConversacion mensaje(String texto, {bool usuario = true}) =>
        MensajeConversacion(
          texto: texto,
          delUsuario: usuario,
          enviadoEn: DateTime(2026, 10, 4, 21, 5),
        );

    List<Rect> cajasDelTexto(WidgetTester tester, String texto) {
      final parrafo = tester.renderObject<RenderParagraph>(
        find
            .descendant(
              of: find.byKey(const Key('burbujaMensajeChat')),
              matching: find.byType(RichText),
            )
            .first,
      );
      return [
        for (final caja in parrafo.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: texto.length),
        ))
          caja.toRect().shift(parrafo.localToGlobal(Offset.zero)),
      ];
    }

    testWidgets('en un mensaje corto la hora comparte la línea del texto', (
      tester,
    ) async {
      await montar(tester, mensaje('Hola'));

      final hora = tester.getRect(find.byKey(const Key('horaMensajeChat')));
      final texto = cajasDelTexto(tester, 'Hola').single;
      expect(hora.left, greaterThanOrEqualTo(texto.right));
      expect(hora.center.dy, closeTo(texto.center.dy, texto.height));
      final burbuja = tester.getSize(
        find.byKey(const Key('burbujaMensajeChat')),
      );
      expect(burbuja.height, lessThan(45));
    });

    testWidgets(
      'si la última línea no deja sitio, la hora va debajo a la derecha',
      (tester) async {
        final largo = 'a' * 34;
        await montar(tester, mensaje(largo));

        final hora = tester.getRect(find.byKey(const Key('horaMensajeChat')));
        final cajas = cajasDelTexto(tester, largo);
        for (final caja in cajas) {
          expect(hora.overlaps(caja), isFalse, reason: 'la hora pisa el texto');
        }
        expect(hora.top, greaterThanOrEqualTo(cajas.last.bottom - 1));
        final burbuja = tester.getRect(
          find.byKey(const Key('burbujaMensajeChat')),
        );
        expect(burbuja.right - hora.right, lessThan(20));
      },
    );

    final preguntas = [
      '¿Qué temperatura se considera fiebre y cuándo debo llamar al médico?',
      '¿Cómo debo cuidar el catéter y qué hago si se moja o se sale?',
      'Mi hijo no quiere comer desde ayer y hoy tiene mucho sueño',
      ('palabra ' * 25).trim(),
      'Hola, ¿puedes decirme si es normal que tenga fiebre después de la quimio?',
    ];
    for (final (ancho, escala) in [
      (360.0, 1.0),
      (320.0, 1.0),
      (320.0, 1.3),
      (280.0, 1.6),
      (411.0, 1.15),
    ]) {
      for (final usuario in [true, false]) {
        testWidgets(
          'la hora nunca pisa el texto (${ancho.toInt()} px, x$escala, '
          '${usuario ? 'usuario' : 'asistente'})',
          (tester) async {
            for (final pregunta in preguntas) {
              await montar(
                tester,
                mensaje(pregunta, usuario: usuario),
                tamano: Size(ancho, 4000),
                escala: escala,
              );
              final hora = tester.getRect(
                find.byKey(const Key('horaMensajeChat')),
              );
              for (final caja in cajasDelTexto(tester, pregunta)) {
                expect(
                  hora.overlaps(caja),
                  isFalse,
                  reason: 'la hora pisa «$pregunta»',
                );
              }
              expect(tester.takeException(), isNull);
            }
          },
        );
      }
    }
  });

  group('letra del usuario', () {
    testWidgets('es más gruesa que la del asistente', (tester) async {
      FontWeight? peso(WidgetTester t, String texto) =>
          t.widget<Text>(find.text(texto)).style?.fontWeight;

      await tester.pumpWidget(
        _envolver(
          const Column(
            children: [
              BurbujaMensaje(
                mensaje: MensajeConversacion(texto: 'mío', delUsuario: true),
              ),
              BurbujaMensaje(
                mensaje: MensajeConversacion(texto: 'bot', delUsuario: false),
              ),
            ],
          ),
        ),
      );

      expect(peso(tester, 'mío'), FontWeight.w700);
      expect(peso(tester, 'bot'), FontWeight.w400);
    });
  });
}
