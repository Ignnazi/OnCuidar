import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/historial/dominio/filtro_historial.dart';
import 'package:oncuidar/caracteristicas/historial/presentacion/controlador_historial.dart';
import 'package:oncuidar/caracteristicas/historial/presentacion/widgets/chip_estado.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';
import 'package:oncuidar/compartido/config_alerta.dart';
import 'package:oncuidar/nucleo/utilidades/formato_fecha.dart';

class FiltrosHistorial extends StatelessWidget {
  const FiltrosHistorial({
    super.key,
    required this.filtro,
    required this.exportable,
    required this.alCambiarEstado,
    required this.alElegirRango,
    required this.alLimpiarRango,
    required this.alExportar,
  });

  final FiltroHistorial filtro;

  final bool exportable;
  final ValueChanged<String?> alCambiarEstado;
  final VoidCallback alElegirRango;
  final VoidCallback alLimpiarRango;
  final ValueChanged<FormatoExportacion> alExportar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChipEstado(
                etiqueta: 'Todos',
                activo: filtro.estado == null,
                onTap: () => alCambiarEstado(null),
              ),
              const SizedBox(width: 8),
              for (final nivel in NivelAlerta.values) ...[
                ChipEstado(
                  etiqueta: configAlerta(nivel).label,
                  activo: filtro.estado == nivel.name,
                  onTap: () => alCambiarEstado(nivel.name),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _botonRango(),
                    if (filtro.hayRango) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Limpiar filtro de fecha',
                        onPressed: alLimpiarRango,
                        style: IconButton.styleFrom(
                          backgroundColor: Paleta.doradoClaro.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: Paleta.textoSecundario,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _BotonExportar(
              formato: FormatoExportacion.pdf,
              icono: Icons.picture_as_pdf,
              colores: const [Paleta.doradoPrincipal, Paleta.doradoOscuro],
              habilitado: exportable,
              alPulsar: alExportar,
            ),
            const SizedBox(width: 8),
            _BotonExportar(
              formato: FormatoExportacion.excel,
              icono: Icons.table_chart,
              colores: const [Color(0xFF217346), Color(0xFF14401F)],
              habilitado: exportable,
              alPulsar: alExportar,
            ),
          ],
        ),
      ],
    );
  }

  Widget _botonRango() {
    return SizedBox(
      height: 40,
      child: OutlinedButton.icon(
        onPressed: alElegirRango,
        icon: const Icon(
          Icons.calendar_month_outlined,
          size: 18,
          color: Paleta.doradoOscuro,
        ),
        label: Text(
          etiquetaRango(filtro, DateTime.now()),
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Paleta.doradoOscuro,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Paleta.doradoOscuro,
          side: const BorderSide(color: Paleta.bordeTarjeta),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

String etiquetaRango(FiltroHistorial filtro, DateTime ahora) {
  final inicio = filtro.inicio;
  final fin = filtro.fin;
  if (inicio != null && fin != null) {
    if (mismoDia(inicio, fin) && mismoDia(inicio, ahora)) return 'Hoy';
    if (mismoDia(inicio, fin)) return fechacorta(inicio);
    return '${fechacorta(inicio)} - ${fechacorta(fin)}';
  }
  if (inicio != null) {
    if (mismoDia(inicio, ahora)) return 'Hoy';
    return 'Inicio · ${fechacorta(inicio)}';
  }
  if (fin != null) return 'Hasta · ${fechacorta(fin)}';
  return 'Filtrar fecha';
}

class _BotonExportar extends StatelessWidget {
  const _BotonExportar({
    required this.formato,
    required this.icono,
    required this.colores,
    required this.habilitado,
    required this.alPulsar,
  });

  final FormatoExportacion formato;
  final IconData icono;
  final List<Color> colores;
  final bool habilitado;
  final ValueChanged<FormatoExportacion> alPulsar;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Exportar ${formato.nombre}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: habilitado ? () => alPulsar(formato) : null,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: habilitado ? LinearGradient(colors: colores) : null,
              color: habilitado ? null : const Color(0xFFEDE3D2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icono,
                  size: 16,
                  color: habilitado ? Colors.white : Paleta.textoSecundario,
                ),
                const SizedBox(width: 6),
                Text(
                  formato.nombre,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: habilitado ? Colors.white : Paleta.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
