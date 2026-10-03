import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/chat/dominio/conversacion.dart';

const List<String> _mesesEs = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

String fechaRelativaConversacion(DateTime fecha, DateTime ahora) {
  final hoy = DateTime(ahora.year, ahora.month, ahora.day);
  final dia = DateTime(fecha.year, fecha.month, fecha.day);
  final diferencia = hoy.difference(dia).inDays;
  if (diferencia == 0) return 'hoy';
  if (diferencia == 1) return 'ayer';
  return '${fecha.day} ${_mesesEs[fecha.month - 1]}';
}

class TarjetaConversacion extends StatelessWidget {
  const TarjetaConversacion({
    super.key,
    required this.conversacion,
    required this.alEntrar,
    required this.alRenombrar,
    required this.alEliminar,
  });

  final Conversacion conversacion;
  final VoidCallback alEntrar;
  final VoidCallback alRenombrar;
  final VoidCallback alEliminar;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Paleta.tarjeta,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Paleta.doradoPrincipal.withValues(alpha: 0.20),
        ),
        boxShadow: [
          BoxShadow(
            color: Paleta.doradoPrincipal.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('conversacion_${conversacion.id}'),
          onTap: alEntrar,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(
                  Icons.folder_rounded,
                  color: Paleta.doradoOscuro,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversacion.titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Paleta.textoPrincipal,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${fechaRelativaConversacion(conversacion.ultimaActividad, DateTime.now())}'
                        ' · ${conversacion.mensajes.length} mensajes',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: Paleta.textoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  key: Key('menuConversacion_${conversacion.id}'),
                  icon: const Icon(
                    Icons.more_vert,
                    color: Paleta.textoSecundario,
                    size: 20,
                  ),
                  onSelected: (valor) {
                    switch (valor) {
                      case 'renombrar':
                        alRenombrar();
                      case 'eliminar':
                        alEliminar();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'renombrar',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Renombrar'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'eliminar',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Eliminar'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
