/// Rutas REST de la API, relativas a la URL base.
class RutasApi {
  const RutasApi._();

  static const cuidador = '/cuidador';
  static const pacientes = '/pacientes';
  static const conversaciones = '/conversaciones';
  static const biblioteca = '/biblioteca';
  static const favoritos = '/favoritos';

  static String paciente(String id) => '/pacientes/$id';
  static String registros(String pid) => '/pacientes/$pid/registros';
  static String registro(String pid, String rid) =>
      '/pacientes/$pid/registros/$rid';
  static String recordatorios(String pid) => '/pacientes/$pid/recordatorios';
  static String recordatorio(String pid, String rid) =>
      '/pacientes/$pid/recordatorios/$rid';
  static String conversacion(String id) => '/conversaciones/$id';
  static String favorito(String id) => '/favoritos/$id';
  static String materialBiblioteca(String id) => '/biblioteca/$id';
}
