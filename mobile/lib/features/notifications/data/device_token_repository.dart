import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// `POST /api/v1/device-tokens` per docs/API_CONTRACT.md. Registers/updates
/// the FCM token for the signed-in user; the backend best-effort subscribes
/// it to province/district topics from optional location hints.
class DeviceTokenRepository {
  DeviceTokenRepository(this._dio);

  final Dio _dio;

  Future<void> registerToken(
    String token, {
    int? provinceId,
    int? districtId,
  }) async {
    await _dio.post<dynamic>(
      '/device-tokens',
      data: {
        'token': token,
        'platform': _platform(),
        if (provinceId != null) 'province_id': provinceId,
        if (districtId != null) 'district_id': districtId,
      },
    );
  }

  String _platform() {
    if (kIsWeb) return 'android';
    return Platform.isIOS ? 'ios' : 'android';
  }
}
