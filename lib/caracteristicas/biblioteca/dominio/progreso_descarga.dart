const tamanoEstimadoPorDefecto = 1500000;

class ProgresoDescarga {
  ProgresoDescarga(
    Map<String, int?> tamanosDeclarados, {
    this.estimacionPorDefecto = tamanoEstimadoPorDefecto,
  }) {
    for (final entrada in tamanosDeclarados.entries) {
      final declarado = entrada.value;
      _conocidos[entrada.key] = (declarado != null && declarado > 0)
          ? declarado
          : null;
    }
  }

  final int estimacionPorDefecto;
  final Map<String, int?> _conocidos = {};
  final Map<String, int> _descargados = {};
  final Set<String> _resueltas = {};
  int _mostrado = 0;

  int get cantidad => _conocidos.length;

  bool get terminado => _resueltas.length >= _conocidos.length;

  int get _estimacion {
    final conocidos = _conocidos.values.whereType<int>().toList();
    if (conocidos.isEmpty) return estimacionPorDefecto;
    return conocidos.reduce((a, b) => a + b) ~/ conocidos.length;
  }

  int _totalDe(String url, int estimacion) {
    final base = _conocidos[url] ?? estimacion;
    final descargado = _descargados[url] ?? 0;
    return descargado > base ? descargado : base;
  }

  void avanzar(String url, int descargado, {int? total}) {
    if (!_conocidos.containsKey(url) || _resueltas.contains(url)) return;
    if (total != null && total > 0) _conocidos[url] = total;
    final previo = _descargados[url] ?? 0;
    if (descargado > previo) _descargados[url] = descargado;
  }

  void completar(String url, {int? tamanoReal}) {
    if (!_conocidos.containsKey(url)) return;
    if (tamanoReal != null && tamanoReal > 0) _conocidos[url] = tamanoReal;
    _resueltas.add(url);
    _descargados[url] = _totalDe(url, _estimacion);
  }

  void descartar(String url) {
    if (!_conocidos.containsKey(url)) return;
    _resueltas.add(url);
    _descargados[url] = _totalDe(url, _estimacion);
  }

  int get porcentaje {
    if (_conocidos.isEmpty) return 0;
    final estimacion = _estimacion;
    var total = 0;
    var hecho = 0;
    for (final url in _conocidos.keys) {
      final t = _totalDe(url, estimacion);
      total += t;
      hecho += _resueltas.contains(url) ? t : (_descargados[url] ?? 0);
    }
    var valor = total == 0 ? 0 : (hecho * 100) ~/ total;
    if (!terminado && valor > 99) valor = 99;
    if (terminado) valor = 100;
    if (valor > _mostrado) _mostrado = valor;
    return _mostrado;
  }
}
