import 'package:flutter_test/flutter_test.dart';
import 'package:safetj/core/constants/incident_constants.dart';
import 'package:safetj/core/offline/queued_report.dart';
import 'package:safetj/core/offline/sync_result.dart';

void main() {
  group('QueuedReport map round-trip', () {
    test('toMap/fromMap preserves every field, including nested media', () {
      final DateTime now = DateTime.utc(2026, 7, 30, 12, 0, 0);
      final QueuedReport report = QueuedReport(
        clientUuid: '11111111-1111-4111-8111-111111111111',
        type: IncidentType.flood,
        description: 'Water rising fast near the bridge.',
        injuredCount: 2,
        roadBlocked: true,
        lat: 38.5598,
        lng: 68.7870,
        provinceId: 1,
        districtId: 3,
        media: const [
          QueuedMediaFile(path: '/tmp/photo1.jpg', type: MediaType.photo),
          QueuedMediaFile(path: '/tmp/clip1.mp4', type: MediaType.video),
        ],
        queuedAt: now,
      );

      final QueuedReport roundTripped = QueuedReport.fromMap(report.toMap());

      expect(roundTripped.clientUuid, report.clientUuid);
      expect(roundTripped.type, IncidentType.flood);
      expect(roundTripped.description, report.description);
      expect(roundTripped.injuredCount, 2);
      expect(roundTripped.roadBlocked, isTrue);
      expect(roundTripped.lat, 38.5598);
      expect(roundTripped.lng, 68.7870);
      expect(roundTripped.provinceId, 1);
      expect(roundTripped.districtId, 3);
      expect(roundTripped.queuedAt, now);
      expect(roundTripped.media, hasLength(2));
      expect(roundTripped.media[0].path, '/tmp/photo1.jpg');
      expect(roundTripped.media[0].type, MediaType.photo);
      expect(roundTripped.media[1].type, MediaType.video);
    });

    test('optional province/district survive being absent', () {
      final QueuedReport report = QueuedReport(
        clientUuid: 'uuid-2',
        type: IncidentType.other,
        description: '',
        injuredCount: 0,
        roadBlocked: false,
        lat: 0,
        lng: 0,
        queuedAt: DateTime.utc(2026),
      );

      final QueuedReport roundTripped = QueuedReport.fromMap(report.toMap());

      expect(roundTripped.provinceId, isNull);
      expect(roundTripped.districtId, isNull);
      expect(roundTripped.media, isEmpty);
    });
  });

  group('SyncResultItem', () {
    test('created and duplicate are resolved; error is not', () {
      expect(
        SyncResultItem.fromJson({'client_uuid': 'a', 'status': 'created'}).isResolved,
        isTrue,
      );
      expect(
        SyncResultItem.fromJson({'client_uuid': 'b', 'status': 'duplicate'}).isResolved,
        isTrue,
      );
      expect(
        SyncResultItem.fromJson({'client_uuid': 'c', 'status': 'error', 'error': 'boom'})
            .isResolved,
        isFalse,
      );
    });
  });
}
