import 'package:dio/dio.dart';

import '../constants/app_config.dart';
import '../storage/secure_storage.dart';
import 'auth_interceptor.dart';
import 'error_interceptor.dart';

/// Builds the single [Dio] instance used across the app. Base URL points at
/// `/api/v1` per docs/API_CONTRACT.md.
class DioClient {
  DioClient(SecureStorageService secureStorage) {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: const {'Accept': 'application/json'},
      ),
    );
    dio.interceptors.addAll([
      AuthInterceptor(secureStorage),
      ErrorInterceptor(),
    ]);
  }

  late final Dio dio;
}
