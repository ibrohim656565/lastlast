import 'package:hive_flutter/hive_flutter.dart';

import '../storage/hive_boxes.dart';
import 'queued_report.dart';

/// CRUD wrapper around the Hive box that backs the offline incident report
/// queue. Keyed by `client_uuid` so re-queuing an already-queued report is
/// idempotent.
class OfflineQueueStore {
  Box<Map<dynamic, dynamic>> get _box =>
      Hive.box<Map<dynamic, dynamic>>(HiveBoxes.offlineQueue);

  Future<void> enqueue(QueuedReport report) async {
    await _box.put(report.clientUuid, report.toMap());
  }

  List<QueuedReport> getAll() {
    return _box.values.map(QueuedReport.fromMap).toList()
      ..sort((a, b) => a.queuedAt.compareTo(b.queuedAt));
  }

  Future<void> remove(String clientUuid) => _box.delete(clientUuid);

  Future<void> removeMany(Iterable<String> clientUuids) =>
      _box.deleteAll(clientUuids);

  int get length => _box.length;

  Stream<void> watch() => _box.watch().map((_) {});
}
