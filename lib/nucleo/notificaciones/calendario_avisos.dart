import 'package:timezone/timezone.dart' as tz;

const diasPorSemana = {
  'lun': DateTime.monday,
  'mar': DateTime.tuesday,
  'mie': DateTime.wednesday,
  'jue': DateTime.thursday,
  'vie': DateTime.friday,
  'sab': DateTime.saturday,
  'dom': DateTime.sunday,
};

tz.TZDateTime proximaCoincidenciaSemanal(
  tz.TZDateTime ahora,
  DateTime horaProgramada,
  List<String> dias,
) {
  final candidato = tz.TZDateTime(
    ahora.location,
    ahora.year,
    ahora.month,
    ahora.day,
    horaProgramada.hour,
    horaProgramada.minute,
  );
  final objetivos =
      (dias.map((d) => diasPorSemana[d]).toList()
            ..removeWhere((d) => d == null))
          .toSet();

  for (var i = 0; i <= 7; i++) {
    final prueba = candidato.add(Duration(days: i));
    if (objetivos.contains(prueba.weekday) && prueba.isAfter(ahora)) {
      return prueba;
    }
  }
  return candidato.add(const Duration(days: 1));
}

tz.TZDateTime proximaMensual(tz.TZDateTime ahora, DateTime horaProgramada) {
  var anio = ahora.year;
  var mes = ahora.month;
  for (var i = 0; i < 13; i++) {
    final diasEnMes = DateTime(anio, mes + 1, 0).day;
    final dia = horaProgramada.day > diasEnMes ? diasEnMes : horaProgramada.day;
    final candidato = tz.TZDateTime(
      ahora.location,
      anio,
      mes,
      dia,
      horaProgramada.hour,
      horaProgramada.minute,
    );
    if (candidato.isAfter(ahora)) return candidato;
    mes++;
    if (mes > 12) {
      mes = 1;
      anio++;
    }
  }
  return ahora.add(const Duration(days: 32));
}

tz.TZDateTime momentoUnaVez(tz.TZDateTime ahora, DateTime fechaHora) {
  final momento = tz.TZDateTime(
    ahora.location,
    fechaHora.year,
    fechaHora.month,
    fechaHora.day,
    fechaHora.hour,
    fechaHora.minute,
  );
  return momento.isBefore(ahora)
      ? momento.add(const Duration(days: 1))
      : momento;
}
