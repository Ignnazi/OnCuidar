import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/compartido/widgets/accion_descargar.dart';
import 'package:oncuidar/compartido/widgets/controles_zoom.dart';
import 'package:oncuidar/compartido/widgets/marco_visor.dart';
import 'package:oncuidar/compartido/widgets/visor_con_zoom.dart';
import 'package:pdfx/pdfx.dart';

typedef ConstructorDocumentoPdf = Widget Function(String ruta);

final constructorDocumentoPdfProvider = Provider<ConstructorDocumentoPdf?>(
  (_) => null,
);

Future<void> abrirVisorPdf(
  BuildContext context, {
  required String ruta,
  required String titulo,
  VoidCallback? alCompartir,
  Future<bool> Function()? alDescargar,
}) {
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      builder: (_) => PantallaVisorPdf(
        ruta: ruta,
        titulo: titulo,
        alCompartir: alCompartir,
        alDescargar: alDescargar,
      ),
    ),
  );
}

class PantallaVisorPdf extends ConsumerWidget {
  const PantallaVisorPdf({
    super.key,
    required this.ruta,
    required this.titulo,
    this.constructorDocumento,
    this.alCompartir,
    this.alDescargar,
  });

  /// Ruta local del archivo ya descargado.
  final String ruta;
  final String titulo;
  final ConstructorDocumentoPdf? constructorDocumento;

  final VoidCallback? alCompartir;

  final Future<bool> Function()? alDescargar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final constructor =
        constructorDocumento ?? ref.watch(constructorDocumentoPdfProvider);
    return MarcoVisor(
      fondo: const Color(0xFF0B0B0D),
      titulo: titulo,
      claveVolver: const Key('cerrarVisorPdf'),
      acciones: [
        if (alDescargar != null)
          IconButton(
            key: const Key('descargarVisorPdf'),
            tooltip: 'Descargar',
            icon: const Icon(Icons.download_rounded),
            onPressed: () => descargarConAviso(context, alDescargar!),
          ),
        if (alCompartir != null)
          IconButton(
            key: const Key('compartirVisorPdf'),
            tooltip: 'Compartir',
            icon: const Icon(Icons.share_rounded),
            onPressed: alCompartir,
          ),
      ],
      cuerpo: constructor != null
          ? constructor(ruta)
          : _DocumentoPdf(ruta: ruta),
    );
  }
}

class IndicadorPaginaPdf extends StatelessWidget {
  const IndicadorPaginaPdf({
    super.key,
    required this.pagina,
    required this.total,
  });

