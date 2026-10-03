import 'package:oncuidar/nucleo/utilidades/rut.dart';
import 'package:oncuidar/nucleo/utilidades/validacion_correo.dart';

const relacionesCuidador = ['Madre', 'Padre', 'Tutor', 'Otro'];

/// Fases de tratamiento que ofrece el alta.
const fasesTratamiento = [
  'Diagnóstico',
  'Tratamiento',
  'Remisión',
  'Cuidados paliativos',
  'No aplica',
  'Otro',
];

String? validarObligatorio(String? v, String mensaje) =>
    v == null || v.trim().isEmpty ? mensaje : null;

String? validarCorreo(String? v, {bool opcional = false}) {
  final valor = v?.trim() ?? '';
  if (valor.isEmpty) return opcional ? null : 'Ingresa tu correo';
  return regexCorreo.hasMatch(valor) ? null : 'Ingresa un correo válido';
}

String? validarContrasena(String? v) {
  if (v == null || v.isEmpty) return 'Ingresa una contraseña';
  if (v.length < 6) return 'Mínimo 6 caracteres';
  return null;
}

String? validarConfirmacion(String? v, String contrasena) {
  if (v == null || v.isEmpty) return 'Confirma tu contraseña';
  if (v != contrasena) return 'Las contraseñas no coinciden';
  return null;
}

String? validarEdad(String? v) {
  if (v == null || v.trim().isEmpty) return 'Ingresa la edad';
  final edad = int.tryParse(v.trim());
  if (edad == null || edad < 0 || edad > 120) return 'Edad no válida';
  return null;
}

String? validarRutPaciente(String? v) {
  final valor = (v ?? '').trim();
  if (valor.isEmpty) return 'Ingresa el RUT del paciente';
  if (!validarRut(valor)) return 'RUT no válido';
  return null;
}
