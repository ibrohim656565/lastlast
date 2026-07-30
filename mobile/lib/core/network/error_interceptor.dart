import 'package:dio/dio.dart';

import 'api_exception.dart';

/// Converts raw [DioException]s into [ApiException]s using the Laravel
/// default resource/validation envelope `{ data, message, errors }`, so
/// every feature repository deals with one normalized error type.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: _mapToApiException(err),
    ));
  }

  ApiException _mapToApiException(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException.timeout();
      case DioExceptionType.connectionError:
        return ApiException.network();
      case DioExceptionType.badResponse:
        return _fromResponse(err);
      case DioExceptionType.cancel:
        return ApiException(message: 'request_cancelled');
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return ApiException(message: err.message ?? 'unknown_error');
    }
  }

  ApiException _fromResponse(DioException err) {
    final int? statusCode = err.response?.statusCode;
    final dynamic data = err.response?.data;

    if (statusCode == 401) {
      return ApiException.unauthorized();
    }

    if (data is Map<String, dynamic>) {
      final String message = (data['message'] as String?) ?? 'server_error';
      final Map<String, dynamic>? errors = data['errors'] is Map
          ? Map<String, dynamic>.from(data['errors'] as Map)
          : null;
      return ApiException(message: message, statusCode: statusCode, errors: errors);
    }

    return ApiException(message: 'server_error', statusCode: statusCode);
  }
}
