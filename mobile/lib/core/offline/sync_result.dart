enum SyncItemStatus {
  created,
  duplicate,
  error;

  static SyncItemStatus fromWire(String value) {
    switch (value) {
      case 'created':
        return SyncItemStatus.created;
      case 'duplicate':
        return SyncItemStatus.duplicate;
      default:
        return SyncItemStatus.error;
    }
  }
}

/// One element of the response array from `POST /api/v1/incidents/sync`:
/// `{ client_uuid, status: "created"|"duplicate"|"error", incident?, error? }`.
class SyncResultItem {
  const SyncResultItem({
    required this.clientUuid,
    required this.status,
    this.incidentJson,
    this.error,
  });

  final String clientUuid;
  final SyncItemStatus status;
  final Map<String, dynamic>? incidentJson;
  final String? error;

  factory SyncResultItem.fromJson(Map<String, dynamic> json) => SyncResultItem(
        clientUuid: json['client_uuid'] as String,
        status: SyncItemStatus.fromWire(json['status'] as String? ?? 'error'),
        incidentJson: json['incident'] != null
            ? Map<String, dynamic>.from(json['incident'] as Map)
            : null,
        error: json['error'] as String?,
      );

  /// Successfully accounted for server-side; safe to drop from the local
  /// queue either way.
  bool get isResolved => status == SyncItemStatus.created || status == SyncItemStatus.duplicate;
}
