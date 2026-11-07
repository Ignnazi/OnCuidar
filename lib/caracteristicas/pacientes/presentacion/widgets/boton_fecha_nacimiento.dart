import 'package:flutter/material.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/fecha_nacimiento.dart';

class BotonFechaNacimiento extends StatelessWidget {
  const BotonFechaNacimiento({super.key, required this.controlador});

  final TextEditingController controlador;

  Future<void> _elegir(BuildContext context) async {
    final hoy = DateTime.now();
    final actual = leerFechaNacimiento(controlador.text);
    final elegida = await showDatePicker(
      context: context,
      initialDate: actual ?? DateTime(hoy.year - 5, hoy.month, hoy.day),
      firstDate: DateTime(hoy.year - 120),
      lastDate: hoy,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText: 'Fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Listo',
    );
    if (elegida != null) controlador.text = formatearFechaNacimiento(elegida);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('botonCalendarioNacimiento'),
      tooltip: 'Elegir en el calendario',
      onPressed: () => _elegir(context),
      color: Paleta.doradoOscuro,
      icon: const Icon(Icons.calendar_month_rounded),
    );
  }
}
