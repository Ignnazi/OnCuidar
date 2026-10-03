import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';
import 'package:oncuidar/nucleo/utilidades/formato_fecha.dart';

class FiltroHistorial {
  const FiltroHistorial({this.estado, this.inicio, this.fin});

  final String? estado;
  final DateTime? inicio;
  final DateTime? fin;

  bool get hayRango => inicio != null || fin != null;

  bool get hayFiltros => estado != null || hayRango;

  FiltroHistorial conEstado(String? estado) =>
      FiltroHistorial(estado: estado, inicio: inicio, fin: fin);

  FiltroHistorial conRango(DateTime? inicio, DateTime? fin) =>
      FiltroHistorial(estado: estado, inicio: inicio, fin: fin);

  bool coincideFecha(DateTime fecha) {
    final inicio = this.inicio;
    final fin = this.fin;
    if (inicio == null && fin == null) return true;
    if (inicio != null && fin == null) return mismoDia(fecha, inicio);
    if (inicio == null && fin != null) {
      final hasta = DateTime(fin.year, fin.month, fin.day, 23, 59, 59, 999);
      return !fecha.isAfter(hasta);
    }
    final desde = DateTime(inicio!.year, inicio.month, inicio.day);
    final hasta = DateTime(
      fin!.year,
      fin.month,
      fin.day,
    ).add(const Duration(days: 1));
    return !fecha.isBefore(desde) && fecha.isBefore(hasta);
  }

  bool admite(RegistroClinico registro) =>
      (estado == null || registro.nivelAlerta.name == estado) &&
      coincideFecha(registro.fecha);

  (DateTime?, DateTime?) limites() {
    DateTime inicioDia(DateTime f) => DateTime(f.year, f.month, f.day);
    DateTime diaSiguiente(DateTime f) => DateTime(f.year, f.month, f.day + 1);
    final inicio = this.inicio;
    final fin = this.fin;
    if (inicio == null && fin == null) return (null, null);
    if (fin == null) return (inicioDia(inicio!), diaSiguiente(inicio));
    return (inicio == null ? null : inicioDia(inicio), diaSiguiente(fin));
  }
}
