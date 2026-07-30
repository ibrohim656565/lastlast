import 'package:dio/dio.dart';

import '../storage/secure_storage.dart';

/// Attaches `Authorization: Bearer <token>` to every request when a Sanctum
/// token is present, and clears it on a 401 so the app can route back to
/// the auth flow (handled by whoever reads [DioException] downstream).
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._secureStorage);

  final SecureStorageService _secureStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final String? token = await _secureStorage.readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      await _secureStorage.clearToken();
    }
    handler.next(err);
  }
}
