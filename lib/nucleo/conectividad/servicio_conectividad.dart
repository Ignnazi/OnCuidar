import 'package:connectivity_plus/connectivity_plus.dart';

class ServicioConectividad {
  ServicioConectividad({
    Future<List<ConnectivityResult>> Function()? consultar,
    Stream<List<ConnectivityResult>> Function()? cambios,
  }) : _consultar = consultar ?? (() => Connectivity().checkConnectivity()),
       _cambios = cambios ?? (() => Connectivity().onConnectivityChanged);

  final Future<List<ConnectivityResult>> Function() _consultar;
  final Stream<List<ConnectivityResult>> Function() _cambios;

  static bool _hayRed(List<ConnectivityResult> resultados) =>
      resultados.any((r) => r != ConnectivityResult.none);

  Future<bool> estaEnLinea() async {
    try {
      return _hayRed(await _consultar());
    } catch (_) {
      return true;
    }
  }

  Stream<bool> enLinea() => _cambios().map(_hayRed).distinct();
}
