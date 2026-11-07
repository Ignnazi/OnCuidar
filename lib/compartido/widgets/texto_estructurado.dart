import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';

enum TipoBloque { parrafo, titulo, vineta, paso }

class BloqueTexto {
  const BloqueTexto(this.tipo, this.texto, {this.etiqueta, this.numero});

  final TipoBloque tipo;
  final String texto;

  final String? etiqueta;
  final String? numero;

  static final _paso = RegExp(r'^(\d+)\.\s+(.+)$');
  static const _largoMaximoTitulo = 60;
  static const _largoMaximoEtiqueta = 30;

  static List<BloqueTexto> desde(String texto) {
    final bloques = <BloqueTexto>[];
    for (final crudo in texto.split('\n')) {
      final linea = crudo.trim();
      if (linea.isEmpty) continue;
      if (linea.startsWith('• ')) {
        bloques.add(_vineta(linea.substring(2).trim()));
        continue;
      }
      final paso = _paso.firstMatch(linea);
      if (paso != null) {
        bloques.add(
          BloqueTexto(TipoBloque.paso, paso.group(2)!, numero: paso.group(1)),
        );
        continue;
      }
      if (linea.endsWith(':') && linea.length <= _largoMaximoTitulo) {
        bloques.add(
          BloqueTexto(TipoBloque.titulo, linea.substring(0, linea.length - 1)),
        );
        continue;
      }
      bloques.add(BloqueTexto(TipoBloque.parrafo, linea));
    }
    return bloques;
  }

  static BloqueTexto _vineta(String texto) {
    final corte = texto.indexOf(': ');
    if (corte > 0 && corte <= _largoMaximoEtiqueta) {
      return BloqueTexto(
        TipoBloque.vineta,
        texto.substring(corte + 2),
        etiqueta: texto.substring(0, corte),
      );
    }
    return BloqueTexto(TipoBloque.vineta, texto);
  }
}

class TextoEstructurado extends StatelessWidget {
  const TextoEstructurado(this.texto, {super.key, this.estilo});

  final String texto;
  final TextStyle? estilo;

  @override
  Widget build(BuildContext context) {
    final base =
        estilo ??
        GoogleFonts.nunito(
          fontSize: 13.5,
          color: Paleta.textoPrincipal,
          height: 1.5,
        );
    final bloques = BloqueTexto.desde(texto);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < bloques.length; i++)
          Padding(
            padding: EdgeInsets.only(top: _espacioAntes(bloques, i)),
            child: _bloque(bloques[i], base),
          ),
      ],
    );
  }

  double _espacioAntes(List<BloqueTexto> bloques, int i) {
    if (i == 0) return 0;
    if (bloques[i].tipo == TipoBloque.titulo) return 14;
    if (bloques[i].tipo == bloques[i - 1].tipo) return 6;
    return 10;
  }

  Widget _bloque(BloqueTexto bloque, TextStyle base) {
    switch (bloque.tipo) {
      case TipoBloque.parrafo:
        return Text(bloque.texto, style: base);
      case TipoBloque.titulo:
        return Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: Paleta.doradoPrincipal,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                bloque.texto,
                style: base.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Paleta.doradoOscuro,
                  height: 1.3,
                ),
              ),
            ),
          ],
        );
      case TipoBloque.vineta:
        final tamano = base.fontSize ?? 13.5;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 7,
              height: 7,
              margin: EdgeInsets.only(top: tamano * 0.6, left: 2, right: 10),
              decoration: BoxDecoration(
                color: Paleta.doradoPrincipal,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: base,
                  children: [
                    if (bloque.etiqueta != null)
                      TextSpan(
                        text: '${bloque.etiqueta}: ',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    TextSpan(text: bloque.texto),
                  ],
                ),
              ),
            ),
          ],
        );
      case TipoBloque.paso:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(right: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Paleta.doradoPrincipal,
                shape: BoxShape.circle,
              ),
              child: Text(
                bloque.numero!,
                style: GoogleFonts.nunito(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: Paleta.sobreDorado,
                ),
              ),
            ),
            Expanded(child: Text(bloque.texto, style: base)),
          ],
        );
    }
  }
}
