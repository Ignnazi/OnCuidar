import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/app/enrutador/fundido_ramas.dart';

class _Contador extends StatefulWidget {
  const _Contador(this.nombre);

  final String nombre;

  @override
  State<_Contador> createState() => _ContadorState();
}

class _ContadorState extends State<_Contador> {
  int toques = 0;

  @override
  Widget build(BuildContext context) => TextButton(
    key: Key('boton_${widget.nombre}'),
    onPressed: () => setState(() => toques++),
    child: Text('${widget.nombre}: $toques'),
  );
}

Widget _app(int activo) => MaterialApp(
  home: FundidoRamas(
    indiceActivo: activo,
    ramas: const [_Contador('inicio'), _Contador('perfil')],
  ),
);

void main() {
  testWidgets('solo se ve la rama activa y la otra no recibe toques', (
    tester,
  ) async {
    await tester.pumpWidget(_app(0));
    expect(find.text('inicio: 0'), findsOneWidget);
    expect(find.text('perfil: 0'), findsNothing);

    await tester.tap(find.byKey(const Key('boton_inicio')));
    await tester.pump();
    expect(find.text('inicio: 1'), findsOneWidget);
  });

  testWidgets('cambiar de rama hace un fundido y conserva el estado', (
    tester,
  ) async {
    await tester.pumpWidget(_app(0));
    await tester.tap(find.byKey(const Key('boton_inicio')));
    await tester.pump();

    await tester.pumpWidget(_app(1));
    // A mitad del fundido ambas ramas se ven.
    await tester.pump(FundidoRamas.duracion ~/ 2);
    expect(find.text('inicio: 1', skipOffstage: false), findsOneWidget);
    expect(find.text('perfil: 0'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('perfil: 0'), findsOneWidget);
    expect(find.text('inicio: 1'), findsNothing);

    // Al volver, la rama de inicio sigue como se dejó.
    await tester.pumpWidget(_app(0));
    await tester.pumpAndSettle();
    expect(find.text('inicio: 1'), findsOneWidget);
  });
}
