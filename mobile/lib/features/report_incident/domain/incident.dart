import '../../../core/constants/geo_ref.dart';
import '../../../core/constants/incident_constants.dart';

class IncidentMedia {
  const IncidentMedia({
    required this.id,
    required this.type,
    required this.url,
    required this.thumbnailUrl,
  });

  final int id;
  final MediaType type;
  final String url;
  final String? thumbnailUrl;

  factory IncidentMedia.fromJson(Map<String, dynamic> json) => IncidentMedia(
        id: json['id'] as int,
        type: MediaType.fromWire(json['type'] as String? ?? 'photo'),
        url: json['url'] as String? ?? '',
        thumbnailUrl: json['thumbnail_url'] as String?,
      );
}

class IncidentReporter {
  const IncidentReporter({
    required this.id,
    required this.name,
    required this.phoneMasked,
  });

  final int id;
  final String name;
  final String phoneMasked;

  factory IncidentReporter.fromJson(Map<String, dynamic> json) => IncidentReporter(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        phoneMasked: json['phone_masked'] as String? ?? '',
      );
}

/// Mirrors the `Incident` shape in docs/API_CONTRACT.md exactly.
class Incident {
  const Incident({
    required this.id,
    required this.clientUuid,
    required this.type,
    required this.status,
    required this.description,
    required this.injuredCount,
    required this.roadBlocked,
    required this.location,
    required this.createdAt,
    this.province,
    this.district,
    this.media = const [],
    this.reporter,
    this.verifiedAt,
    this.dispatchedAt,
    this.resolvedAt,
  });

  final int id;
  final String clientUuid;
  final IncidentType type;
  final IncidentStatus status;
  final String description;
  final int injuredCount;
  final bool roadBlocked;
  final GeoPoint location;
  final GeoRefSummary? province;
  final GeoRefSummary? district;
  final List<IncidentMedia> media;
  final IncidentReporter? reporter;
  final DateTime createdAt;
  final DateTime? verifiedAt;
  final DateTime? dispatchedAt;
  final DateTime? resolvedAt;

  factory Incident.fromJson(Map<String, dynamic> json) => Incident(
        id: json['id'] as int,
        clientUuid: json['client_uuid'] as String? ?? '',
        type: IncidentType.fromWire(json['type'] as String? ?? 'other'),
        status: IncidentStatus.fromWire(json['status'] as String? ?? 'new'),
        description: json['description'] as String? ?? '',
        injuredCount: json['injured_count'] as int? ?? 0,
        roadBlocked: json['road_blocked'] as bool? ?? false,
        location: GeoPoint.fromJson(
          Map<String, dynamic>.from(json['location'] as Map? ?? const {}),
        ),
        province: json['province'] != null
            ? GeoRefSummary.fromJson(Map<String, dynamic>.from(json['province'] as Map))
            : null,
        district: json['district'] != null
            ? GeoRefSummary.fromJson(Map<String, dynamic>.from(json['district'] as Map))
            : null,
        media: (json['media'] as List<dynamic>? ?? [])
            .map((e) => IncidentMedia.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        reporter: json['reporter'] != null
            ? IncidentReporter.fromJson(Map<String, dynamic>.from(json['reporter'] as Map))
            : null,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now().toUtc(),
        verifiedAt: json['verified_at'] != null
            ? DateTime.tryParse(json['verified_at'] as String)
            : null,
        dispatchedAt: json['dispatched_at'] != null
            ? DateTime.tryParse(json['dispatched_at'] as String)
            : null,
        resolvedAt: json['resolved_at'] != null
            ? DateTime.tryParse(json['resolved_at'] as String)
            : null,
      );
}
