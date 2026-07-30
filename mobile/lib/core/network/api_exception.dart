/// Normalized error shape surfaced to the UI, built from the Laravel default
/// resource/validation envelope: `{ data, message, errors }`.
class ApiException implements Exception {
  ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  factory ApiException.network() => ApiException(
        message: 'network_error',
      );

  factory ApiException.timeout() => ApiException(
        message: 'timeout_error',
      );

  factory ApiException.unauthorized() => ApiException(
        message: 'unauthorized',
        statusCode: 401,
      );

  @override
  String toString() => 'ApiException($statusCode, $message, $errors)';
}
