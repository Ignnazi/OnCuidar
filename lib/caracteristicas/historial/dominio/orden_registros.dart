import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';

List<RegistroClinico> ordenarCronologicamente(List<RegistroClinico> registros) {
  return [...registros]..sort((a, b) {
    final porFecha = a.fecha.compareTo(b.fecha);
    return porFecha != 0 ? porFecha : a.creadoEn.compareTo(b.creadoEn);
  });
}
