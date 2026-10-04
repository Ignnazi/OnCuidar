import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/chat/dominio/conversacion.dart';
import 'package:oncuidar/caracteristicas/chat/dominio/respuestas_chat.dart';
import 'package:oncuidar/nucleo/utilidades/formato_fecha.dart';

void main() {
  group('MensajeConversacion', () {
    test('conserva la hora de envío al guardar y leer', () {
      final enviado = DateTime(2026, 10, 4, 21, 30);
      final mensaje = MensajeConversacion(
        texto: 'Hola',
        delUsuario: true,
        enviadoEn: enviado,
      );

      final leido = MensajeConversacion.desdeMapa(mensaje.aMapa());

      expect(leido.enviadoEn, enviado);
    });

    test('un mensaje guardado antes de existir la hora se lee sin ella', () {
      final leido = MensajeConversacion.desdeMapa({
        'texto': 'Antiguo',
        'delUsuario': false,
      });

      expect(leido.enviadoEn, isNull);
      expect(leido.aMapa().containsKey('enviadoEn'), isFalse);
    });
  });

  test('guarda y lee el material relacionado y la sugerencia', () {
    const mensaje = MensajeConversacion(
      texto: 'Respuesta',
      delUsuario: false,
      materialId: 'videos-como-medir-la-fiebre',
      sugerenciaConsulta: true,
    );

    final leido = MensajeConversacion.desdeMapa(mensaje.aMapa());

    expect(leido.materialId, 'videos-como-medir-la-fiebre');
    expect(leido.sugerenciaConsulta, isTrue);
  });

  group('sugiereConsultarEquipo', () {
    test('detecta señales aunque falten tildes o haya mayúsculas', () {
      expect(sugiereConsultarEquipo('Mi hijo tiene FIEBRE'), isTrue);
      expect(sugiereConsultarEquipo('le cuesta respirar'), isTrue);
      expect(sugiereConsultarEquipo('tuvo vómitos toda la noche'), isTrue);
    });

    test('una consulta sin señales no sugiere nada', () {
      expect(sugiereConsultarEquipo('¿qué puede comer hoy?'), isFalse);
      expect(sugiereConsultarEquipo('   '), isFalse);
    });
  });

  group('etiquetaDia', () {
    final ahora = DateTime(2026, 10, 4, 12);

    test('hoy y ayer se nombran', () {
      expect(etiquetaDia(DateTime(2026, 10, 4, 1), ahora), 'Hoy');
      expect(etiquetaDia(DateTime(2026, 10, 3, 23), ahora), 'Ayer');
    });

    test('un día anterior muestra la fecha larga', () {
      expect(etiquetaDia(DateTime(2026, 10, 1), ahora), 'Jueves 01/10/2026');
    });
  });
}
