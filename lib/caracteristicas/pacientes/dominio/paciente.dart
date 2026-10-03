class Paciente {
  final String id;
  final String nombreCompleto;
  final String? rut;
  final int? edad;
  final String? diagnostico;
  final String? tratamientoFase;
  final String? centroSaludNombre;
  final String? centroSaludDireccion;
  final String? centroSaludTelefono;
  final String? contactoEmergenciaNombre;
  final String? contactoEmergenciaTelefono;
  final DateTime creadoEn;

  final int maximoRegistrosDia;

  Paciente({
    required this.id,
    required this.nombreCompleto,
    this.rut,
    this.edad,
    this.diagnostico,
    this.tratamientoFase,
    this.centroSaludNombre,
    this.centroSaludDireccion,
    this.centroSaludTelefono,
    this.contactoEmergenciaNombre,
    this.contactoEmergenciaTelefono,
    required this.creadoEn,
    this.maximoRegistrosDia = 3,
  });
}
