class Paciente {
  final String id;
  final String fullName;
  final String? rut;
  final int? age;
  final String? diagnosis;
  final String? tratamientoFase;
  final String? centroSaludNombre;
  final String? centroSaludDireccion;
  final String? centroSaludTelefono;
  final String? contactoEmergenciaNombre;
  final String? contactoEmergenciaTelefono;
  final DateTime createdAt;

  Paciente({
    required this.id,
    required this.fullName,
    this.rut,
    this.age,
    this.diagnosis,
    this.tratamientoFase,
    this.centroSaludNombre,
    this.centroSaludDireccion,
    this.centroSaludTelefono,
    this.contactoEmergenciaNombre,
    this.contactoEmergenciaTelefono,
    required this.createdAt,
  });
}