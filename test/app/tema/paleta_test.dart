import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/app/tema/repintar.dart';
import 'package:oncuidar/app/tema/tema.dart';
import 'package:oncuidar/app/tema/transicion_fundido.dart';
import 'package:oncuidar/compartido/widgets/fondo_hoja.dart';

/// Pinta un cuadro con el color de tarjeta vigente.
class _Muestra extends StatelessWidget {
  const _Muestra();

  @override
  Widget build(BuildContext context) =>
      ColoredBox(key: const Key('muestra'), color: Paleta.tarjeta);
}

Color _colorMuestra(WidgetTester tester) =>
    tester.widget<ColoredBox>(find.byKey(const Key('muestra'))).color;

void main() {
  tearDown(() => Paleta.usar(coloresClaros));

  test('usar cambia la paleta y avisa solo si hubo cambio', () {
    expect(Paleta.esOscura, isFalse);
    expect(Paleta.usar(coloresOscuros), isTrue);
    expect(Paleta.esOscura, isTrue);
    expect(Paleta.tarjeta, coloresOscuros.tarjeta);
    expect(Paleta.usar(coloresOscuros), isFalse);
  });

  test('sobre dorado: blanco en claro (como antes) y café en oscuro', () {
    expect(Paleta.sobreDorado, const Color(0xFFFFFFFF));
    Paleta.usar(coloresOscuros);
    expect(Paleta.sobreDorado, const Color(0xFF3B2400));
    double contraste(Color a, Color b) {
      final claro = a.computeLuminance() > b.computeLuminance() ? a : b;
      final oscuro = identical(claro, a) ? b : a;
      return (claro.computeLuminance() + 0.05) /
          (oscuro.computeLuminance() + 0.05);
    }

    final dorado = Paleta.doradoPrincipal;
    expect(
      contraste(Paleta.sobreDorado, dorado),
      greaterThan(contraste(Colors.white, dorado)),
    );
  });

  test('los velos sobre dorado conservan su valor original en modo claro', () {
    expect(Paleta.alfa(claro: 0.22, oscuro: 0.35), 0.22);
    Paleta.usar(coloresOscuros);
    expect(Paleta.alfa(claro: 0.22, oscuro: 0.35), 0.35);
  });

  test('los degradados dorados son los mismos en modo claro y oscuro', () {
    final cabecera = Paleta.degradadoCabecera.colors;
    final banner = Paleta.degradadoBanner;
    final relleno = Paleta.doradoRelleno;
    Paleta.usar(coloresOscuros);
    expect(Paleta.degradadoCabecera.colors, cabecera);
    expect(Paleta.degradadoBanner, banner);
    expect(Paleta.doradoRelleno, relleno);
    expect(Paleta.doradoPrincipal, coloresClaros.doradoPrincipal);
    expect(Paleta.doradoMedio, coloresClaros.doradoMedio);
  });

  testWidgets('el tema sigue el brillo de la paleta', (tester) async {
    expect(Tema.obtener().brightness, Brightness.light);
    Paleta.usar(coloresOscuros);
    final tema = Tema.obtener();
    expect(tema.brightness, Brightness.dark);
    expect(tema.scaffoldBackgroundColor, coloresOscuros.crema);
  });

  testWidgets('todas las pantallas entran con el mismo fundido', (
    tester,
  ) async {
    final builders = Tema.obtener().pageTransitionsTheme.builders;
    for (final plataforma in [
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.macOS,
    ]) {
      expect(builders[plataforma], isA<TransicionFundido>());
    }
    expect(
      const TransicionFundido().transitionDuration,
      TransicionFundido.duracion,
    );
  });

  testWidgets('repintarArbol actualiza incluso los widgets const', (
    tester,
  ) async {
    late BuildContext raiz;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          raiz = context;
          return const Directionality(
            textDirection: TextDirection.ltr,
            child: _Muestra(),
          );
        },
      ),
    );
    expect(_colorMuestra(tester), coloresClaros.tarjeta);

    Paleta.usar(coloresOscuros);
    await tester.pump();
    expect(_colorMuestra(tester), coloresClaros.tarjeta);

    repintarArbol(raiz);
    await tester.pump();
    expect(_colorMuestra(tester), coloresOscuros.tarjeta);
  });

  testWidgets('una hoja inferior abierta cambia de color al cambiar de modo', (
    tester,
  ) async {
    late BuildContext raiz;
    await tester.pumpWidget(
      Builder(
        builder: (arriba) {
          raiz = arriba;
          return MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const FondoHoja(
                        child: SizedBox(key: Key('contenidoHoja'), height: 100),
                      ),
                    ),
                    child: const Text('abrir'),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    Color fondo() => tester
        .widget<Material>(
          find
              .ancestor(
                of: find.byKey(const Key('contenidoHoja')),
                matching: find.byType(Material),
              )
              .first,
        )
        .color!;

    expect(fondo(), coloresClaros.crema);

    Paleta.usar(coloresOscuros);
    repintarArbol(raiz);
    await tester.pump();

    expect(fondo(), coloresOscuros.crema);
  });
}
