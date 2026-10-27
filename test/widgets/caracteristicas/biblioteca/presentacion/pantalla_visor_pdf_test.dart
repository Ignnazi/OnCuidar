import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/app/proveedores_navegacion.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/pantalla_visor_pdf.dart';

void main() {
  late ProviderContainer contenedor;
  String? rutaRecibida;

  Future<void> abrir(WidgetTester tester) async {
    contenedor = ProviderContainer();
    addTearDown(contenedor.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: contenedor,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PantallaVisorPdf(
                      ruta: '/datos/manual.pdf',
                      titulo: 'Manual de Control de Síntomas',
                      constructorDocumento: (ruta) {
                        rutaRecibida = ruta;
                        return const Center(child: Text('documento falso'));
                      },
                    ),
                  ),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('muestra título y documento, sin favorito ni compartir', (
    tester,
  ) async {
    await abrir(tester);

    expect(find.text('Manual de Control de Síntomas'), findsOneWidget);
    expect(find.text('documento falso'), findsOneWidget);
    expect(rutaRecibida, '/datos/manual.pdf');
    expect(find.byKey(const Key('cerrarVisorPdf')), findsOneWidget);
    expect(find.byKey(const Key('girarVisor')), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_border), findsNothing);
    expect(find.byIcon(Icons.share_rounded), findsNothing);
    final scaffold = tester.widget<Scaffold>(
      find.descendant(
        of: find.byType(PantallaVisorPdf),
        matching: find.byType(Scaffold),
      ),
    );
    expect(scaffold.backgroundColor!.computeLuminance(), lessThan(0.01));
  });

  testWidgets(
    'se abre sobre toda la app, barra inferior incluida, sin redimensionarse',
    (tester) async {
      contenedor = ProviderContainer(
        overrides: [
          constructorDocumentoPdfProvider.overrideWithValue(
            (ruta) => const SizedBox.expand(key: Key('documentoFalso')),
          ),
        ],
      );
      addTearDown(contenedor.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: contenedor,
          child: MaterialApp(
            home: Scaffold(
              bottomNavigationBar: const SizedBox(
                height: 60,
                child: Text('barra inferior'),
              ),
              body: Navigator(
                onGenerateRoute: (_) => MaterialPageRoute<void>(
                  builder: (interno) => Center(
                    child: TextButton(
                      onPressed: () => abrirVisorPdf(
                        interno,
                        ruta: '/datos/manual.pdf',
                        titulo: 'Manual',
                      ),
                      child: const Text('abrir'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('barra inferior'), findsOneWidget);

      await tester.tap(find.text('abrir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      final tamanoAlAbrir = tester.getSize(
        find.byKey(const Key('documentoFalso')),
      );
      await tester.pumpAndSettle();
      final tamanoFinal = tester.getSize(
        find.byKey(const Key('documentoFalso')),
      );

      expect(tamanoFinal, tamanoAlAbrir);
      expect(find.text('barra inferior'), findsNothing);
      expect(contenedor.read(pantallaCompletaProvider), isFalse);

      await tester.tap(find.byKey(const Key('cerrarVisorPdf')));
      await tester.pumpAndSettle();
      expect(find.byType(PantallaVisorPdf), findsNothing);
      expect(find.text('barra inferior'), findsOneWidget);
    },
  );

  testWidgets('el botón de compartir solo aparece si se da la acción', (
    tester,
  ) async {
    var compartido = 0;
    Widget visor({VoidCallback? alCompartir}) => ProviderScope(
      child: MaterialApp(
        home: PantallaVisorPdf(
          ruta: '/x.pdf',
          titulo: 'Historial',
          alCompartir: alCompartir,
          constructorDocumento: (_) => const SizedBox(),
        ),
      ),
    );

    await tester.pumpWidget(visor());
    expect(find.byKey(const Key('compartirVisorPdf')), findsNothing);

    await tester.pumpWidget(visor(alCompartir: () => compartido++));
    await tester.tap(find.byKey(const Key('compartirVisorPdf')));
    expect(compartido, 1);
  });

  testWidgets('el indicador muestra página actual y total', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: IndicadorPaginaPdf(pagina: 3, total: 10)),
    );
    expect(find.text('3 / 10'), findsOneWidget);
  });
}
