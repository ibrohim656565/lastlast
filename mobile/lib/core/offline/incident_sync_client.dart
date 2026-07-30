import 'queued_report.dart';
import 'sync_result.dart';

/// Abstraction the offline sync service depends on instead of importing the
/// `report_incident` feature's Dio-based repository directly, keeping
/// `core/` free of feature imports. Implemented by
/// `features/report_incident/data/incident_repository.dart`.
abstract class IncidentSyncClient {
  Future<List<SyncResultItem>> syncReports(List<QueuedReport> reports);
}
