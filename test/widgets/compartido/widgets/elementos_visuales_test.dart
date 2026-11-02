import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/compartido/widgets/chip_franja.dart';
import 'package:oncuidar/compartido/widgets/tarjeta_dato.dart';
import 'package:oncuidar/compartido/widgets/titulo_seccion.dart';

Widget _envolver(Widget hijo) => MaterialApp(
  home: Scaffold(body: Center(child: hijo)),
);

void main() {
  testWidgets('TituloSeccion muestra el icono y el texto', (tester) async {
    await tester.pumpWidget(
      _envolver(const TituloSeccion(Icons.person_outline, 'Paciente')),
    );

    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.text('Paciente'), findsOneWidget);
  });

  group('ChipFranja', () {
    testWidgets('muestra el icono y el texto', (tester) async {
      await tester.pumpWidget(
        _envolver(const ChipFranja(Icons.schedule, 'Mañana')),
      );

      expect(find.byIcon(Icons.schedule), findsOneWidget);
      expect(find.text('Mañana'), findsOneWidget);
    });

    testWidgets('un texto largo se recorta sin desbordar', (tester) async {
      await tester.pumpWidget(
        _envolver(
          const SizedBox(
            width: 90,
            child: ChipFranja(Icons.schedule, 'Un texto demasiado largo'),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final texto = tester.widget<Text>(find.text('Un texto demasiado largo'));
      expect(texto.overflow, TextOverflow.ellipsis);
      expect(texto.maxLines, 1);
    });
  });

  group('FilaDato', () {
    testWidgets('muestra etiqueta, valor e icono', (tester) async {
      await tester.pumpWidget(
        _envolver(
          const FilaDato(
            icono: Icons.cake_outlined,
            etiqueta: 'Edad',
            valor: '78 años',
          ),
        ),
      );

      expect(find.text('Edad'), findsOneWidget);
      expect(find.text('78 años'), findsOneWidget);
      expect(find.byIcon(Icons.cake_outlined), findsOneWidget);
    });

    testWidgets('el valor ausente se ve más pequeño que el normal', (
      tester,
    ) async {
      await tester.pumpWidget(
        _envolver(
          const Column(
            children: [
              FilaDato(
                icono: Icons.cake_outlined,
                etiqueta: 'A',
                valor: 'dato',
              ),
              FilaDato(
                icono: Icons.cake_outlined,
                etiqueta: 'B',
                valor: 'sin dato',
                valorAusente: true,
              ),
            ],
          ),
        ),
      );

      final normal = tester.widget<Text>(find.text('dato')).style!.fontSize!;
      final ausente = tester
          .widget<Text>(find.text('sin dato'))
          .style!
          .fontSize!;
      expect(ausente, lessThan(normal));
    });

    testWidgets('recortar agrega puntos suspensivos al valor', (tester) async {
      const largo = 'un.correo.muy.largo@dominio-largo.example.com';
      await tester.pumpWidget(
        _envolver(
          const SizedBox(
            width: 150,
            child: FilaDato(
              icono: Icons.mail_outline,
              etiqueta: 'Correo',
              valor: largo,
              recortar: true,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.widget<Text>(find.text(largo)).overflow,
        TextOverflow.ellipsis,
      );
    });
  });

  testWidgets('TarjetaDorada ocupa todo el ancho y muestra su contenido', (
    tester,
  ) async {
    await tester.pumpWidget(
      _envolver(const TarjetaDorada(child: Text('Contenido'))),
    );

    expect(find.text('Contenido'), findsOneWidget);
    final anchoPantalla =
        tester.view.physicalSize.width / tester.view.devicePixelRatio;
    expect(tester.getSize(find.byType(TarjetaDorada)).width, anchoPantalla);
  });
}
