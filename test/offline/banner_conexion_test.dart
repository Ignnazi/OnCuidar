import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/compartidos/widgets/banner_conexion.dart';
import 'package:oncuidar/core/proveedores/proveedores.dart';

const _breve = Duration(seconds: 3);
final _banner = find.byKey(const Key('banner_conexion'));

Widget _app({required bool enLinea}) {
  return ProviderScope(
    overrides: [
      estadoConexionProvider.overrideWith((_) => Stream.value(enLinea)),
    ],
    child: MaterialApp(
      home: Scaffold(body: BannerConexion(duracion: _breve)),
    ),
  );
}

Future<void> _montar(WidgetTester tester, {required bool enLinea}) async {
  await tester.pumpWidget(_app(enLinea: enLinea));
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('sin conexión dice solo «Sin conexión»', (tester) async {
    await _montar(tester, enLinea: false);

    expect(_banner, findsOneWidget);
    expect(find.text('Sin conexión'), findsOneWidget);
    expect(find.textContaining('cambio'), findsNothing);
    expect(find.textContaining('Enviando'), findsNothing);
    expect(find.text('Reintentar'), findsNothing);
    await tester.pump(_breve);
  });

  testWidgets('desaparece a los 3 segundos', (tester) async {
    await _montar(tester, enLinea: false);
    expect(_banner, findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(_banner, findsOneWidget, reason: 'a los 2 s sigue visible');

    await tester.pump(const Duration(seconds: 1));
    expect(_banner, findsNothing, reason: 'a los 3 s ya se ocultó');
  });

  testWidgets('con conexión no muestra nada', (tester) async {
    await _montar(tester, enLinea: true);

    expect(_banner, findsNothing);
  });

  testWidgets('al retomar la app sin conexión vuelve a aparecer', (
    tester,
  ) async {
    await _montar(tester, enLinea: false);
    await tester.pump(_breve);
    expect(_banner, findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(_banner, findsOneWidget);
    await tester.pump(_breve);
  });
}
