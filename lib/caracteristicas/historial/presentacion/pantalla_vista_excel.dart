import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/caracteristicas/historial/datos/exportador_excel.dart';
import 'package:oncuidar/caracteristicas/historial/datos/formato_exportacion.dart';
import 'package:oncuidar/caracteristicas/historial/dominio/orden_registros.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/paciente.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';
import 'package:oncuidar/compartido/widgets/accion_descargar.dart';
import 'package:oncuidar/compartido/widgets/marco_visor.dart';
import 'package:oncuidar/compartido/widgets/visor_con_zoom.dart';
import 'package:oncuidar/nucleo/utilidades/formato_fecha.dart';

class DatosHojaExcel {
  const DatosHojaExcel({
    required this.registros,
    required this.paciente,
    required this.nombreCuidador,
    required this.fechaInicio,
    required this.fechaFin,
    required this.generadoEn,
  });

  final List<RegistroClinico> registros;
  final Paciente? paciente;
  final String? nombreCuidador;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final DateTime generadoEn;
}

Future<void> abrirVistaExcel(
  BuildContext context, {
  required DatosHojaExcel datos,
  VoidCallback? alCompartir,
  Future<bool> Function()? alDescargar,
}) {
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      builder: (_) => PantallaVistaExcel(
        datos: datos,
        alCompartir: alCompartir,
        alDescargar: alDescargar,
      ),
    ),
  );
}

const _dorado = Color(0xFFE8A820);
const _doradoEncabezado = Color(0xFFC47E10);
const _doradoTexto = Color(0xFFC08808);
const _doradoClaro = Color(0xFFFFF4D0);
const _crema = Color(0xFFFFF9E8);
const _texto = Color(0xFF2C1A00);
const _textoSuave = Color(0xFF6B5330);
const _lineaSuave = Color(0xFFE8DCC0);

// Cuadrícula y bordes como en Excel.
const _rejilla = Color(0xFFD4D4D4);
const _fondoRotulos = Color(0xFFF1F1F1);
const _textoRotulos = Color(0xFF555555);

const _pxPorCaracter = 8.0;

/// Ancho de la columna con los números de fila.
const _anchoNumeros = 38.0;

const _altoLetras = 24.0;

const _altoLinea = 16.0;

const zoomMinimoHoja = 0.15;
const zoomMaximoHoja = 8.0;

const zoomInicialHoja = 0.8;

class _Celda {
  const _Celda(
    this.desde,
    this.hasta,
    this.texto, {
    this.fondo,
    this.color = _texto,
    this.negrita = false,
    this.tamano = 12,
    this.centrado = false,
    this.ajustar = false,
    this.linea,
  });

  final int desde;
  final int hasta;
  final String texto;
  final Color? fondo;
  final Color color;
  final bool negrita;
  final double tamano;
  final bool centrado;

  final bool ajustar;

  final Color? linea;
}

class _Fila {
  const _Fila(this.alto, this.celdas, {this.clave});

  final double alto;
  final List<_Celda> celdas;
  final Key? clave;
}

double _anchoColumnas(int desde, int hasta) {
  var total = 0.0;
  for (var i = desde; i <= hasta; i++) {
    total += anchosColumnasExcel[i] * _pxPorCaracter;
  }
  return total;
}

int _lineas(String texto, int desde, int hasta) {
  final caracteres = ((_anchoColumnas(desde, hasta) - 14) / 6.8).floor();
  return lineasNecesarias(texto, math.max(4, caracteres));
}

double _altoDato(String valor, int desde, int hasta) =>
    math.max(26, _lineas(valor, desde + 1, hasta) * _altoLinea + 10);

