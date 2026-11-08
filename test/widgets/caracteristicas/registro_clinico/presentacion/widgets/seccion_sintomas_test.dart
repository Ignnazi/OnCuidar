import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/presentacion/widgets/seccion_sintomas.dart';

void main() {
  testWidgets('agregar un síntoma desde el selector no abre el teclado', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final seleccionados = <String>{};
    final otro = TextEditingController();
    addTearDown(otro.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => ListView(
              children: [
                const TextField(key: Key('campoPrevio')),
                SeccionSintomas(
                  seleccionados: seleccionados,
                  catalogoPorNombre: const {},
                  intensidades: const {},
                  otroController: otro,
                  onAlternar: (n) => setState(
                    () => seleccionados.contains(n)
                        ? seleccionados.remove(n)
                        : seleccionados.add(n),
                  ),
                  onIntensidad: (_, _) {},
                  onCambioOtro: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('campoPrevio')));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tap(find.byKey(const Key('campoSelectorSintomas')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fatiga'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();

    expect(seleccionados, contains('Fatiga'));
    expect(tester.testTextInput.isVisible, isFalse);
    expect(
      FocusManager.instance.primaryFocus?.context?.widget,
      isNot(isA<EditableText>()),
    );
  });
}
