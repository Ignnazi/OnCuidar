import '../../modelos/registro_clinico.dart';
import 'formato_fecha.dart';

int contarProgramadosDelDia(
  Iterable<RegistroClinico> registros,
  DateTime dia,
) => registros
    .where((r) => r.tipoRegistro == 'programado' && mismoDia(r.fecha, dia))
    .length;

int contarExtrasDelDia(Iterable<RegistroClinico> registros, DateTime dia) =>
    registros
        .where((r) => r.tipoRegistro == 'extra' && mismoDia(r.fecha, dia))
        .length;
