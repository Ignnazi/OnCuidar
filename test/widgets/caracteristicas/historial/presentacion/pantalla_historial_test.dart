import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/historial/presentacion/pantalla_historial.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/paciente.dart';
import 'package:oncuidar/caracteristicas/pacientes/presentacion/proveedores_pacientes.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/presentacion/proveedores_registro_clinico.dart';
import 'package:oncuidar/nucleo/red/cliente_api.dart';

void main() {
  testWidgets('error del servidor muestra un mensaje corto y no el detalle', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          registrosClinicosProvider.overrideWith(
            (ref) => Stream<List<RegistroClinico>>.error(
              const ExcepcionApi(500, 'Fallo interno'),
            ),
          ),
          pacienteActivoProvider.overrideWith(
            (ref) => Stream<Paciente?>.value(null),
          ),
        ],
        child: const MaterialApp(home: HistorialScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Error al cargar registros'), findsOneWidget);
    expect(
      find.text('No se pudieron cargar los datos. Intenta de nuevo.'),
      findsOneWidget,
    );
    expect(find.textContaining('Fallo interno'), findsNothing);
    expect(find.text('No hay registros aún'), findsNothing);
  });
}
