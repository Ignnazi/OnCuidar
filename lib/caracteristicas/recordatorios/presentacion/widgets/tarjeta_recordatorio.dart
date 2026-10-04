import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/recordatorios/dominio/recordatorio.dart';
import 'package:oncuidar/caracteristicas/recordatorios/presentacion/formato_recordatorio.dart';
import 'package:oncuidar/nucleo/utilidades/formato_fecha.dart';

enum _AccionRecordatorio { editar, eliminar }

class TarjetaRecordatorio extends StatelessWidget {
  const TarjetaRecordatorio({
    super.key,
    required this.recordatorio,
    required this.nombrePaciente,
    required this.silenciadas,
    required this.alAlternarActivo,
    required this.alEditar,
    required this.alEliminar,
  });

  final Recordatorio recordatorio;
  final String nombrePaciente;
  final bool silenciadas;
  final VoidCallback alAlternarActivo;
  final VoidCallback alEditar;
  final VoidCallback alEliminar;

  @override
  Widget build(BuildContext context) {
    final r = recordatorio;
    final (:icono, :color) = estiloTipoRecordatorio(r.tipo);
    final dias = r.diasRepeticion.map(diaCorto).toList();
    return Opacity(
      opacity: silenciadas ? 0.55 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Paleta.tarjeta,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Paleta.doradoPrincipal.withValues(alpha: 0.20),
          ),
          boxShadow: [
            BoxShadow(
              color: Paleta.doradoOscuro.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: r.activo ? Paleta.doradoClaro : Paleta.deshabilitado,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icono,
                color: r.activo ? color : Paleta.textoDeshabilitado,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.titulo,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: r.activo
                          ? Paleta.textoPrincipal
                          : Paleta.textoSecundario,
                    ),
                  ),
                  if (r.descripcion != null && r.descripcion!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      r.descripcion!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Paleta.textoSecundario,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (nombrePaciente.isNotEmpty) ...[
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Paleta.doradoClaro,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              nombrePaciente,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Paleta.textoSecundario,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Paleta.textoSecundario,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          r.esRecurrente
                              ? hora12(r.fechaHora)
                              : '${fechacorta(r.fechaHora)} · ${hora12(r.fechaHora)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Paleta.textoSecundario,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (r.esMensual) ...[
                    const SizedBox(height: 6),
                    _ChipDia('Cada mes el día ${r.fechaHora.day}', r.activo),
                  ],
                  if (dias.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    if (dias.length == 7) ...[
                      _ChipDia('Toda la semana', r.activo),
                    ] else ...[
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final dia in dias)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: _ChipDia(dia, r.activo),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            _Interruptor(
              key: Key('switchActivo_${r.id}'),
              activo: r.activo,
              alTocar: alAlternarActivo,
            ),
            const SizedBox(width: 6),
            _menu(r),
          ],
        ),
      ),
    );
  }

  Widget _menu(Recordatorio r) {
    return PopupMenuButton<_AccionRecordatorio>(
      key: Key('menuRecordatorio_${r.id}'),
      tooltip: 'Opciones del recordatorio',
      onSelected: (accion) {
        switch (accion) {
          case _AccionRecordatorio.editar:
            alEditar();
          case _AccionRecordatorio.eliminar:
            alEliminar();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _AccionRecordatorio.editar,
          child: ListTile(
            key: Key('accionEditar_${r.id}'),
            leading: Icon(Icons.edit_outlined, color: Paleta.doradoOscuro),
            title: Text(
              'Editar',
              style: GoogleFonts.nunito(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Paleta.doradoOscuro,
              ),
            ),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _AccionRecordatorio.eliminar,
          child: ListTile(
            key: Key('accionEliminar_${r.id}'),
            leading: Icon(Icons.delete_outline, color: Paleta.error),
            title: Text(
              'Eliminar',
              style: GoogleFonts.nunito(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Paleta.error,
              ),
            ),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
      ],
      color: Paleta.tarjeta,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Paleta.doradoClaro.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.more_vert_rounded,
          size: 18,
          color: Paleta.doradoOscuro,
        ),
      ),
    );
  }
}

class _ChipDia extends StatelessWidget {
  const _ChipDia(this.texto, this.activo);

  final String texto;
  final bool activo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: activo ? Paleta.doradoClaro : Paleta.deshabilitado,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: activo ? Paleta.doradoOscuro : Paleta.textoSecundario,
        ),
      ),
    );
  }
}

class _Interruptor extends StatelessWidget {
  const _Interruptor({super.key, required this.activo, required this.alTocar});

  final bool activo;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: alTocar,
      child: Container(
        width: 48,
        height: 26,
        decoration: BoxDecoration(
          color: activo ? Paleta.doradoPrincipal : Paleta.bordeDeshabilitado,
          borderRadius: BorderRadius.circular(13),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: activo ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
            ),
          ),
        ),
      ),
    );
  }
}
