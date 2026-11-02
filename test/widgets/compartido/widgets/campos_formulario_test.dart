import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/compartido/widgets/campos_formulario.dart';

Widget _envolver(Widget hijo) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: hijo)),
);

void main() {
  group('CampoFormulario', () {
    testWidgets('muestra la ayuda y avisa de cada cambio', (tester) async {
      final controlador = TextEditingController();
      final cambios = <String>[];
      await tester.pumpWidget(
        _envolver(
          CampoFormulario(
            controlador: controlador,
            textoAyuda: 'Correo',
            icono: Icons.mail_outline,
            alCambiar: cambios.add,
          ),
        ),
      );

      expect(find.text('Correo'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'ana@mail.cl');
      expect(controlador.text, 'ana@mail.cl');
      expect(cambios, ['ana@mail.cl']);
    });

    testWidgets('oculta el texto cuando es una contraseña', (tester) async {
      await tester.pumpWidget(
        _envolver(
          CampoFormulario(
            controlador: TextEditingController(),
            textoAyuda: 'Contraseña',
            icono: Icons.lock_outline,
            oculto: true,
          ),
        ),
      );

      final campo = tester.widget<TextField>(find.byType(TextField));
      expect(campo.obscureText, isTrue);
    });

    testWidgets('deshabilitado no deja escribir', (tester) async {
      await tester.pumpWidget(
        _envolver(
          CampoFormulario(
            controlador: TextEditingController(),
            textoAyuda: 'Nombre',
            icono: Icons.person_outline,
            habilitado: false,
          ),
        ),
      );

      final campo = tester.widget<TextField>(find.byType(TextField));
      expect(campo.enabled, isFalse);
    });

    testWidgets('el validador muestra su mensaje de error', (tester) async {
      final clave = GlobalKey<FormState>();
      await tester.pumpWidget(
        _envolver(
          Form(
            key: clave,
            child: CampoFormulario(
              controlador: TextEditingController(),
              textoAyuda: 'Nombre',
              icono: Icons.person_outline,
              validador: (v) => (v ?? '').isEmpty ? 'Campo obligatorio' : null,
            ),
          ),
        ),
      );

      expect(clave.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Campo obligatorio'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Ana');
      expect(clave.currentState!.validate(), isTrue);
    });

    testWidgets('envía el texto al confirmar desde el teclado', (tester) async {
      String? enviado;
      await tester.pumpWidget(
        _envolver(
          CampoFormulario(
            controlador: TextEditingController(),
            textoAyuda: 'Buscar',
            icono: Icons.search,
            alEnviar: (v) => enviado = v,
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'hola');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(enviado, 'hola');
    });
  });

  testWidgets('TarjetaSeccion muestra el título y sus hijos', (tester) async {
    await tester.pumpWidget(
      _envolver(
        const TarjetaSeccion(
          icono: Icons.favorite_border,
          titulo: 'Datos personales',
          hijos: [Text('Primer hijo'), Text('Segundo hijo')],
        ),
      ),
    );

    expect(find.text('Datos personales'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    expect(find.text('Primer hijo'), findsOneWidget);
    expect(find.text('Segundo hijo'), findsOneWidget);
  });

  testWidgets('EtiquetaCampo muestra su texto', (tester) async {
    await tester.pumpWidget(_envolver(const EtiquetaCampo(texto: 'Edad')));
    expect(find.text('Edad'), findsOneWidget);
  });

  test('decoracionEntrada usa la ayuda y el icono recibidos', () {
    final decoracion = decoracionEntrada(
      textoAyuda: 'Peso',
      icono: Icons.monitor_weight_outlined,
    );

    expect(decoracion.hintText, 'Peso');
    expect(decoracion.filled, isTrue);
    expect(decoracion.suffixIcon, isNull);
    expect(
      (decoracion.prefixIcon! as Icon).icon,
      Icons.monitor_weight_outlined,
    );
  });
}
