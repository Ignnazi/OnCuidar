import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/historial/presentacion/widgets/cabecera_tarjeta_registro.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';

RegistroClinico _registroDel(DateTime fecha) => RegistroClinico(
  id: 'r1',
  pacienteId: 'p1',
  fecha: fecha,
  creadoEn: fecha,
  tipoRegistro: 'programado',
);

Future<void> _mostrar(WidgetTester tester, RegistroClinico registro) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CabeceraRegistro(
            registro: registro,
            etiqueta: 'Registro 1/3',
            onEditar: () {},
            onEliminar: () {},
          ),
        ),
      ),
    );

final _menu = find.byWidgetPredicate((w) => w is PopupMenuButton);

void main() {
  final ahora = DateTime(2026, 10, 26, 18);

  test('solo los registros de hoy se pueden editar', () {
    expect(
      esEditableHoy(_registroDel(DateTime(2026, 10, 26, 7)), ahora: ahora),
      isTrue,
    );
    expect(
      esEditableHoy(_registroDel(DateTime(2026, 10, 25, 23)), ahora: ahora),
      isFalse,
    );
  });

  testWidgets('un registro de hoy muestra el menú de editar y eliminar', (
    tester,
  ) async {
    await _mostrar(tester, _registroDel(DateTime.now()));
    expect(_menu, findsOneWidget);
  });

  testWidgets('un registro de un día anterior no muestra el menú', (
    tester,
  ) async {
    final ayer = DateTime.now().subtract(const Duration(days: 1));
    await _mostrar(tester, _registroDel(ayer));
    expect(_menu, findsNothing);
  });
}
