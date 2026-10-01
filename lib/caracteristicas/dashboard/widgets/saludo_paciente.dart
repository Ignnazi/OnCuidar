import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/tema/paleta.dart';
import '../../../core/util/formato_fecha.dart';
import '../../../modelos/paciente.dart';
import '../../../modelos/registro_clinico.dart';

class SaludoPaciente extends StatelessWidget {
  const SaludoPaciente({
    super.key,
    required this.nombreCuidador,
    required this.paciente,
    required this.registros,
    this.meta = 3,
  });

  final String nombreCuidador;
  final Paciente paciente;
  final List<RegistroClinico> registros;

  final int meta;

  @override
  Widget build(BuildContext context) {
    final cuantos = registros
        .where((r) => mismoDia(r.fecha, DateTime.now()))
        .length;
    final ultimo = registros.isEmpty ? null : registros.first;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Paleta.doradoBannerClaro, Paleta.doradoBannerOscuro],
        ),
        boxShadow: [
          BoxShadow(
            color: Paleta.doradoOscuro.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hola, $nombreCuidador',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Paleta.textoPrincipal,
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 3.5,
                      margin: const EdgeInsets.only(top: 7),
                      decoration: BoxDecoration(
                        color: Paleta.textoTerciario.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PACIENTE ACTIVO',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Paleta.textoSecundario,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      paciente.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Paleta.textoPrincipal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _progresoRegistrosHoy(context, cuantos),
            ],
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 13),
            color: Paleta.textoTerciario.withValues(alpha: 0.20),
          ),
          Row(
            children: [
              Icon(Icons.schedule, size: 13, color: Paleta.textoTerciario),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _lineaUltimoRegistro(ultimo),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Paleta.textoPrincipal.withValues(alpha: 0.88),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _progresoRegistrosHoy(BuildContext context, int cuantos) {
    final barraCompleta = cuantos >= meta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'REGISTROS DE HOY',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.nunito(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Paleta.textoSecundario,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$cuantos',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Paleta.textoPrincipal,
                    ),
                  ),
                  TextSpan(
                    text: '/$meta',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Paleta.textoSecundario,
                    ),
                  ),
                ],
              ),
            ),
            if (cuantos > meta) ...[
              const SizedBox(width: 5),
              Text(
                '+${cuantos - meta}',
                style: GoogleFonts.nunito(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1FA97C),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 7),
        _barraRegistros(cuantos, barraCompleta),
      ],
    );
  }

  Widget _barraRegistros(int cuantos, bool barraCompleta) {
    return SizedBox(
      width: 64,
      height: 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Paleta.textoTerciario.withValues(alpha: 0.20),
              ),
            ),
            FractionallySizedBox(
              widthFactor: (cuantos / meta).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: barraCompleta
                      ? const Color(0xFF1FA97C)
                      : Paleta.textoTerciario,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _lineaUltimoRegistro(RegistroClinico? ultimo) {
    if (ultimo == null) return 'Sin registros todavía';
    final hace = _hace(ultimo.creadoEn);
    final base = 'Registro más reciente: ${_fechaHora(ultimo.fecha)}';
    return hace == null ? base : '$base · hace $hace';
  }

  String _fechaHora(DateTime momento) {
    final hora = momento.hour.toString().padLeft(2, '0');
    final minuto = momento.minute.toString().padLeft(2, '0');
    return '${fechacorta(momento)}, $hora:$minuto';
  }

  String? _hace(DateTime momento) {
    final dif = DateTime.now().difference(momento);
    if (dif.inMinutes < 1) return null;
    if (dif.inHours < 1) return '${dif.inMinutes} min';
    if (dif.inDays < 1) return '${dif.inHours} h';
    if (dif.inDays < 7) return '${dif.inDays} d';
    return null;
  }
}
