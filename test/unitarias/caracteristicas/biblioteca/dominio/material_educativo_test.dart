import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/material_educativo.dart';

MaterialEducativo _material({String? tipo, String? url}) => MaterialEducativo(
  id: 'm',
  titulo: 't',
  categoria: 'Guías',
  tema: '',
  cuerpo: '',
  tipoArchivo: tipo,
  urlArchivo: url,
  creadoEn: DateTime.utc(2026, 1, 1),
);

void main() {
  test('esPdf reconoce el tipo declarado o la extensión del archivo', () {
    expect(_material(tipo: 'pdf').esPdf, isTrue);
    expect(
      _material(url: 'https://x.test/o/Guias%2Fmanual.pdf?alt=media').esPdf,
      isTrue,
    );
    expect(
      _material(tipo: 'video', url: 'https://x.test/v.mp4').esPdf,
      isFalse,
    );
    expect(_material().esPdf, isFalse);
  });
}
