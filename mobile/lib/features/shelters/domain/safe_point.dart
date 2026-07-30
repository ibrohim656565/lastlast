import '../../../core/constants/geo_ref.dart';
import '../../../core/constants/incident_constants.dart';

/// Mirrors `SafePoint`: `{ id, type, name, phone, location: {lat,lng},
/// province_id, district_id, address }`.
class SafePoint {
  const SafePoint({
    required this.id,
    required this.type,
    required this.name,
    required this.phone,
    required this.location,
    required this.address,
    this.provinceId,
    this.districtId,
    this.distanceKm,
  });

  final int id;
  final SafePointType type;
  final String name;
  final String phone;
  final GeoPoint location;
  final String address;
  final int? provinceId;
  final int? districtId;

  /// Client-computed, not part of the wire payload — set after fetch when
  /// the user's current GPS position is known, so lists can be re-sorted
  /// without another network round trip.
  final double? distanceKm;

  factory SafePoint.fromJson(Map<String, dynamic> json) => SafePoint(
        id: json['id'] as int,
        type: SafePointType.fromWire(json['type'] as String? ?? 'shelter'),
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        location: GeoPoint.fromJson(
          Map<String, dynamic>.from(json['location'] as Map? ?? const {}),
        ),
        address: json['address'] as String? ?? '',
        provinceId: json['province_id'] as int?,
        districtId: json['district_id'] as int?,
      );

  SafePoint copyWithDistance(double km) => SafePoint(
        id: id,
        type: type,
        name: name,
        phone: phone,
        location: location,
        address: address,
        provinceId: provinceId,
        districtId: districtId,
        distanceKm: km,
      );
}
