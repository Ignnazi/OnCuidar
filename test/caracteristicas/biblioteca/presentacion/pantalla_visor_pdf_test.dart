import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/app/proveedores_navegacion.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/material_educativo.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/pantalla_visor_pdf.dart';

MaterialEducativo _material({String? tipo, String? url}) => MaterialEducativo(
  id: 'm',
  titulo: 't',
  categoria: 'Guías',
  tema: '',
  cuerpo: '',
  tipoArchivo: tipo,
  urlArchivo: url,
  creadoEn: DateTime.utc(2026, 1, 1),
);

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

  testWidgets('oculta la barra inferior y la devuelve al volver', (
    tester,
  ) async {
    await abrir(tester);
    expect(contenedor.read(pantallaCompletaProvider), isTrue);

    await tester.tap(find.byKey(const Key('cerrarVisorPdf')));
    await tester.pumpAndSettle();

    expect(find.byType(PantallaVisorPdf), findsNothing);
    expect(contenedor.read(pantallaCompletaProvider), isFalse);
  });

  testWidgets('el indicador muestra página actual y total', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: IndicadorPaginaPdf(pagina: 3, total: 10)),
    );
    expect(find.text('3 / 10'), findsOneWidget);
  });

  test('esPdf reconoce el tipo declarado o la extensión del archivo', () {
    expect(_material(tipo: 'pdf').esPdf, isTrue);
    expect(
      _material(url: 'https://x.test/o/Guias%2Fmanual.pdf?alt=media').esPdf,
      isTrue,
    );
    expect(
      _material(tipo: 'video', url: 'https://x.test/v.mp4').esPdf,
      isFalse,
    );
    expect(_material().esPdf, isFalse);
  });
}
