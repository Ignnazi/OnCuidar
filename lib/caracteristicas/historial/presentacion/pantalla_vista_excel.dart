import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/caracteristicas/historial/datos/exportador_excel.dart';
import 'package:oncuidar/caracteristicas/historial/datos/formato_exportacion.dart';
import 'package:oncuidar/caracteristicas/historial/dominio/orden_registros.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/paciente.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';
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
}) {
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          PantallaVistaExcel(datos: datos, alCompartir: alCompartir),
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
const _linea = Color(0xFFE8DCC0);

const _pxPorCaracter = 7.2;

class PantallaVistaExcel extends StatelessWidget {
  const PantallaVistaExcel({super.key, required this.datos, this.alCompartir});

  final DatosHojaExcel datos;
  final VoidCallback? alCompartir;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EEE3),
      appBar: AppBar(
        leading: IconButton(
          key: const Key('cerrarVistaExcel'),
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Historial en Excel',
          style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (alCompartir != null)
            IconButton(
              key: const Key('compartirVistaExcel'),
              tooltip: 'Compartir',
              icon: const Icon(Icons.share_rounded),
              onPressed: alCompartir,
            ),
        ],
      ),
      body: InteractiveViewer(
        key: const Key('zoomVistaExcel'),
        constrained: false,
        minScale: 0.4,
        maxScale: 3,
        boundaryMargin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _Hoja(datos: datos),
        ),
      ),
    );
  }
}

class _Hoja extends StatelessWidget {
  const _Hoja({required this.datos});

  final DatosHojaExcel datos;

  static double _ancho(int desde, int hasta) {
    var total = 0.0;
    for (var i = desde; i <= hasta; i++) {
      total += anchosColumnasExcel[i] * _pxPorCaracter;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final anchoIzquierda = _ancho(0, 4);
    final izquierda = bloquesPacienteYCuidador(
      datos.paciente,
      datos.nombreCuidador,
    );
    final derecha = bloquesCentroYContacto(datos.paciente);
    final nombre = datos.paciente?.nombreCompleto.trim();

    return Container(
      key: const Key('hojaExcel'),
      width: _ancho(0, 9),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _linea),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 34,
            color: _dorado,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            child: Text(
              'HISTORIAL ONCUIDAR',
              style: GoogleFonts.nunito(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
            child: Text(
              [
                if (nombre != null && nombre.isNotEmpty) 'Paciente: $nombre',
                'Generado: ${fechacorta(datos.generadoEn)} '
                    '${hora12(datos.generadoEn)}',
              ].join('   ·   '),
              style: GoogleFonts.nunito(fontSize: 12, color: _textoSuave),
            ),
          ),
          for (
            var i = 0;
            i <
                (izquierda.length > derecha.length
                    ? izquierda.length
                    : derecha.length);
            i++
          )
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: anchoIzquierda,
                    child: i < izquierda.length
                        ? _Bloque(
                            bloque: izquierda[i],
                            anchoEtiqueta:
                                anchosColumnasExcel[0] * _pxPorCaracter,
                          )
                        : null,
                  ),
                  Expanded(
                    child: i < derecha.length
                        ? _Bloque(
                            bloque: derecha[i],
                            anchoEtiqueta:
                                anchosColumnasExcel[5] * _pxPorCaracter,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          _Bloque(
            bloque: (
              titulo: 'RESUMEN',
              filas: <FilaInfo>[
                (
                  rotuloPeriodo(datos.fechaInicio, datos.fechaFin),
                  etiquetaPeriodo(datos.fechaInicio, datos.fechaFin),
                ),
                ('Registros', '${datos.registros.length}'),
              ],
            ),
            anchoEtiqueta: anchosColumnasExcel[0] * _pxPorCaracter,
          ),
          const SizedBox(height: 12),
          _Tabla(registros: datos.registros),
        ],
      ),
    );
  }
}

class _Bloque extends StatelessWidget {
  const _Bloque({required this.bloque, required this.anchoEtiqueta});

  final BloqueInfo bloque;
  final double anchoEtiqueta;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: _doradoClaro,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Text(
            bloque.titulo,
            style: GoogleFonts.nunito(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: _doradoTexto,
            ),
          ),
        ),
        for (final (etiqueta, valor) in bloque.filas)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: anchoEtiqueta,
                  child: Text(
                    etiqueta,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _doradoTexto,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    valor,
                    style: GoogleFonts.nunito(fontSize: 12, color: _texto),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Tabla extends StatelessWidget {
  const _Tabla({required this.registros});

  final List<RegistroClinico> registros;

  static Color _colorEstado(String estado) => switch (estado) {
    'Normal' => const Color(0xFF168A63),
    'Alerta' => const Color(0xFFB77900),
    'Crítico' => const Color(0xFFD1103F),
    _ => _texto,
  };

  @override
  Widget build(BuildContext context) {
    final datos = [
      for (final r in ordenarCronologicamente(registros))
        celdasRegistro(r, vacio: '–'),
    ];

    Widget celda(
      String texto, {
      required int columna,
      Color? color,
      bool negrita = false,
      bool encabezado = false,
    }) {
      final esTexto = columna >= 8;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        alignment: esTexto && !encabezado
            ? Alignment.centerLeft
            : Alignment.center,
        child: Text(
          texto,
          textAlign: esTexto && !encabezado ? TextAlign.left : TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: negrita || encabezado
                ? FontWeight.w800
                : FontWeight.w500,
            color: encabezado ? Colors.white : (color ?? _texto),
          ),
        ),
      );
    }

    return Table(
      key: const Key('tablaExcel'),
      columnWidths: {
        for (var i = 0; i < anchosColumnasExcel.length; i++)
          i: FixedColumnWidth(anchosColumnasExcel[i] * _pxPorCaracter),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: const TableBorder(
        horizontalInside: BorderSide(color: _linea, width: 0.6),
        bottom: BorderSide(color: _linea, width: 0.6),
      ),
      children: [
        TableRow(
          decoration: const BoxDecoration(color: _doradoEncabezado),
          children: [
            for (var i = 0; i < encabezadosRegistro.length; i++)
              celda(
                encabezadosRegistro[i].replaceAll('O2', 'O₂'),
                columna: i,
                encabezado: true,
              ),
          ],
        ),
        for (final (n, fila) in datos.indexed)
          TableRow(
            decoration: BoxDecoration(color: n.isOdd ? _crema : Colors.white),
            children: [
              for (var i = 0; i < fila.length; i++)
                celda(
                  fila[i],
                  columna: i,
                  negrita: i == 3,
                  color: i == 3 ? _colorEstado(fila[i]) : null,
                ),
            ],
          ),
      ],
    );
  }
}