List<_Fila> _construirFilas(DatosHojaExcel datos) {
  final filas = <_Fila>[];
  const ultima = 9;
  const ultimaIzquierda = 4;
  const hueco = _Fila(12, []);

  final nombre = datos.paciente?.nombreCompleto.trim();
  filas
    ..add(
      const _Fila(36, [
        _Celda(
          0,
          ultima,
          'HISTORIAL ONCUIDAR',
          fondo: _dorado,
          color: Colors.white,
          negrita: true,
          tamano: 17,
        ),
      ]),
    )
    ..add(
      _Fila(26, [
        _Celda(
          0,
          ultima,
          [
            if (nombre != null && nombre.isNotEmpty) 'Paciente: $nombre',
            'Generado: ${fechacorta(datos.generadoEn)} '
                '${hora12(datos.generadoEn)}',
          ].join('   ·   '),
          color: _textoSuave,
          tamano: 11,
        ),
      ]),
    )
    ..add(hueco);

  final izquierda = bloquesPacienteYCuidador(
    datos.paciente,
    datos.nombreCuidador,
  );
  final derecha = bloquesCentroYContacto(datos.paciente);
  for (var i = 0; i < math.max(izquierda.length, derecha.length); i++) {
    final bloqueIzq = i < izquierda.length ? izquierda[i] : null;
    final bloqueDer = i < derecha.length ? derecha[i] : null;
    final cuantas = math.max(
      bloqueIzq == null ? 0 : bloqueIzq.filas.length + 1,
      bloqueDer == null ? 0 : bloqueDer.filas.length + 1,
    );
    for (var k = 0; k < cuantas; k++) {
      final celdas = <_Celda>[];
      var alto = 26.0;
      void lado(BloqueInfo? bloque, int desde, int hasta) {
        if (bloque == null || k > bloque.filas.length) return;
        if (k == 0) {
          celdas.add(
            _Celda(
              desde,
              hasta,
              bloque.titulo,
              fondo: _doradoClaro,
              color: _doradoTexto,
              negrita: true,
              tamano: 12.5,
            ),
          );
          return;
        }
        final (etiqueta, valor) = bloque.filas[k - 1];
        celdas
          ..add(
            _Celda(desde, desde, etiqueta, color: _doradoTexto, negrita: true),
          )
          ..add(_Celda(desde + 1, hasta, valor, ajustar: true));
        alto = math.max(alto, _altoDato(valor, desde, hasta));
      }

      lado(bloqueIzq, 0, ultimaIzquierda);
      lado(bloqueDer, ultimaIzquierda + 1, ultima);
      filas.add(_Fila(alto, celdas));
    }
    filas.add(hueco);
  }

  filas.add(
    const _Fila(26, [
      _Celda(
        0,
        ultima,
        'RESUMEN',
        fondo: _doradoClaro,
        color: _doradoTexto,
        negrita: true,
        tamano: 12.5,
      ),
    ]),
  );
  for (final (etiqueta, valor) in <FilaInfo>[
    (
      rotuloPeriodo(datos.fechaInicio, datos.fechaFin),
      etiquetaPeriodo(datos.fechaInicio, datos.fechaFin),
    ),
    ('Registros', '${datos.registros.length}'),
  ]) {
    filas.add(
      _Fila(_altoDato(valor, 0, ultimaIzquierda), [
        _Celda(0, 0, etiqueta, color: _doradoTexto, negrita: true),
        _Celda(1, ultimaIzquierda, valor, ajustar: true),
      ]),
    );
  }
  filas.add(const _Fila(14, []));

  filas.add(
    _Fila(30, [
      for (var i = 0; i < encabezadosRegistro.length; i++)
        _Celda(
          i,
          i,
          encabezadosRegistro[i].replaceAll('O2', 'O₂'),
          fondo: _doradoEncabezado,
          color: Colors.white,
          negrita: true,
          centrado: true,
          ajustar: true,
          linea: _doradoEncabezado,
        ),
    ]),
  );
  for (final (n, registro) in ordenarCronologicamente(
    datos.registros,
  ).indexed) {
    final celdas = celdasRegistro(registro, vacio: '–');
    final lineas = math.max(_lineas(celdas[8], 8, 8), _lineas(celdas[9], 9, 9));
    filas.add(
      _Fila(
        math.max(28, lineas * _altoLinea + 12),
        clave: Key('filaRegistroExcel_$n'),
        [
          for (var i = 0; i < celdas.length; i++)
            _Celda(
              i,
              i,
              celdas[i],
              fondo: n.isOdd ? _crema : Colors.white,
              color: i == 3 ? _colorEstado(celdas[i]) : _texto,
              negrita: i == 3,
              centrado: i < 8,
              ajustar: true,
              linea: _lineaSuave,
            ),
        ],
      ),
    );
  }
  return filas;
}

Color _colorEstado(String estado) => switch (estado) {
  'Normal' => const Color(0xFF168A63),
  'Alerta' => const Color(0xFFB77900),
  'Crítico' => const Color(0xFFD1103F),
  _ => _texto,
};

class PantallaVistaExcel extends StatelessWidget {
  const PantallaVistaExcel({
    super.key,
    required this.datos,
    this.alCompartir,
    this.alDescargar,
  });

  final DatosHojaExcel datos;
  final VoidCallback? alCompartir;
  final Future<bool> Function()? alDescargar;

  @override
  Widget build(BuildContext context) {
    final filas = _construirFilas(datos);
    final anchos = _medirAnchos(filas, MediaQuery.textScalerOf(context));
    final anchoHoja = _anchoNumeros + anchos.fold<double>(0, (a, b) => a + b);
    double ajuste(Size zona) =>
        (zona.width / anchoHoja).clamp(zoomMinimoHoja, zoomMaximoHoja);

    return MarcoVisor(
      fondo: _fondoRotulos,
      titulo: 'Historial en Excel',
      claveVolver: const Key('cerrarVistaExcel'),
      acciones: [
        if (alDescargar != null)
          IconButton(
            key: const Key('descargarVistaExcel'),
            tooltip: 'Descargar',
            icon: const Icon(Icons.download_rounded),
            onPressed: () => descargarConAviso(context, alDescargar!),
          ),
        if (alCompartir != null)
          IconButton(
            key: const Key('compartirVistaExcel'),
            tooltip: 'Compartir',
            icon: const Icon(Icons.share_rounded),
            onPressed: alCompartir,
          ),
      ],
      cuerpo: VisorConZoom(
        claveVisor: const Key('zoomVistaExcel'),
        sobreOscuro: false,
        zoomMinimo: ajuste,
        zoomMaximo: zoomMaximoHoja,
        escalaInicial: (zona) =>
            zoomInicialHoja.clamp(ajuste(zona), zoomMaximoHoja),
        escalaAjuste: ajuste,
        alineacion: Alignment.topLeft,
        constructor: (_, factor) =>
            _Hoja(filas: filas, anchos: anchos, factor: factor),
      ),
    );
  }
}

