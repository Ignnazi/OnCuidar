import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/tema/config_alerta.dart';
import '../../../core/tema/paleta.dart';
import '../../../core/util/formato_fecha.dart';
import '../../../modelos/registro_clinico.dart';

enum _AccionRegistro { editar, eliminar }

class CabeceraRegistro extends StatelessWidget {
  const CabeceraRegistro({
    super.key,
    required this.registro,
    required this.etiqueta,
    required this.onEditar,
    required this.onEliminar,
  });

  final RegistroClinico registro;
  final String etiqueta;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final config = configAlerta(registro.nivelAlerta);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4D0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.calendar_month,
            size: 18,
            color: Color(0xFFE8A820),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fechalarga(registro.fecha),
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Paleta.textoPrincipal,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${hora12(registro.fecha)} · $etiqueta',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Paleta.textoSecundario,
                ),
              ),
            ],
          ),
        ),
        _ChipEstadoRegistro(config: config),
        const SizedBox(width: 2),
        PopupMenuButton<_AccionRegistro>(
          onSelected: (accion) {
            switch (accion) {
              case _AccionRegistro.editar:
                onEditar();
              case _AccionRegistro.eliminar:
                onEliminar();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _AccionRegistro.editar,
              child: ListTile(
                leading:
                    const Icon(Icons.edit_outlined, color: Paleta.doradoOscuro),
                title: Text(
                  'Editar registro',
                  style: TextStyle(
                    color: Paleta.doradoOscuro,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            PopupMenuItem(
              value: _AccionRegistro.eliminar,
              child: ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: Paleta.error),
                title: Text(
                  'Eliminar registro',
                  style: TextStyle(
                    color: Paleta.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
          ],
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Paleta.doradoClaro.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.more_vert_rounded,
              size: 18,
              color: Paleta.doradoOscuro,
            ),
          ),
          color: Paleta.tarjeta,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          tooltip: 'Opciones del registro',
        ),
      ],
    );
  }
}

class _ChipEstadoRegistro extends StatelessWidget {
  const _ChipEstadoRegistro({required this.config});

  final ConfigAlerta config;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: config.fondo,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: config.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            config.label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: config.color,
            ),
          ),
        ],
      ),
    );
  }
}