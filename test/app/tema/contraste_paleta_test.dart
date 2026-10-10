import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/compartido/widgets/insignia_conteo.dart';

double contraste(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final claro = la > lb ? la : lb;
  final oscuro = la > lb ? lb : la;
  return (claro + 0.05) / (oscuro + 0.05);
}

void main() {
  tearDown(() => Paleta.usar(coloresClaros));

  group('Contraste del modo oscuro (4,5 es el mínimo para texto)', () {
    const c = coloresOscuros;
    final fondos = {
      'crema': c.crema,
      'tarjeta': c.tarjeta,
      'fondoEntrada': c.fondoEntrada,
      'doradoClaro': c.doradoClaro,
    };
    final textos = {
      'textoPrincipal': c.textoPrincipal,
      'textoSecundario': c.textoSecundario,
      'doradoOscuro (texto e íconos)': c.doradoOscuro,
    };

    for (final texto in textos.entries) {
      for (final fondo in fondos.entries) {
        test('${texto.key} sobre ${fondo.key}', () {
          expect(
            contraste(texto.value, fondo.value),
            greaterThanOrEqualTo(4.5),
          );
        });
      }
    }

    test('textoAyuda (pistas) sobre tarjeta y campos', () {
      expect(contraste(c.textoAyuda, c.tarjeta), greaterThanOrEqualTo(4.5));
      expect(
        contraste(c.textoAyuda, c.fondoEntrada),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('el café sobre dorado se lee sobre todos los rellenos', () {
      for (final dorado in [
        c.doradoPrincipal,
        c.doradoMedio,
        Paleta.doradoRelleno,
      ]) {
        expect(contraste(c.sobreDorado, dorado), greaterThanOrEqualTo(4.5));
      }
    });
  });

  group(
    'Contraste del modo claro (el diseño original, solo se verifica lo propio)',
    () {
      const c = coloresClaros;

      test(
        'el texto principal y el terciario se leen sobre las superficies',
        () {
          for (final fondo in [
            c.crema,
            c.tarjeta,
            c.fondoEntrada,
            c.doradoClaro,
          ]) {
            expect(contraste(c.textoPrincipal, fondo), greaterThanOrEqualTo(7));
          }
          for (final fondo in [c.crema, c.tarjeta]) {
            expect(
              contraste(c.textoTerciario, fondo),
              greaterThanOrEqualTo(4.5),
            );
          }
        },
      );
    },
  );

  group('Acentos de tema: texto legible sobre su fondo y sobre la tarjeta', () {
    for (final (nombre, c) in [
      ('claro', coloresClaros),
      ('oscuro', coloresOscuros),
    ]) {
      for (var i = 0; i < c.acentosTema.length; i++) {
        test('modo $nombre, acento $i', () {
          final a = c.acentosTema[i];
          expect(contraste(a.texto, a.fondo), greaterThanOrEqualTo(4.5));
          expect(contraste(a.texto, c.tarjeta), greaterThanOrEqualTo(4.5));
        });
      }
    }
  });

  group('Insignia con número', () {
    for (final (nombre, c) in [
      ('claro', coloresClaros),
      ('oscuro', coloresOscuros),
    ]) {
      test('en modo $nombre: número blanco, aro claro y fondo del degradado', () {
        Paleta.usar(c);
        expect(InsigniaConteo.colorNumero, const Color(0xFFFFFFFF));
        expect(
          contraste(InsigniaConteo.colorNumero, InsigniaConteo.colorFondo()),
          greaterThan(2.0),
        );
        // El aro claro la separa del botón en oscuro.
        if (c.oscuro) {
          expect(
            contraste(Paleta.aroInsignia, Paleta.tarjeta),
            greaterThanOrEqualTo(4.5),
          );
        }
      });
    }

    test('el fondo es el del degradado y no cambia con el modo', () {
      final claro = InsigniaConteo.colorFondo();
      Paleta.usar(coloresOscuros);
      expect(InsigniaConteo.colorFondo(), claro);
    });
  });
}
