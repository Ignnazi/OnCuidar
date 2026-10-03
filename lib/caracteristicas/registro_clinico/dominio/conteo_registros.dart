import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';
import 'package:oncuidar/nucleo/utilidades/formato_fecha.dart';

Iterable<RegistroClinico> programadosDelDia(
  Iterable<RegistroClinico> registros,
  DateTime dia,
) => registros.where(
  (r) => r.tipoRegistro == 'programado' && mismoDia(r.fecha, dia),
);

/// Cantidad de registros programados del día.
int contarProgramadosDelDia(
  Iterable<RegistroClinico> registros,
  DateTime dia,
) => programadosDelDia(registros, dia).length;

int contarExtrasDelDia(Iterable<RegistroClinico> registros, DateTime dia) =>
    registros
        .where((r) => r.tipoRegistro == 'extra' && mismoDia(r.fecha, dia))
        .length;

String etiquetaNumeroRegistro(
  RegistroClinico registro,
  Iterable<RegistroClinico> todos,
  int tope,
) {
  if (registro.tipoRegistro == 'extra') return 'Registro extra';
  final delDia = programadosDelDia(todos, registro.fecha).toList()
    ..sort((a, b) => a.creadoEn.compareTo(b.creadoEn));
  final posicion = delDia.indexWhere((r) => r.id == registro.id);
  if (posicion == -1) return 'Registro 1/$tope';
  final numero = posicion + 1;
  return numero <= tope ? 'Registro $numero/$tope' : 'Registro extra';
}