  final int pagina;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('indicadorPaginaPdf'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '$pagina / $total',
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

const zoomMaximoPdf = 6.0;

/// Separación entre páginas.
const _separacionPaginas = 10.0;

const _pixelesMaximos = 4096.0;

const _margenNitidez = 2.0;

class _DocumentoPdf extends StatefulWidget {
  const _DocumentoPdf({required this.ruta});

  final String ruta;

  @override
  State<_DocumentoPdf> createState() => _DocumentoPdfState();
}

typedef _Dibujo = ({Uint8List bytes, double pixeles});

class _DocumentoPdfState extends State<_DocumentoPdf> {
  final _proporciones = <double>[];
  final _dibujos = <int, _Dibujo>{};

  final _enCurso = <int, double>{};
  Set<int> _cercanas = {0, 1};
  PdfDocument? _documento;
  bool _error = false;
  bool _cargaIniciada = false;
  bool _cerrado = false;
  int _paginaActual = 1;
  double _ancho = 0;
  double _densidad = 2;
  double _factor = 1;

  Future<void> _fila = Future.value();

  @override
  void dispose() {
    _cerrado = true;
    final documento = _documento;
    if (documento != null) {
      unawaited(_fila.whenComplete(documento.close));
    }
    super.dispose();
  }

  Future<T> _enFila<T>(Future<T> Function() tarea) {
    final resultado = _fila.then((_) => tarea());
    _fila = resultado.then<void>((_) {}, onError: (_) {});
    return resultado;
  }

  Future<void> _cargar() async {
    try {
      final documento = await PdfDocument.openFile(widget.ruta);
      _documento = documento;
      if (_cerrado) {
        await documento.close();
        return;
      }
      final proporciones = <double>[];
      for (var i = 1; i <= documento.pagesCount; i++) {
        proporciones.add(
          await _enFila(() async {
            final pagina = await documento.getPage(i);
            final p = pagina.height / pagina.width;
            await pagina.close();
            return p;
          }),
        );
      }
      if (_cerrado || !mounted) return;
      setState(() => _proporciones.addAll(proporciones));
      _asegurarNitidez();
    } on Object {
      if (mounted) setState(() => _error = true);
    }
  }

  double get _pixelesNecesarios =>
      (_ancho * _factor * _densidad * _margenNitidez).clamp(
        400.0,
        _pixelesMaximos,
      );

  void _asegurarNitidez() {
    final necesarios = _pixelesNecesarios;
    for (final i in _cercanas) {
      if (i >= _proporciones.length) continue;
      final actual = _dibujos[i]?.pixeles ?? 0;
      final pedido = _enCurso[i] ?? 0;
      if (actual >= necesarios / _margenNitidez * 1.1 && actual > 0) continue;
      if (pedido >= necesarios * 0.9) continue;
      _enCurso[i] = necesarios;
      unawaited(_dibujar(i, necesarios));
    }
  }

  Future<void> _dibujar(int indice, double pixeles) async {
    try {
      final dibujo = await _enFila<_Dibujo?>(() async {
        final documento = _documento;
        if (documento == null || _cerrado || !_cercanas.contains(indice)) {
          return null;
        }
        final pagina = await documento.getPage(indice + 1);
        try {
          final imagen = await pagina.render(
            width: pixeles,
            height: pixeles * _proporciones[indice],
            format: PdfPageImageFormat.jpeg,
            backgroundColor: '#FFFFFF',
            quality: 92,
          );
          return imagen == null
              ? null
              : (bytes: imagen.bytes, pixeles: pixeles);
        } finally {
          await pagina.close();
        }
      });
      if (dibujo != null && mounted && !_cerrado) {
        setState(() => _dibujos[indice] = dibujo);
      }
    } on Object {
      // Si falla, se sigue igual.
    } finally {
      if (_enCurso[indice] == pixeles) _enCurso.remove(indice);
    }
  }

  double _altoDocumento(double factor) {
    var alto = 0.0;
    for (final p in _proporciones) {
      alto += _ancho * factor * p + _separacionPaginas;
    }
    return alto;
  }

  void _alMover(Matrix4 matriz, Size zona, double factor) {
    if (_proporciones.isEmpty || _ancho == 0) return;
    final estirado = escalaDe(matriz);
    final relleno = ((zona.height * factor - _altoDocumento(factor)) / 2).clamp(
      0.0,
      double.infinity,
    );
    final arriba = -matriz.getTranslation().y / estirado - relleno;
    final abajo = arriba + zona.height / estirado;
    final centro = (arriba + abajo) / 2;

    var acumulado = 0.0;
    var pagina = _proporciones.length;
    final visibles = <int>[];
    for (var i = 0; i < _proporciones.length; i++) {
      final inicio = acumulado;
      acumulado += _ancho * factor * _proporciones[i] + _separacionPaginas;
      if (acumulado > arriba && inicio < abajo) visibles.add(i);
      if (centro < acumulado && pagina == _proporciones.length) {
        pagina = i + 1;
      }
    }
    if (visibles.isEmpty) return;
    final cercanas = {
      for (var i = visibles.first - 1; i <= visibles.last + 1; i++)
        if (i >= 0 && i < _proporciones.length) i,
    };
    final cambio =
        pagina != _paginaActual ||
        cercanas.length != _cercanas.length ||
        !cercanas.containsAll(_cercanas);
    _factor = factor;
    if (cambio) {
      setState(() {
        _paginaActual = pagina;
        _cercanas = cercanas;
        _dibujos.removeWhere((i, _) => !cercanas.contains(i));
      });
    }
    _asegurarNitidez();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        _ancho = restricciones.maxWidth;
        _densidad = MediaQuery.of(context).devicePixelRatio;
        if (!_cargaIniciada) {
          _cargaIniciada = true;
          unawaited(_cargar());
        }
        if (_error) {
          return Center(
            child: Text(
              'No se pudo mostrar el PDF.',
              style: GoogleFonts.nunito(fontSize: 14, color: Colors.white),
            ),
          );
        }
        if (_proporciones.isEmpty) {
          return Center(
            child: CircularProgressIndicator(color: Paleta.doradoMedio),
          );
        }
        return VisorConZoom(
          claveVisor: const Key('zoomVisorPdf'),
          zoomMaximo: zoomMaximoPdf,
          alMover: _alMover,
          pie: IndicadorPaginaPdf(
            pagina: _paginaActual,
            total: _proporciones.length,
          ),
          constructor: (_, factor) => SizedBox(
            width: _ancho * factor,
            child: Column(
              children: [
                for (var i = 0; i < _proporciones.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == _proporciones.length - 1
                          ? 0
                          : _separacionPaginas,
                    ),
                    child: SizedBox(
                      width: _ancho * factor,
                      height: _ancho * factor * _proporciones[i],
                      child: _dibujos[i] == null
                          ? const ColoredBox(color: Colors.white)
                          : Image.memory(
                              _dibujos[i]!.bytes,
                              fit: BoxFit.fill,
                              gaplessPlayback: true,
                              filterQuality: FilterQuality.medium,
                            ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
