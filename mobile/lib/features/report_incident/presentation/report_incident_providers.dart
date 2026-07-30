import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/offline/offline_queue_store.dart';
import '../../../core/offline/offline_sync_service.dart';
import '../../../core/providers/core_providers.dart';
import '../data/incident_repository.dart';

final incidentRepositoryProvider = Provider<IncidentRepository>((ref) {
  return IncidentRepository(ref.watch(dioProvider));
});

/// Single long-lived instance: created once and started from `main.dart`
/// with the app-wide connectivity stream so it keeps flushing the queue for
/// the whole process lifetime, not just while the report screen is open.
final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) {
  final OfflineSyncService service = OfflineSyncService(
    store: ref.watch(offlineQueueStoreProvider),
    client: ref.watch(incidentRepositoryProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

final offlineQueueLengthProvider = Provider<int>((ref) {
  final OfflineQueueStore store = ref.watch(offlineQueueStoreProvider);
  return store.length;
});
