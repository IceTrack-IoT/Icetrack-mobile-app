/// Backend location. The production URL is the default; another backend can be
/// used without touching code:
///   flutter run --dart-define=API_BASE_URL=https://otro-backend.example.com
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://platform-icetrackiot-production.up.railway.app',
  );

  static const String apiPrefix = '/api/v1';

  /// The mobile app always signs in through the MOBILE channel (TECHNICIAN_ROLE).
  static const String channel = 'MOBILE';

  static const Duration timeout = Duration(seconds: 25);

  static Uri uri(String path, [Map<String, String>? query]) {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final uri = Uri.parse('$base$apiPrefix$path');
    return query == null || query.isEmpty ? uri : uri.replace(queryParameters: query);
  }
}
