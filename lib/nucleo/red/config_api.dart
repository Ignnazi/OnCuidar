class ConfigApi {
  const ConfigApi._();

  static const urlBase = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:8080/api',
  );
}
