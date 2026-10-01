import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/tema/config_alerta.dart';

class ChipAlerta extends StatelessWidget {
  const ChipAlerta({super.key, required this.estado});

  final ConfigAlerta estado;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: estado.color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: estado.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              estado.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: estado.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
