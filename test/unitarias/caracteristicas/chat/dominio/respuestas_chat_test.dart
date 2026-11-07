import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/chat/dominio/respuestas_chat.dart';
import 'package:oncuidar/caracteristicas/preguntas_frecuentes/dominio/catalogo_preguntas.dart';

void main() {
  group('respuesta del asistente', () {
    test('responde con la pregunta del catálogo que más se parece', () {
      final pregunta = resolverPregunta(
        'mi hijo tiene fiebre, cuándo llamo al médico',
        preguntasFrecuentes,
      );
      expect(pregunta?.id, 'fiebre');
    });

    test('entiende la pregunta aunque venga sin tildes', () {
      final pregunta = resolverPregunta(
        'que temperatura es fiebre',
        preguntasFrecuentes,
      );
      expect(pregunta?.id, 'fiebre');
    });

    final casos = {
      'le sangra la nariz, cómo hago el taponamiento': 'taponamiento-nasal',
      'le salieron petequias': 'petequias',
      'se puede bañar en la piscina con el cateter': 'cateter-bano',
      'qué alimentos debe evitar': 'alimentos-evitar',
      'tiene diarrea qué le doy': 'diarrea',
      'tiene llagas en la boca': 'mucositis',
      'puede tener perro': 'mascotas',
      'se me olvidó darle la dosis del antibiótico': 'dosis-olvidada',
      'cuándo le ponen las vacunas': 'vacunas',
      'cómo sé si le duele si no habla': 'dolor-escalas',
      'efectos de los corticoides en el humor': 'esteroides',
      'la orina salió de color rojo': 'orina-color',
    };
    for (final caso in casos.entries) {
      test('"${caso.key}" responde ${caso.value}', () {
        expect(resolverPregunta(caso.key, preguntasFrecuentes)?.id, caso.value);
      });
    }

    test('sin coincidencias no inventa una respuesta', () {
      expect(resolverPregunta('xyz qwerty', preguntasFrecuentes), isNull);
      expect(resolverPregunta('   ', preguntasFrecuentes), isNull);
    });
  });

  group('aviso de consultar al equipo médico', () {
    test('aparece ante señales de alarma', () {
      expect(sugiereConsultarEquipo('Tiene FIEBRE desde anoche'), isTrue);
      expect(sugiereConsultarEquipo('le salieron petequias'), isTrue);
    });

    test('no aparece en una duda común', () {
      expect(sugiereConsultarEquipo('qué puede comer en la tarde'), isFalse);
    });
  });

  group('título de la conversación', () {
    test('usa la primera pregunta tal cual si es corta', () {
      expect(
        tituloAutomaticoConversacion('  ¿Cómo lavo el catéter?  '),
        '¿Cómo lavo el catéter?',
      );
    });

    test('corta una pregunta larga sin partir palabras', () {
      final titulo = tituloAutomaticoConversacion(
        '¿Qué alimentos puede comer mi hijo durante la quimioterapia en casa?',
      );
      expect(
        titulo.length,
        lessThanOrEqualTo(largoMaximoTituloConversacion + 1),
      );
      expect(titulo, endsWith('…'));
      expect(titulo, isNot(contains('quimioterapia')));
    });

    test('sin texto el título es Consulta', () {
      expect(tituloAutomaticoConversacion('   '), 'Consulta');
    });
  });
}
