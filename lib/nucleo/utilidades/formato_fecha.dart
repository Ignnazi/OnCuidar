library;

String _dd(int v) => v.toString().padLeft(2, '0');

bool mismoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

const _diasSemana = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

String fechalarga(DateTime fecha) =>
    '${_diasSemana[fecha.weekday - 1]} ${_dd(fecha.day)}/${_dd(fecha.month)}/${fecha.year}';

String fechacorta(DateTime fecha) =>
    '${_dd(fecha.day)}-${_dd(fecha.month)}-${fecha.year}';

String hora12(DateTime fecha) {
  final hora = fecha.hour % 12 == 0 ? 12 : fecha.hour % 12;
  final sufijo = fecha.hour >= 12 ? 'PM' : 'AM';
  return '$hora:${fecha.minute.toString().padLeft(2, '0')} $sufijo';
}

String fechaEntrada(DateTime fecha) =>
    '${_dd(fecha.day)}/${_dd(fecha.month)}/${fecha.year}';

DateTime? parsearFechaEntrada(String texto) {
  final partes = texto.trim().split('/');
  if (partes.length != 3) return null;
  final dia = int.tryParse(partes[0]);
  final mes = int.tryParse(partes[1]);
  final anio = int.tryParse(partes[2]);
  if (dia == null || mes == null || anio == null) return null;
  if (dia < 1 || dia > 31 || mes < 1 || mes > 12 || anio < 1900) return null;
  final fecha = DateTime(anio, mes, dia);
  if (fecha.day != dia || fecha.month != mes || fecha.year != anio) {
    return null;
  }
  return fecha;
}
