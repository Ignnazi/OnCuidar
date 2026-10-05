import 'package:flutter/material.dart';

double escalaDe(Matrix4 matriz) => matriz.getColumn(0).length;

Matrix4 escalaUniforme(double escala) =>
    Matrix4.diagonal3Values(escala, escala, escala);

Matrix4 zoomAlrededor(
  Matrix4 matriz,
  double factor,
  Offset centro, {
  required double minima,
  required double maxima,
}) {
  final actual = escalaDe(matriz);
  final nueva = (actual * factor).clamp(minima, maxima);
  final relativo = nueva / actual;
  final alrededor =
      Matrix4.translationValues(centro.dx, centro.dy, 0) *
      Matrix4.diagonal3Values(relativo, relativo, relativo) *
      Matrix4.translationValues(-centro.dx, -centro.dy, 0);
  return alrededor * matriz;
}

class ControlesZoom extends StatelessWidget {
  const ControlesZoom({
    super.key,
    required this.alAcercar,
    required this.alAlejar,
    required this.alAjustar,
    this.sobreOscuro = true,
  });

  final VoidCallback alAcercar;
  final VoidCallback alAlejar;
  final VoidCallback alAjustar;

  final bool sobreOscuro;

  @override
  Widget build(BuildContext context) {
    final fondo = sobreOscuro
        ? Colors.black.withValues(alpha: 0.65)
        : Colors.white.withValues(alpha: 0.92);
    final icono = sobreOscuro ? Colors.white : const Color(0xFF2C1A00);
    Widget boton(
      Key clave,
      IconData datos,
      String ayuda,
      VoidCallback alTocar,
    ) => IconButton(
      key: clave,
      tooltip: ayuda,
      onPressed: alTocar,
      icon: Icon(datos, color: icono),
      visualDensity: VisualDensity.compact,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          boton(const Key('zoomMas'), Icons.add_rounded, 'Acercar', alAcercar),
          boton(
            const Key('zoomMenos'),
            Icons.remove_rounded,
            'Alejar',
            alAlejar,
          ),
          boton(
            const Key('zoomAjustar'),
            Icons.fit_screen_rounded,
            'Ajustar al ancho',
            alAjustar,
          ),
        ],
      ),
    );
  }
}