TextStyle _estilo(_Celda c, double factor) => GoogleFonts.nunito(
  fontSize: c.tamano * factor,
  fontWeight: c.negrita ? FontWeight.w800 : FontWeight.w500,
  color: c.color,
  height: _altoLinea / c.tamano,
);

bool _enUnaLinea(_Celda c) => c.desde == c.hasta && c.desde < 8;

List<double> _medirAnchos(List<_Fila> filas, TextScaler escala) {
  final anchos = [for (final a in anchosColumnasExcel) a * _pxPorCaracter];
  for (final fila in filas) {
    for (final c in fila.celdas) {
      if (!_enUnaLinea(c)) continue;
      final medida = TextPainter(
        text: TextSpan(text: c.texto, style: _estilo(c, 1)),
        textDirection: TextDirection.ltr,
        textScaler: escala,
        maxLines: 1,
      )..layout();
      final necesario = medida.width * 1.15 + 2 * _margenCelda + 4;
      medida.dispose();
      anchos[c.desde] = math.max(anchos[c.desde], necesario);
    }
  }
  return anchos;
}

const _margenCelda = 7.0;

class _Hoja extends StatelessWidget {
  const _Hoja({
    required this.filas,
    required this.anchos,
    required this.factor,
  });

  final List<_Fila> filas;
  final List<double> anchos;

  final double factor;

  static const _borde = BorderSide(color: _rejilla, width: 0.8);

  static String _letra(int i) => String.fromCharCode(65 + i);

  double _ancho(int desde, int hasta) {
    var total = 0.0;
    for (var i = desde; i <= hasta; i++) {
      total += anchos[i];
    }
    return total * factor;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('hojaExcel'),
      width: _anchoNumeros * factor + _ancho(0, anchos.length - 1),
      color: Colors.white,
      child: Column(
        key: const Key('tablaExcel'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _letras(),
          for (final (n, fila) in filas.indexed) _fila(n + 1, fila),
        ],
      ),
    );
  }

  Widget _rotulo(String texto, double ancho, [double? alto]) => Container(
    width: ancho,
    height: alto,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: _fondoRotulos,
      border: Border(right: _borde, bottom: _borde),
    ),
    child: Text(
      texto,
      maxLines: 1,
      softWrap: false,
      style: GoogleFonts.nunito(
        fontSize: 11 * factor,
        fontWeight: FontWeight.w700,
        color: _textoRotulos,
      ),
    ),
  );

  Widget _letras() => Row(
    children: [
      _rotulo('', _anchoNumeros * factor, _altoLetras * factor),
      for (var i = 0; i < anchos.length; i++)
        _rotulo(_letra(i), _ancho(i, i), _altoLetras * factor),
    ],
  );

  Widget _fila(int numero, _Fila fila) {
    final porInicio = {for (final c in fila.celdas) c.desde: c};
    final partes = <Widget>[_rotulo('$numero', _anchoNumeros * factor)];
    var columna = 0;
    while (columna < anchos.length) {
      final celda = porInicio[columna];
      if (celda == null) {
        partes.add(
          Container(
            width: _ancho(columna, columna),
            constraints: BoxConstraints(minHeight: fila.alto * factor),
            decoration: const BoxDecoration(
              border: Border(right: _borde, bottom: _borde),
            ),
          ),
        );
        columna++;
      } else {
        partes.add(_celda(celda, fila.alto));
        columna = celda.hasta + 1;
      }
    }
    return IntrinsicHeight(
      key: fila.clave,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: partes,
      ),
    );
  }

  Widget _celda(_Celda c, double alto) {
    final unaLinea = _enUnaLinea(c);
    return Container(
      width: _ancho(c.desde, c.hasta),
      constraints: BoxConstraints(minHeight: alto * factor),
      padding: EdgeInsets.symmetric(
        horizontal: _margenCelda * factor,
        vertical: 5 * factor,
      ),
      alignment: c.centrado ? Alignment.center : Alignment.centerLeft,
      decoration: BoxDecoration(
        color: c.fondo,
        border: c.fondo == null
            ? const Border(right: _borde, bottom: _borde)
            : Border(
                bottom: BorderSide(color: c.linea ?? c.fondo!, width: 0.8),
              ),
      ),
      child: Text(
        c.texto,
        maxLines: unaLinea ? 1 : null,
        softWrap: !unaLinea,
        textAlign: c.centrado ? TextAlign.center : TextAlign.left,
        style: _estilo(c, factor),
      ),
    );
  }
}
