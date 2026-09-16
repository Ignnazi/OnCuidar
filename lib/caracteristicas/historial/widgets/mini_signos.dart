import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../modelos/registro_clinico.dart';

class MiniSignos extends StatelessWidget {
  const MiniSignos({super.key, required this.signos});

  final SignosVitales? signos;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[];
    if (signos?.temperature != null) {
      tiles.add(
        _MiniTile(
          Icons.thermostat,
          const Color(0xFFF07830),
          '${signos!.temperature!.toStringAsFixed(1)}°C',
        ),
      );
    }
    if (signos?.heartRate != null) {
      tiles.add(
        _MiniTile(
          Icons.favorite,
          const Color(0xFFF43F5E),
          '${signos!.heartRate} lpm',
        ),
      );
    }
    if (signos?.oxygenSaturation != null) {
      tiles.add(
        _MiniTile(
          Icons.air,
          const Color(0xFF4EC4D4),
          '${signos!.oxygenSaturation}%',
        ),
      );
    }
    if (signos?.respiratoryRate != null) {
      tiles.add(
        _MiniTile(
          Icons.monitor_heart_outlined,
          const Color(0xFFA78BFA),
          '${signos!.respiratoryRate} rpm',
        ),
      );
    }
    if (tiles.isEmpty) return const SizedBox.shrink();

    final filas = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      filas.add(
        Row(
          children: [
            Expanded(child: tiles[i]),
            if (i + 1 < tiles.length) ...[
              const SizedBox(width: 8),
              Expanded(child: tiles[i + 1]),
            ],
          ],
        ),
      );
      if (i + 2 < tiles.length) filas.add(const SizedBox(height: 8));
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Column(children: filas),
    );
  }
}

class _MiniTile extends StatelessWidget {
  const _MiniTile(this.icono, this.color, this.valor);

  final IconData icono;
  final Color color;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icono, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              valor,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}