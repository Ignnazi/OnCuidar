final _formato = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$');

const _edadMaxima = 120;

int edadEnAnios(DateTime nacimiento, DateTime hoy) {
  var anios = hoy.year - nacimiento.year;
  final yaCumplio =
      hoy.month > nacimiento.month ||
      (hoy.month == nacimiento.month && hoy.day >= nacimiento.day);
  if (!yaCumplio) anios--;
  return anios;
}

DateTime? leerFechaNacimiento(String texto) {
  final partes = _formato.firstMatch(texto.trim());
  if (partes == null) return null;
  final dia = int.parse(partes.group(1)!);
  final mes = int.parse(partes.group(2)!);
  final anio = int.parse(partes.group(3)!);
  final fecha = DateTime(anio, mes, dia);
  if (fecha.year != anio || fecha.month != mes || fecha.day != dia) {
    return null;
  }
  return fecha;
}

String formatearFechaNacimiento(DateTime fecha) {
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year}';
}

String? validarFechaNacimiento(String? texto, {DateTime? hoy}) {
  final valor = texto?.trim() ?? '';
  if (valor.isEmpty) return 'Ingresa la fecha de nacimiento';
  final fecha = leerFechaNacimiento(valor);
  if (fecha == null) return 'Usa el formato dd/mm/aaaa';
  final referencia = hoy ?? DateTime.now();
  if (fecha.isAfter(referencia)) return 'La fecha no puede ser futura';
  if (edadEnAnios(fecha, referencia) > _edadMaxima) {
    return 'Revisa el año de nacimiento';
  }
  return null;
}

String fechaNacimientoGuardada(DateTime fecha) =>
    fecha.toIso8601String().substring(0, 10);
