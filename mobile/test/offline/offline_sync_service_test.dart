import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:safetj/core/constants/incident_constants.dart';
import 'package:safetj/core/offline/incident_sync_client.dart';
import 'package:safetj/core/offline/offline_queue_store.dart';
import 'package:safetj/core/offline/offline_sync_service.dart';
import 'package:safetj/core/offline/queued_report.dart';
import 'package:safetj/core/offline/sync_result.dart';
import 'package:safetj/core/storage/hive_boxes.dart';

/// Stands in for `IncidentRepository.syncReports` (the real Dio-backed
/// implementation of [IncidentSyncClient]) so this test never touches the
/// network. Behavior is scripted per-`client_uuid` via [scriptedResults].
class _FakeIncidentSyncClient implements IncidentSyncClient {
  _FakeIncidentSyncClient(this.scriptedResults);

  final Map<String, SyncItemStatus> scriptedResults;
  int callCount = 0;
  List<QueuedReport>? lastBatch;

  @override
  Future<List<SyncResultItem>> syncReports(List<QueuedReport> reports) async {
    callCount++;
    lastBatch = reports;
    return reports
        .map((r) => SyncResultItem(
              clientUuid: r.clientUuid,
              status: scriptedResults[r.clientUuid] ?? SyncItemStatus.error,
            ))
        .toList();
  }
}

QueuedReport _report(String clientUuid) => QueuedReport(
      clientUuid: clientUuid,
      type: IncidentType.fire,
      description: 'test report $clientUuid',
      injuredCount: 0,
      roadBlocked: false,
      lat: 38.55,
      lng: 68.77,
      queuedAt: DateTime.utc(2026, 7, 30),
    );

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('safetj_hive_test_');
    Hive.init(tempDir.path);
    await Hive.openBox<Map<dynamic, dynamic>>(HiveBoxes.offlineQueue);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('syncNow removes created/duplicate items and keeps errored ones queued', () async {
    final OfflineQueueStore store = OfflineQueueStore();
    await store.enqueue(_report('created-1'));
    await store.enqueue(_report('duplicate-1'));
    await store.enqueue(_report('error-1'));
    expect(store.length, 3);

    final _FakeIncidentSyncClient client = _FakeIncidentSyncClient({
      'created-1': SyncItemStatus.created,
      'duplicate-1': SyncItemStatus.duplicate,
      'error-1': SyncItemStatus.error,
    });
    final OfflineSyncService service = OfflineSyncService(store: store, client: client);

    final SyncBatchResult? result = await service.syncNow();

    expect(client.callCount, 1);
    expect(result, isNotNull);
    expect(result!.succeeded, 2);
    expect(result.stillQueued, 1);
    expect(store.length, 1);
    expect(store.getAll().single.clientUuid, 'error-1');

    service.dispose();
  });

  test('syncNow is a no-op when the queue is empty', () async {
    final OfflineQueueStore store = OfflineQueueStore();
    final _FakeIncidentSyncClient client = _FakeIncidentSyncClient({});
    final OfflineSyncService service = OfflineSyncService(store: store, client: client);

    final SyncBatchResult? result = await service.syncNow();

    expect(result, isNull);
    expect(client.callCount, 0);

    service.dispose();
  });

  test('start() triggers a flush only on transition to online', () async {
    final OfflineQueueStore store = OfflineQueueStore();
    await store.enqueue(_report('created-1'));

    final _FakeIncidentSyncClient client =
        _FakeIncidentSyncClient({'created-1': SyncItemStatus.created});
    final OfflineSyncService service = OfflineSyncService(store: store, client: client);

    final StreamController<bool> connectivity = StreamController<bool>();
    service.start(connectivity.stream);

    connectivity.add(false);
    await Future<void>.delayed(Duration.zero);
    expect(client.callCount, 0, reason: 'going offline must not trigger a sync');

    connectivity.add(true);
    await Future<void>.delayed(Duration.zero);
    expect(client.callCount, 1, reason: 'regaining connectivity must trigger a sync');
    expect(store.length, 0);

    await connectivity.close();
    service.dispose();
  });

  test('enqueue is idempotent per client_uuid (re-queuing overwrites, not duplicates)', () async {
    final OfflineQueueStore store = OfflineQueueStore();
    await store.enqueue(_report('same-uuid'));
    await store.enqueue(_report('same-uuid'));

    expect(store.length, 1);
  });
}
