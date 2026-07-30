import '../../../core/constants/incident_constants.dart';

/// Mirrors `{ id, category, name, phone }` from
/// `GET /api/v1/emergency-contacts?category=`.
class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.category,
    required this.name,
    required this.phone,
  });

  final int id;
  final EmergencyContactCategory category;
  final String name;
  final String phone;

  factory EmergencyContact.fromJson(Map<String, dynamic> json) => EmergencyContact(
        id: json['id'] as int,
        category: EmergencyContactCategory.fromWire(json['category'] as String? ?? 'other'),
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
      );

  factory EmergencyContact.fromFallback(int id, FallbackEmergencyContact fallback) =>
      EmergencyContact(
        id: id,
        category: fallback.category,
        name: fallback.name,
        phone: fallback.phone,
      );
}
