import 'package:flutter/material.dart';

import 'tarjeta_signo.dart';
import 'titulo_seccion.dart';

class SeccionSignosVitales extends StatelessWidget {
  const SeccionSignosVitales({
    super.key,
    required this.controladores,
  });

  final List<TextEditingController> controladores;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TituloSeccion('Signos vitales', icono: Icons.monitor_heart_rounded),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TarjetaSigno(
                etiqueta: 'Temperatura',
                icono: Icons.thermostat,
                color: const Color(0xFFF07830),
                hint: '37.0',
                unidad: '°C',
                rango: '30-45',
                controlador: controladores[0],
                decimal: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TarjetaSigno(
                etiqueta: 'Frec. cardíaca',
                icono: Icons.favorite,
                color: const Color(0xFFF43F5E),
                hint: '80',
                unidad: 'lpm',
                rango: '20-250',
                controlador: controladores[1],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TarjetaSigno(
                etiqueta: 'Saturación O₂',
                icono: Icons.show_chart,
                color: const Color(0xFF4EC4D4),
                hint: '98',
                unidad: '%',
                rango: '50-100',
                controlador: controladores[2],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TarjetaSigno(
                etiqueta: 'Frec. respiratoria',
                icono: Icons.air,
                color: const Color(0xFFA78BFA),
                hint: '18',
                unidad: 'rpm',
                rango: '4-60',
                controlador: controladores[3],
              ),
            ),
          ],
        ),
      ],
    );
  }
}