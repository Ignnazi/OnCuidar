import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/motor_reglas_clinicas.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/presentacion/widgets/boton_tipo.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/presentacion/widgets/indicador_alerta.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/presentacion/widgets/tarjeta_signo.dart';

Widget _envolver(Widget hijo) => MaterialApp(
  home: Scaffold(body: Center(child: hijo)),
);

TarjetaSigno _tarjeta(
  TextEditingController controlador, {
  bool decimal = false,
  String? rango,
}) => TarjetaSigno(
  etiqueta: 'Temperatura',
  icono: Icons.thermostat,
  color: Colors.orange,
  hint: '36.5',
  unidad: '°C',
  controlador: controlador,
  decimal: decimal,
  rango: rango,
);

void main() {
  group('BotonTipo', () {
    testWidgets('habilitado ejecuta la acción al pulsar', (tester) async {
      var pulsaciones = 0;
      await tester.pumpWidget(
        _envolver(
          BotonTipo(
            etiqueta: 'Signos',
            activo: true,
            habilitado: true,
            alPulsar: () => pulsaciones++,
          ),
        ),
      );

      await tester.tap(find.text('Signos'));
      expect(pulsaciones, 1);
    });

    testWidgets('deshabilitado ignora la pulsación', (tester) async {
      var pulsaciones = 0;
      await tester.pumpWidget(
        _envolver(
          BotonTipo(
            etiqueta: 'Síntomas',
            activo: true,
            habilitado: false,
            alPulsar: () => pulsaciones++,
          ),
        ),
      );

      await tester.tap(find.text('Síntomas'));
      expect(pulsaciones, 0);
    });
  });

  group('TarjetaSigno', () {
    testWidgets('muestra etiqueta, unidad y ayuda', (tester) async {
      await tester.pumpWidget(_envolver(_tarjeta(TextEditingController())));

      expect(find.text('Temperatura'), findsOneWidget);
      expect(find.text('°C'), findsOneWidget);
      expect(find.text('36.5'), findsOneWidget);
      expect(find.textContaining('Rango'), findsNothing);
    });

    testWidgets('muestra el rango cuando se informa', (tester) async {
      await tester.pumpWidget(
        _envolver(_tarjeta(TextEditingController(), rango: '35-42')),
      );

      expect(find.text('Normal: 35-42 °C'), findsOneWidget);
    });

    testWidgets('sin decimales solo acepta dígitos', (tester) async {
      final controlador = TextEditingController();
      await tester.pumpWidget(_envolver(_tarjeta(controlador)));

      await tester.enterText(find.byType(TextField), '12a.5,3');
      expect(controlador.text, '1253');
    });

    testWidgets('con decimales cambia la coma por punto', (tester) async {
      final controlador = TextEditingController();
      await tester.pumpWidget(_envolver(_tarjeta(controlador, decimal: true)));

      await tester.enterText(find.byType(TextField), '36,6');
      expect(controlador.text, '36.6');
    });

    testWidgets('con decimales descarta las letras', (tester) async {
      final controlador = TextEditingController();
      await tester.pumpWidget(_envolver(_tarjeta(controlador, decimal: true)));

      await tester.enterText(find.byType(TextField), '3x7.2');
      expect(controlador.text, '37.2');
    });
  });

  group('IndicadorAlerta', () {
    testWidgets('nivel normal muestra su título y subtítulo', (tester) async {
      await tester.pumpWidget(
        _envolver(
          const IndicadorAlerta(
            alerta: EvaluacionAlerta(
              nivel: NivelAlerta.normal,
              mensajes: ['Sin síntomas preocupantes'],
            ),
          ),
        ),
      );

      expect(find.text('Todo parece normal'), findsOneWidget);
      expect(find.text('Continúa con la vigilancia habitual'), findsOneWidget);
    });

    testWidgets('oculta el mensaje de «Sin síntomas preocupantes»', (
      tester,
    ) async {
      await tester.pumpWidget(
        _envolver(
          const IndicadorAlerta(
            alerta: EvaluacionAlerta(
              nivel: NivelAlerta.normal,
              mensajes: ['Sin síntomas preocupantes'],
            ),
          ),
        ),
      );

      expect(find.textContaining('Sin síntomas preocupantes'), findsNothing);
    });

    testWidgets('nivel alerta lista cada mensaje con viñeta', (tester) async {
      await tester.pumpWidget(
        _envolver(
          const IndicadorAlerta(
            alerta: EvaluacionAlerta(
              nivel: NivelAlerta.alerta,
              mensajes: ['Fiebre elevada', 'Dolor intenso'],
            ),
          ),
        ),
      );

      expect(find.text('Se recomienda consultar'), findsOneWidget);
      expect(find.text('• Fiebre elevada'), findsOneWidget);
      expect(find.text('• Dolor intenso'), findsOneWidget);
    });

    testWidgets('nivel crítico pide atención urgente', (tester) async {
      await tester.pumpWidget(
        _envolver(
          const IndicadorAlerta(
            alerta: EvaluacionAlerta(
              nivel: NivelAlerta.critico,
              mensajes: ['Saturación muy baja'],
            ),
          ),
        ),
      );

      expect(find.text('Se recomienda atención urgente'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('• Saturación muy baja'), findsOneWidget);
    });
  });
}
