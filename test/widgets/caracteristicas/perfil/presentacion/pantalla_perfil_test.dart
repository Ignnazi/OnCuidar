import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/paciente.dart';
import 'package:oncuidar/caracteristicas/pacientes/presentacion/proveedores_pacientes.dart';
import 'package:oncuidar/caracteristicas/perfil/presentacion/pantalla_perfil.dart';
import 'package:oncuidar/nucleo/red/cliente_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _montar(WidgetTester tester, Stream<List<Paciente>> pacientes) {
  return tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        pacientesProvider.overrideWith((ref) => pacientes),
        pacientesArchivadosProvider.overrideWith(
          (ref) => Stream.value(const <Paciente>[]),
        ),
      ],
      child: const MaterialApp(home: Perfil()),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('si el servidor falla muestra error y no la lista vacía', (
    tester,
  ) async {
    await _montar(tester, Stream.error(const ExcepcionApi(500, 'Fallo')));
    await tester.pumpAndSettle();

    expect(find.text('No se pudieron cargar tus datos.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.text('Agregar paciente'), findsNothing);
  });

  testWidgets('sin pacientes sigue mostrando la tarjeta para agregar', (
    tester,
  ) async {
    await _montar(tester, Stream.value(const <Paciente>[]));
    await tester.pumpAndSettle();

    expect(find.text('No se pudieron cargar tus datos.'), findsNothing);
    expect(find.text('Agregar paciente'), findsOneWidget);
  });
}
