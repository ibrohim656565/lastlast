/// `{id, name_tg, name_ru, name_en}` from `GET /api/v1/provinces`.
class Province {
  const Province({
    required this.id,
    required this.nameTg,
    required this.nameRu,
    required this.nameEn,
  });

  final int id;
  final String nameTg;
  final String nameRu;
  final String nameEn;

  factory Province.fromJson(Map<String, dynamic> json) => Province(
        id: json['id'] as int,
        nameTg: json['name_tg'] as String? ?? '',
        nameRu: json['name_ru'] as String? ?? '',
        nameEn: json['name_en'] as String? ?? '',
      );
}

/// `{id, province_id, name_tg, name_ru, name_en}` from
/// `GET /api/v1/districts?province_id=`.
class District {
  const District({
    required this.id,
    required this.provinceId,
    required this.nameTg,
    required this.nameRu,
    required this.nameEn,
  });

  final int id;
  final int provinceId;
  final String nameTg;
  final String nameRu;
  final String nameEn;

  factory District.fromJson(Map<String, dynamic> json) => District(
        id: json['id'] as int,
        provinceId: json['province_id'] as int,
        nameTg: json['name_tg'] as String? ?? '',
        nameRu: json['name_ru'] as String? ?? '',
        nameEn: json['name_en'] as String? ?? '',
      );
}

/// Minimal `{id, name_en}` reference embedded inside `Incident.province`
/// and `Incident.district` per the API contract's incident sample payload.
class GeoRefSummary {
  const GeoRefSummary({required this.id, required this.nameEn});

  final int id;
  final String nameEn;

  factory GeoRefSummary.fromJson(Map<String, dynamic> json) => GeoRefSummary(
        id: json['id'] as int,
        nameEn: json['name_en'] as String? ?? '',
      );
}

/// `{lat, lng}` embedded location object used by Incident and SafePoint.
class GeoPoint {
  const GeoPoint({required this.lat, required this.lng});

  final double lat;
  final double lng;

  factory GeoPoint.fromJson(Map<String, dynamic> json) => GeoPoint(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};
}
