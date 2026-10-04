enum EscalaTexto {
  normal('Normal', 1.0),
  grande('Grande', 1.15),
  muyGrande('Muy grande', 1.3);

  const EscalaTexto(this.etiqueta, this.factor);

  final String etiqueta;

  final double factor;

  static EscalaTexto desdeNombre(String? nombre) {
    for (final escala in values) {
      if (escala.name == nombre) return escala;
    }
    return normal;
  }
}
