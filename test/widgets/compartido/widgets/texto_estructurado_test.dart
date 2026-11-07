import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/compartido/widgets/texto_estructurado.dart';

Future<void> _montar(WidgetTester tester, String texto) => tester.pumpWidget(
  MaterialApp(home: Scaffold(body: TextoEstructurado(texto))),
);

void main() {
  test('separa párrafos, títulos, viñetas y pasos', () {
    final bloques = BloqueTexto.desde(
      'Introducción del tema.\n'
      'Al comprar:\n'
      '• Prefiere marcas conocidas.\n'
      '• Quimioterapia: puede durar 48 horas.\n'
      '1. Siéntalo.\n'
      '2. Presiona la nariz.',
    );
    expect(bloques.map((b) => b.tipo), [
      TipoBloque.parrafo,
      TipoBloque.titulo,
      TipoBloque.vineta,
      TipoBloque.vineta,
      TipoBloque.paso,
      TipoBloque.paso,
    ]);
    expect(bloques[1].texto, 'Al comprar');
    expect(bloques[2].texto, 'Prefiere marcas conocidas.');
    expect(bloques[3].etiqueta, 'Quimioterapia');
    expect(bloques[3].texto, 'puede durar 48 horas.');
    expect(bloques[5].numero, '2');
    expect(bloques[5].texto, 'Presiona la nariz.');
  });

  test('una frase larga con dos puntos sigue siendo párrafo', () {
    final bloques = BloqueTexto.desde(
      'Si pasa más de 3 días sin evacuar, consulta: se considera una urgencia.',
    );
    expect(bloques.single.tipo, TipoBloque.parrafo);
  });

  testWidgets('muestra cada parte con su texto', (tester) async {
    await _montar(tester, 'Al guardar:\n• Rotula los envases.\n1. Siéntalo.');
    expect(find.text('Al guardar'), findsOneWidget);
    expect(find.text('Rotula los envases.'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Siéntalo.'), findsOneWidget);
  });

  testWidgets('la etiqueta de una viñeta va en negrita', (tester) async {
    await _montar(tester, '• Cara: 0 sin expresión.');
    final rico = tester.widget<RichText>(
      find.byWidgetPredicate(
        (w) =>
            w is RichText && w.text.toPlainText() == 'Cara: 0 sin expresión.',
      ),
    );
    TextSpan? etiqueta;
    rico.text.visitChildren((span) {
      if (span is TextSpan && span.text == 'Cara: ') etiqueta = span;
      return etiqueta == null;
    });
    expect(etiqueta?.style?.fontWeight, FontWeight.w800);
  });
}
