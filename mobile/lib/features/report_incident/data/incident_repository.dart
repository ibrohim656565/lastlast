import 'package:dio/dio.dart';

import '../../../core/constants/incident_constants.dart';
import '../../../core/offline/incident_sync_client.dart';
import '../../../core/offline/queued_report.dart';
import '../../../core/offline/sync_result.dart';
import '../domain/incident.dart';

/// `/api/v1/incidents*` per docs/API_CONTRACT.md. Implements
/// [IncidentSyncClient] so [OfflineSyncService] can flush the local queue
/// without depending on this feature directly.
class IncidentRepository implements IncidentSyncClient {
  IncidentRepository(this._dio);

  final Dio _dio;

  Future<List<Incident>> fetchIncidents({
    IncidentType? type,
    IncidentStatus? status,
    int? provinceId,
    int? districtId,
    double? lat,
    double? lng,
    double? radiusKm,
    DateTime? from,
    DateTime? to,
    int page = 1,
  }) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      '/incidents',
      queryParameters: {
        if (type != null) 'type': type.wireValue,
        if (status != null) 'status': status.wireValue,
        if (provinceId != null) 'province_id': provinceId,
        if (districtId != null) 'district_id': districtId,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (radiusKm != null) 'radius_km': radiusKm,
        if (from != null) 'from': from.toIso8601String(),
        if (to != null) 'to': to.toIso8601String(),
        'page': page,
      },
    );
    final List<dynamic> data = (response.data as Map)['data'] as List<dynamic>;
    return data
        .map((e) => Incident.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Incident> fetchIncident(int id) async {
    final Response<dynamic> response = await _dio.get<dynamic>('/incidents/$id');
    return Incident.fromJson(
      Map<String, dynamic>.from((response.data as Map)['data'] as Map),
    );
  }

  /// Submits a single report while online. Returns 201 for a new incident or
  /// 200 when `client_uuid` already existed for this user (contract
  /// guarantees idempotency either way).
  Future<Incident> createIncident({
    required String clientUuid,
    required IncidentType type,
    required String description,
    required int injuredCount,
    required bool roadBlocked,
    required double lat,
    required double lng,
    int? provinceId,
    int? districtId,
    List<QueuedMediaFile> media = const [],
  }) async {
    final FormData formData = FormData.fromMap({
      'client_uuid': clientUuid,
      'type': type.wireValue,
      'description': description,
      'injured_count': injuredCount,
      'road_blocked': roadBlocked,
      'lat': lat,
      'lng': lng,
      if (provinceId != null) 'province_id': provinceId,
      if (districtId != null) 'district_id': districtId,
    });
    for (final QueuedMediaFile file in media) {
      formData.files.add(MapEntry(
        'media[]',
        await MultipartFile.fromFile(file.path, filename: _basename(file.path)),
      ));
    }

    final Response<dynamic> response = await _dio.post<dynamic>('/incidents', data: formData);
    return Incident.fromJson(
      Map<String, dynamic>.from((response.data as Map)['data'] as Map),
    );
  }

  /// `POST /api/v1/incidents/sync` — batched flush of the offline queue.
  /// Each report keeps its own `client_uuid` and `media[]` so the server can
  /// report per-item created/duplicate/error status.
  @override
  Future<List<SyncResultItem>> syncReports(List<QueuedReport> reports) async {
    final FormData formData = FormData();
    for (int i = 0; i < reports.length; i++) {
      final QueuedReport report = reports[i];
      formData.fields.addAll([
        MapEntry('reports[$i][client_uuid]', report.clientUuid),
        MapEntry('reports[$i][type]', report.type.wireValue),
        MapEntry('reports[$i][description]', report.description),
        MapEntry('reports[$i][injured_count]', report.injuredCount.toString()),
        MapEntry('reports[$i][road_blocked]', report.roadBlocked.toString()),
        MapEntry('reports[$i][lat]', report.lat.toString()),
        MapEntry('reports[$i][lng]', report.lng.toString()),
        if (report.provinceId != null)
          MapEntry('reports[$i][province_id]', report.provinceId.toString()),
        if (report.districtId != null)
          MapEntry('reports[$i][district_id]', report.districtId.toString()),
      ]);
      for (final QueuedMediaFile file in report.media) {
        formData.files.add(MapEntry(
          'reports[$i][media][]',
          await MultipartFile.fromFile(file.path, filename: _basename(file.path)),
        ));
      }
    }

    final Response<dynamic> response =
        await _dio.post<dynamic>('/incidents/sync', data: formData);
    final List<dynamic> data = (response.data as Map)['data'] as List<dynamic>;
    return data
        .map((e) => SyncResultItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  String _basename(String path) => path.split(RegExp(r'[\\/]')).last;
}
