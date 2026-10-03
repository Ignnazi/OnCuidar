import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/panel_principal/presentacion/widgets/chip_alerta.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';
import 'package:oncuidar/compartido/config_alerta.dart';

class TarjetaSignosVitales extends StatelessWidget {
  const TarjetaSignosVitales({super.key, required this.registros});

  final List<RegistroClinico> registros;

  @override
  Widget build(BuildContext context) {
    final ultimo = registros.isEmpty ? null : registros.first;
    final estado = configAlerta(ultimo?.nivelAlerta ?? NivelAlerta.normal);

    return Container(
      decoration: BoxDecoration(
        color: Paleta.tarjeta,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Paleta.doradoPrincipal.withValues(alpha: 0.20),
        ),
        boxShadow: [
          BoxShadow(
            color: Paleta.doradoOscuro.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'Signos vitales y síntomas',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Paleta.textoPrincipal,
                    ),
                  ),
                ),
                ChipAlerta(estado: estado),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _gridSignos(ultimo?.signosVitales),
                const SizedBox(height: 12),
                _botonVerRegistros(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _botonVerRegistros(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>
            context.push('/historial', extra: {'filtroFecha': _inicioDeHoy()}),
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Paleta.doradoBannerOscuro, Paleta.doradoMedio],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Paleta.doradoMedio.withValues(alpha: 0.7),
            ),
            boxShadow: [
              BoxShadow(
                color: Paleta.doradoOscuro.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                size: 17,
                color: Paleta.textoPrincipal,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Ver registros del día',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Paleta.textoPrincipal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DateTime _inicioDeHoy() {
    final ahora = DateTime.now();
    return DateTime(ahora.year, ahora.month, ahora.day);
  }

  Widget _gridSignos(SignosVitales? signos) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _celdaSigno(
                  icono: Icons.thermostat,
                  color: const Color(0xFFF07830),
                  etiqueta: 'Temperatura',
                  valor: _temperatura(signos),
                ),
              ),
              _divisorVertical(),
              Expanded(
                child: _celdaSigno(
                  icono: Icons.favorite,
                  color: const Color(0xFFF43F5E),
                  etiqueta: 'Frec. cardíaca',
                  valor: _frecuenciaCardiaca(signos),
                ),
              ),
            ],
          ),
        ),
        _divisorHorizontal(),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _celdaSigno(
                  icono: Icons.show_chart,
                  color: const Color(0xFF4EC4D4),
                  etiqueta: 'Saturación O₂',
                  valor: _saturacion(signos),
                ),
              ),
              _divisorVertical(),
              Expanded(
                child: _celdaSigno(
                  icono: Icons.air,
                  color: const Color(0xFFA78BFA),
                  etiqueta: 'Frec. respiratoria',
                  valor: _respiracion(signos),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _divisorVertical() => Container(
    width: 1,
    color: Paleta.doradoPrincipal.withValues(alpha: 0.10),
  );

  Widget _divisorHorizontal() => Container(
    height: 1,
    color: Paleta.doradoPrincipal.withValues(alpha: 0.10),
  );

  Widget _celdaSigno({
    required IconData icono,
    required Color color,
    required String etiqueta,
    required String valor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icono, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  etiqueta,
                  maxLines: 2,
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
          const SizedBox(height: 8),
          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Paleta.textoPrincipal,
            ),
          ),
        ],
      ),
    );
  }

  String _temperatura(SignosVitales? signos) {
    final valor = signos?.temperatura;
    return valor != null ? '${valor.toStringAsFixed(1)} °C' : '-- °C';
  }

  String _frecuenciaCardiaca(SignosVitales? signos) {
    final valor = signos?.frecuenciaCardiaca;
    return valor != null ? '$valor lpm' : '-- lpm';
  }

  String _saturacion(SignosVitales? signos) {
    final valor = signos?.saturacionOxigeno;
    return valor != null ? '$valor %' : '-- %';
  }

  String _respiracion(SignosVitales? signos) {
    final valor = signos?.frecuenciaRespiratoria;
    return valor != null ? '$valor rpm' : '-- rpm';
  }
}
