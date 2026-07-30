import 'package:dio/dio.dart';

import '../../../core/constants/incident_constants.dart';
import '../domain/safe_point.dart';

/// `GET /api/v1/safe-points` per docs/API_CONTRACT.md.
class SafePointRepository {
  SafePointRepository(this._dio);

  final Dio _dio;

  Future<List<SafePoint>> fetchSafePoints({
    SafePointType? type,
    double? lat,
    double? lng,
    double? radiusKm,
  }) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      '/safe-points',
      queryParameters: {
        if (type != null) 'type': type.wireValue,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (radiusKm != null) 'radius_km': radiusKm,
      },
    );
    final dynamic body = response.data;
    final List<dynamic> data = body is Map ? (body['data'] as List<dynamic>) : body as List<dynamic>;
    return data
        .map((e) => SafePoint.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
