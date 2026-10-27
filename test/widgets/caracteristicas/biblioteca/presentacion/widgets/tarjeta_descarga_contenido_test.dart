import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/estado_descarga_contenido.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/widgets/tarjeta_descarga_contenido.dart';

Widget _app(FaseDescarga fase, int porcentaje) => MaterialApp(
  home: Scaffold(
    body: TarjetaDescargaContenido(fase: fase, porcentaje: porcentaje),
  ),
);

final _tarjeta = find.byKey(const Key('tarjeta_descarga_contenido'));

void main() {
  testWidgets('descargando muestra el porcentaje y no desconectarse', (
    tester,
  ) async {
    await tester.pumpWidget(_app(FaseDescarga.descargando, 45));
    await tester.pumpAndSettle();

    expect(find.text('Descargando contenido educativo… 45 %'), findsOneWidget);
    expect(find.text('No cierres la app ni te desconectes.'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('pausada muestra el texto de pausa', (tester) async {
    await tester.pumpWidget(_app(FaseDescarga.pausada, 45));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Descarga en pausa: sin conexión. Seguirá cuando vuelvas a conectarte.',
      ),
      findsOneWidget,
    );
    expect(find.text('No cierres la app ni te desconectes.'), findsNothing);
  });

  testWidgets('con errores avisa que se descargarán más tarde', (tester) async {
    await tester.pumpWidget(_app(FaseDescarga.conErrores, 80));
    await tester.pumpAndSettle();

    expect(
      find.text('Algunos archivos se descargarán más tarde.'),
      findsOneWidget,
    );
  });

  testWidgets('lista confirma y luego se oculta', (tester) async {
    await tester.pumpWidget(_app(FaseDescarga.lista, 100));
    await tester.pumpAndSettle();
    expect(
      find.text('¡Listo! Contenido guardado en tu teléfono.'),
      findsOneWidget,
    );

    await tester.pumpWidget(_app(FaseDescarga.ninguna, 100));
    await tester.pumpAndSettle();
    expect(_tarjeta, findsNothing);
  });

  testWidgets('con texto grande no desborda', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: TarjetaDescargaContenido(
              fase: FaseDescarga.pausada,
              porcentaje: 45,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
