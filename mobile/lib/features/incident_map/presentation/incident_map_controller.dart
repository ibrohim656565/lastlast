import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/constants/incident_constants.dart';
import '../../report_incident/data/incident_repository.dart';
import '../../report_incident/domain/incident.dart';
import '../../report_incident/presentation/report_incident_providers.dart';

class IncidentMapFilters {
  const IncidentMapFilters({this.type, this.status});

  final IncidentType? type;
  final IncidentStatus? status;

  IncidentMapFilters copyWith({
    IncidentType? type,
    bool clearType = false,
    IncidentStatus? status,
    bool clearStatus = false,
  }) {
    return IncidentMapFilters(
      type: clearType ? null : (type ?? this.type),
      status: clearStatus ? null : (status ?? this.status),
    );
  }
}

class IncidentMapState {
  const IncidentMapState({
    this.incidents = const [],
    this.filters = const IncidentMapFilters(),
    this.isLoading = false,
    this.errorMessage,
  });

  final List<Incident> incidents;
  final IncidentMapFilters filters;
  final bool isLoading;
  final String? errorMessage;

  IncidentMapState copyWith({
    List<Incident>? incidents,
    IncidentMapFilters? filters,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return IncidentMapState(
      incidents: incidents ?? this.incidents,
      filters: filters ?? this.filters,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class IncidentMapController extends StateNotifier<IncidentMapState> {
  IncidentMapController(this._repository) : super(const IncidentMapState());

  final IncidentRepository _repository;

  Future<void> load({double? lat, double? lng}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final List<Incident> incidents = await _repository.fetchIncidents(
        type: state.filters.type,
        status: state.filters.status,
        lat: lat,
        lng: lng,
        radiusKm: (lat != null && lng != null) ? AppConfig.defaultRadiusKm : null,
      );
      state = state.copyWith(incidents: incidents, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setTypeFilter(IncidentType? type) {
    state = state.copyWith(
      filters: state.filters.copyWith(type: type, clearType: type == null),
    );
    load();
  }

  void setStatusFilter(IncidentStatus? status) {
    state = state.copyWith(
      filters: state.filters.copyWith(status: status, clearStatus: status == null),
    );
    load();
  }
}

final incidentMapControllerProvider =
    StateNotifierProvider.autoDispose<IncidentMapController, IncidentMapState>((ref) {
  return IncidentMapController(ref.watch(incidentRepositoryProvider));
});
