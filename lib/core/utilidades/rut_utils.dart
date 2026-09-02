library;

final RegExp _soloDigitosK = RegExp(r'^[0-9kK]$');

/// Formatea un RUT mientras se escribe: agrega puntos cada 3 digitos y el
String formatearRut(String valor) {
  var limpio = valor.replaceAll(RegExp(r'[^0-9kK]'), '').toUpperCase();
  if (limpio.isEmpty) return '';
  // Un solo caracter es el primer digito del cuerpo: no lo borres ni lo
  // conviertas en digito verificador todavia.
  if (limpio.length == 1) return limpio;

  final cuerpo = limpio.substring(0, limpio.length - 1);
  final digito = limpio.substring(limpio.length - 1);

  var cuerpoFormateado = '';
  for (var i = cuerpo.length; i > 0; i -= 3) {
    final inicio = i - 3 < 0 ? 0 : i - 3;
    cuerpoFormateado =
        cuerpo.substring(inicio, i) +
        (cuerpoFormateado.isEmpty ? '' : '.$cuerpoFormateado');
  }

  if (digito.isNotEmpty && !_soloDigitosK.hasMatch(digito)) {
    return cuerpoFormateado;
  }
  return digito.isEmpty ? cuerpoFormateado : '$cuerpoFormateado-$digito';
}

/// Calcula el digito verificador a partir del cuerpo numerico.
String _digitoVerificador(int cuerpo) {
  var suma = 0;
  var multiplicador = 2;
  var resto = cuerpo;
  while (resto > 0) {
    suma += (resto % 10) * multiplicador;
    resto ~/= 10;
    multiplicador = multiplicador == 7 ? 2 : multiplicador + 1;
  }
  final mod = 11 - (suma % 11);
  switch (mod) {
    case 11:
      return '0';
    case 10:
      return 'K';
    default:
      return '$mod';
  }
}

/// Valida que el RUT sea correcto, incluyendo el digito verificador.
bool validarRut(String valor) {
  final limpio = valor.replaceAll(RegExp(r'[^0-9kK]'), '').toUpperCase();
  if (limpio.length < 2) return false;

  final cuerpoStr = limpio.substring(0, limpio.length - 1);
  final digito = limpio.substring(limpio.length - 1);
  final cuerpo = int.tryParse(cuerpoStr);
  if (cuerpo == null) return false;

  return _digitoVerificador(cuerpo) == digito;
}