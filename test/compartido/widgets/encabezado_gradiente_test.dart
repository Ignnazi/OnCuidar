import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/compartido/widgets/buscador.dart';
import 'package:oncuidar/compartido/widgets/encabezado_gradiente.dart';

Widget _app({required double escala}) => MaterialApp(
  builder: (context, hijo) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(escala)),
    child: hijo!,
  ),
  home: Scaffold(
    body: Column(
      children: [
        EncabezadoGradiente(
          titulo: 'Chat de orientación',
          subtitulo: 'Resuelve tus dudas',
          logo: const AssetImage('assets/images/OnCuidar.png'),
          alTocarLogo: () {},
          accionDerecha: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              BotonCircular(
                clave: const Key('botonA'),
                tooltip: 'A',
                alTocar: () {},
                hijo: const Icon(Icons.search),
              ),
              const SizedBox(width: 8),
              BotonCircular(
                clave: const Key('botonB'),
                tooltip: 'B',
                alTocar: () {},
                hijo: const Icon(Icons.folder_rounded),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
);

void main() {
  for (final (ancho, escala) in [(360.0, 1.0), (320.0, 1.3), (320.0, 1.6)]) {
    testWidgets(
      'logo y botones miden 48 y comparten altura (${ancho.toInt()}, x$escala)',
      (tester) async {
        tester.view.physicalSize = Size(ancho, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(_app(escala: escala));
        await tester.pumpAndSettle();

        final logo = find.byKey(const Key('logoEncabezado'));
        expect(tester.getSize(logo), const Size(48, 48));
        for (final clave in ['botonA', 'botonB']) {
          final boton = find.byKey(Key(clave));
          expect(tester.getSize(boton), const Size(48, 48));
          expect(tester.getCenter(boton).dy, tester.getCenter(logo).dy);
        }
        expect(
          tester.getTopRight(find.byKey(const Key('botonB'))).dx,
          lessThan(ancho - 12),
        );
      },
    );
  }
}
