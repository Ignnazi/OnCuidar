import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';

void main() {
  group('EntradaSintoma.etiquetaPara', () {
    final esperado = {
      0: 'Sin síntoma',
      1: 'Leve',
      2: 'Leve',
      3: 'Leve',
      4: 'Moderado',
      5: 'Moderado',
      6: 'Moderado',
      7: 'Severo',
      8: 'Severo',
      9: 'Severo',
      10: 'Insoportable',
    };

    for (final MapEntry(key: intensidad, value: etiqueta) in esperado.entries) {
      test('$intensidad es «$etiqueta»', () {
        expect(EntradaSintoma.etiquetaPara(intensidad), etiqueta);
      });
    }

    test('las once intensidades caen en exactamente cinco categorías', () {
      final categorias = {
        for (var i = 0; i <= 10; i++) EntradaSintoma.etiquetaPara(i),
      };
      expect(categorias, hasLength(5));
    });
  });

  group('mensajes guardados del registro', () {
    RegistroClinico registro(String? mensaje) => RegistroClinico(
      id: 'r1',
      pacienteId: 'p1',
      fecha: DateTime(2026, 11, 7),
      creadoEn: DateTime(2026, 11, 7),
      tipoRegistro: 'programado',
      nivelAlerta: NivelAlerta.alerta,
      mensajeAlerta: mensaje,
    );

    test('se muestran los avisos de ese momento, uno por línea', () {
      expect(
        registro('Subfebril (37.6°C)\nSaturación de O₂ baja (95%)').mensajes,
        ['Subfebril (37.6°C)', 'Saturación de O₂ baja (95%)'],
      );
    });

    test('un registro antiguo muestra su mensaje tal como se guardó', () {
      expect(registro('Fiebre moderada (39.0°C) 1 síntoma severo').mensajes, [
        'Fiebre moderada (39.0°C) 1 síntoma severo',
      ]);
    });

    test('sin mensaje o sin nada preocupante no hay avisos', () {
      expect(registro(null).mensajes, isEmpty);
      expect(registro('Sin síntomas preocupantes').mensajes, isEmpty);
    });

    test('al guardar une los mensajes con saltos de línea', () {
      expect(mensajeAlertaParaGuardar(['A', 'B']), 'A\nB');
      expect(mensajeAlertaParaGuardar(const []), isNull);
    });
  });
}
