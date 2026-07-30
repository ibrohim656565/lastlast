/// In-app representation of an FCM push, built from the payload shape in
/// docs/API_CONTRACT.md: `{ title, body, data: { type, incident_id } }`.
class AppNotification {
  const AppNotification({
    required this.title,
    required this.body,
    required this.receivedAt,
    this.type,
    this.incidentId,
  });

  final String title;
  final String body;
  final DateTime receivedAt;
  final String? type;
  final String? incidentId;

  factory AppNotification.fromRemoteMessageData({
    required String? title,
    required String? body,
    required Map<String, dynamic> data,
  }) =>
      AppNotification(
        title: title ?? '',
        body: body ?? '',
        receivedAt: DateTime.now().toUtc(),
        type: data['type'] as String?,
        incidentId: data['incident_id'] as String?,
      );
}
