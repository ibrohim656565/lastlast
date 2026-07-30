import '../constants/incident_constants.dart';

class QueuedMediaFile {
  const QueuedMediaFile({required this.path, required this.type});

  final String path;
  final MediaType type;

  Map<String, dynamic> toMap() => {'path': path, 'type': type.wireValue};

  factory QueuedMediaFile.fromMap(Map<dynamic, dynamic> map) => QueuedMediaFile(
        path: map['path'] as String,
        type: MediaType.fromWire(map['type'] as String? ?? 'photo'),
      );
}

/// A `POST /api/v1/incidents` payload persisted locally when the device is
/// offline at submission time. Field names deliberately mirror the API
/// contract's create-incident request so building the sync `reports[]`
/// batch later is a straight pass-through.
class QueuedReport {
  const QueuedReport({
    required this.clientUuid,
    required this.type,
    required this.description,
    required this.injuredCount,
    required this.roadBlocked,
    required this.lat,
    required this.lng,
    required this.queuedAt,
    this.provinceId,
    this.districtId,
    this.media = const [],
  });

  final String clientUuid;
  final IncidentType type;
  final String description;
  final int injuredCount;
  final bool roadBlocked;
  final double lat;
  final double lng;
  final int? provinceId;
  final int? districtId;
  final List<QueuedMediaFile> media;
  final DateTime queuedAt;

  Map<String, dynamic> toMap() => {
        'client_uuid': clientUuid,
        'type': type.wireValue,
        'description': description,
        'injured_count': injuredCount,
        'road_blocked': roadBlocked,
        'lat': lat,
        'lng': lng,
        'province_id': provinceId,
        'district_id': districtId,
        'media': media.map((m) => m.toMap()).toList(),
        'queued_at': queuedAt.toIso8601String(),
      };

  factory QueuedReport.fromMap(Map<dynamic, dynamic> map) => QueuedReport(
        clientUuid: map['client_uuid'] as String,
        type: IncidentType.fromWire(map['type'] as String? ?? 'other'),
        description: map['description'] as String? ?? '',
        injuredCount: map['injured_count'] as int? ?? 0,
        roadBlocked: map['road_blocked'] as bool? ?? false,
        lat: (map['lat'] as num).toDouble(),
        lng: (map['lng'] as num).toDouble(),
        provinceId: map['province_id'] as int?,
        districtId: map['district_id'] as int?,
        media: ((map['media'] as List<dynamic>?) ?? [])
            .map((e) => QueuedMediaFile.fromMap(e as Map<dynamic, dynamic>))
            .toList(),
        queuedAt: DateTime.tryParse(map['queued_at'] as String? ?? '') ??
            DateTime.now().toUtc(),
      );
}
