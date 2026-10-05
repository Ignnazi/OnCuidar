import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/recordatorios/dominio/recordatorio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../ayudas/recordatorios.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Modelo Recordatorio', () {
    test('sin asignación guardada va dirigido al paciente', () {
      final r = Recordatorio.fromMap('x', {'titulo': 'Antiguo'});
      expect(r.asignadoA, Recordatorio.asignadoAPaciente);
      expect(r.esParaCuidador, isFalse);
    });

    test('el título del aviso nombra al cuidador o al paciente', () {
      final paraPaciente = recordatorioDe('p');
      final paraCuidador = recordatorioDe(
        'p',
        asignadoA: Recordatorio.asignadoACuidador,
      );
      expect(paraPaciente.tituloAviso('Rosa', 'Cita'), 'Rosa · Cita');
      expect(paraCuidador.tituloAviso('Rosa', 'Cita'), 'Cuidador · Cita');
    });

    test('el cuerpo del aviso incluye la descripción', () {
      expect(
        recordatorioDe('p', titulo: 'Jarabe', descripcion: '5 ml').cuerpoAviso,
        'Jarabe · 5 ml',
      );
      expect(recordatorioDe('p', titulo: 'Jarabe').cuerpoAviso, 'Jarabe');
    });
  });
}
