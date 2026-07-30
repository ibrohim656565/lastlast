import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/incident_constants.dart';
import '../../../core/offline/queued_report.dart';
import '../../../core/providers/core_providers.dart';
import 'report_incident_providers.dart';

enum ReportSubmitOutcome { submittedOnline, queuedOffline, failed }

class ReportFormState {
  const ReportFormState({
    required this.type,
    this.description = '',
    this.injuredCount = 0,
    this.roadBlocked = false,
    this.media = const [],
    this.position,
    this.isFetchingLocation = false,
    this.locationError = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final IncidentType type;
  final String description;
  final int injuredCount;
  final bool roadBlocked;
  final List<QueuedMediaFile> media;
  final Position? position;
  final bool isFetchingLocation;
  final bool locationError;
  final bool isSubmitting;
  final String? errorMessage;

  ReportFormState copyWith({
    IncidentType? type,
    String? description,
    int? injuredCount,
    bool? roadBlocked,
    List<QueuedMediaFile>? media,
    Position? position,
    bool? isFetchingLocation,
    bool? locationError,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ReportFormState(
      type: type ?? this.type,
      description: description ?? this.description,
      injuredCount: injuredCount ?? this.injuredCount,
      roadBlocked: roadBlocked ?? this.roadBlocked,
      media: media ?? this.media,
      position: position ?? this.position,
      isFetchingLocation: isFetchingLocation ?? this.isFetchingLocation,
      locationError: locationError ?? this.locationError,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ReportFormController extends StateNotifier<ReportFormState> {
  ReportFormController(this._ref, IncidentType initialType)
      : super(ReportFormState(type: initialType)) {
    fetchLocation();
  }

  final Ref _ref;

  Future<void> fetchLocation() async {
    state = state.copyWith(isFetchingLocation: true, locationError: false);
    final Position? position = await _ref.read(locationServiceProvider).getCurrentPosition();
    state = state.copyWith(
      isFetchingLocation: false,
      position: position,
      locationError: position == null,
    );
  }

  void setType(IncidentType type) => state = state.copyWith(type: type);

  void setDescription(String value) => state = state.copyWith(description: value);

  void setInjuredCount(int value) =>
      state = state.copyWith(injuredCount: value < 0 ? 0 : value);

  void setRoadBlocked(bool value) => state = state.copyWith(roadBlocked: value);

  void addMedia(List<QueuedMediaFile> files) {
    final int remaining = 5 - state.media.length;
    if (remaining <= 0) return;
    state = state.copyWith(media: [...state.media, ...files.take(remaining)]);
  }

  void removeMediaAt(int index) {
    final List<QueuedMediaFile> next = [...state.media]..removeAt(index);
    state = state.copyWith(media: next);
  }

  Future<ReportSubmitOutcome> submit() async {
    if (state.position == null) {
      state = state.copyWith(locationError: true);
      return ReportSubmitOutcome.failed;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    final String clientUuid = _ref.read(uuidProvider).v4();
    final bool isOnline = _ref.read(isOnlineProvider).valueOrNull ?? true;

    final QueuedReport queued = QueuedReport(
      clientUuid: clientUuid,
      type: state.type,
      description: state.description,
      injuredCount: state.injuredCount,
      roadBlocked: state.roadBlocked,
      lat: state.position!.latitude,
      lng: state.position!.longitude,
      media: state.media,
      queuedAt: DateTime.now().toUtc(),
    );

    if (!isOnline) {
      await _ref.read(offlineQueueStoreProvider).enqueue(queued);
      state = state.copyWith(isSubmitting: false);
      return ReportSubmitOutcome.queuedOffline;
    }

    try {
      await _ref.read(incidentRepositoryProvider).createIncident(
            clientUuid: clientUuid,
            type: state.type,
            description: state.description,
            injuredCount: state.injuredCount,
            roadBlocked: state.roadBlocked,
            lat: state.position!.latitude,
            lng: state.position!.longitude,
            media: state.media,
          );
      state = state.copyWith(isSubmitting: false);
      return ReportSubmitOutcome.submittedOnline;
    } catch (_) {
      // Covers the "went offline mid-submit" / transient network failure
      // case: fall back to the same offline queue rather than losing the
      // report entirely.
      await _ref.read(offlineQueueStoreProvider).enqueue(queued);
      state = state.copyWith(isSubmitting: false);
      return ReportSubmitOutcome.queuedOffline;
    }
  }
}

final reportFormControllerProvider = StateNotifierProvider.autoDispose
    .family<ReportFormController, ReportFormState, IncidentType>((ref, initialType) {
  return ReportFormController(ref, initialType);
});
