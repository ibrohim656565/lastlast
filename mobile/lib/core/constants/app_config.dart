/// Central place for environment-dependent configuration.
///
/// Override at build/run time with:
///   flutter run --dart-define=API_BASE_URL=https://api.safetj.tj/api/v1
class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.safetj.tj/api/v1',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const int maxMediaPerReport = 5;

  /// Default map radius used when browsing nearby incidents/safe points.
  static const double defaultRadiusKm = 25;
}
