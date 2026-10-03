import 'package:flutter/material.dart';
import 'package:oncuidar/caracteristicas/autenticacion/datos/servicio_alta_cuenta.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/paciente.dart';

class FormularioRegistro {
  // Cuidador
  final nombre = TextEditingController();
  final telefono = TextEditingController();
  final direccion = TextEditingController();
  final correo = TextEditingController();
  final correoRespaldo = TextEditingController();
  final contrasena = TextEditingController();
  final confirmar = TextEditingController();

  // Paciente
  final nombrePaciente = TextEditingController();
  final rut = TextEditingController();
  final edad = TextEditingController();
  final diagnostico = TextEditingController();
  final contactoEmergenciaNombre = TextEditingController();

  final centroNombre = TextEditingController();
  final centroDireccion = TextEditingController();
  final centroTelefono = TextEditingController();
  final urgenciaTelefono = TextEditingController();

  final relacionOtro = TextEditingController();
  final faseOtro = TextEditingController();

  String? relacion;
  String? faseTratamiento;

  late final List<TextEditingController> _todos = [
    nombre,
    telefono,
    direccion,
    correo,
    correoRespaldo,
    contrasena,
    confirmar,
    nombrePaciente,
    rut,
    edad,
    diagnostico,
    contactoEmergenciaNombre,
    centroNombre,
    centroDireccion,
    centroTelefono,
    urgenciaTelefono,
    relacionOtro,
    faseOtro,
  ];

  void dispose() {
    for (final controlador in _todos) {
      controlador.dispose();
    }
  }

  DatosRegistro aDatos() {
    return DatosRegistro(
      nombre: nombre.text.trim(),
      correo: correo.text.trim(),
      telefono: telefono.text.trim(),
      relacion: relacion == 'Otro' ? relacionOtro.text.trim() : relacion,
      correoRespaldo: correoRespaldo.text.trim(),
      direccion: direccion.text.trim(),
      contrasena: contrasena.text,
      paciente: Paciente(
        id: 'auto',
        nombreCompleto: nombrePaciente.text.trim(),
        rut: rut.text.trim(),
        edad: int.tryParse(edad.text.trim()),
        diagnostico: diagnostico.text.trim(),
        tratamientoFase: faseTratamiento == 'Otro'
            ? faseOtro.text.trim()
            : faseTratamiento,
        contactoEmergenciaNombre: contactoEmergenciaNombre.text.trim(),
        centroSaludNombre: centroNombre.text.trim(),
        centroSaludDireccion: centroDireccion.text.trim(),
        centroSaludTelefono: centroTelefono.text.trim(),
        contactoEmergenciaTelefono: urgenciaTelefono.text.trim(),
        creadoEn: DateTime.now(),
      ),
    );
  }
}
