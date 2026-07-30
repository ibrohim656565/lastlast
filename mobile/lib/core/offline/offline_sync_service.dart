import 'dart:async';

import 'incident_sync_client.dart';
import 'offline_queue_store.dart';
import 'queued_report.dart';
import 'sync_result.dart';

/// Result of one flush attempt, surfaced to the UI so it can show e.g.
/// "3 queued reports were sent".
class SyncBatchResult {
  const SyncBatchResult({required this.succeeded, required this.stillQueued});

  final int succeeded;
  final int stillQueued;
}

/// Watches connectivity and flushes the offline report queue to
/// `POST /api/v1/incidents/sync` whenever the device regains a network
/// path. Also exposes [syncNow] for manual triggers (e.g. app resume,
/// pull-to-refresh).
///
/// Registered once at app start: the connectivity stream subscription is
/// intentionally never cancelled for the lifetime of the app process.
class OfflineSyncService {
  OfflineSyncService({
    required OfflineQueueStore store,
    required IncidentSyncClient client,
  })  : _store = store,
        _client = client;

  final OfflineQueueStore _store;
  final IncidentSyncClient _client;

  final StreamController<SyncBatchResult> _resultsController =
      StreamController<SyncBatchResult>.broadcast();
  Stream<SyncBatchResult> get results => _resultsController.stream;

  StreamSubscription<bool>? _connectivitySub;
  bool _isSyncing = false;

  void start(Stream<bool> isOnlineStream) {
    _connectivitySub?.cancel();
    _connectivitySub = isOnlineStream.listen((online) {
      if (online) {
        unawaited(syncNow());
      }
    });
  }

  void dispose() {
    _connectivitySub?.cancel();
    _resultsController.close();
  }

  Future<SyncBatchResult?> syncNow() async {
    if (_isSyncing) return null;
    final List<QueuedReport> pending = _store.getAll();
    if (pending.isEmpty) return null;

    _isSyncing = true;
    try {
      final List<SyncResultItem> results = await _client.syncReports(pending);
      final Iterable<String> resolvedUuids =
          results.where((r) => r.isResolved).map((r) => r.clientUuid);
      await _store.removeMany(resolvedUuids);

      final SyncBatchResult batch = SyncBatchResult(
        succeeded: resolvedUuids.length,
        stillQueued: _store.length,
      );
      if (batch.succeeded > 0) {
        _resultsController.add(batch);
      }
      return batch;
    } catch (_) {
      // Network dropped again mid-flush, or the server rejected the whole
      // batch (e.g. auth expired) — leave everything queued for next time.
      return null;
    } finally {
      _isSyncing = false;
    }
  }
}
