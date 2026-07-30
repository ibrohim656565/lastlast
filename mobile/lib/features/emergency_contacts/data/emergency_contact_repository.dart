import 'package:dio/dio.dart';

import '../../../core/constants/incident_constants.dart';
import '../domain/emergency_contact.dart';

/// `GET /api/v1/emergency-contacts?category=` (public, no auth) per
/// docs/API_CONTRACT.md.
class EmergencyContactRepository {
  EmergencyContactRepository(this._dio);

  final Dio _dio;

  Future<List<EmergencyContact>> fetchContacts({EmergencyContactCategory? category}) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      '/emergency-contacts',
      queryParameters: {if (category != null) 'category': category.wireValue},
    );
    final dynamic body = response.data;
    final List<dynamic> data = body is Map ? (body['data'] as List<dynamic>) : body as List<dynamic>;
    return data
        .map((e) => EmergencyContact.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Real standard emergency numbers used in Tajikistan, returned when the
  /// server is unreachable so the app is still useful mid-disaster.
  List<EmergencyContact> fallbackContacts() {
    return kFallbackEmergencyContacts
        .asMap()
        .entries
        .map((entry) => EmergencyContact.fromFallback(-(entry.key + 1), entry.value))
        .toList();
  }
}
