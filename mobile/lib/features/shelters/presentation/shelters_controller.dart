import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/constants/incident_constants.dart';
import '../../../core/providers/core_providers.dart';
import '../data/safe_point_repository.dart';
import '../domain/safe_point.dart';

final safePointRepositoryProvider = Provider<SafePointRepository>((ref) {
  return SafePointRepository(ref.watch(dioProvider));
});

class SheltersState {
  const SheltersState({
    this.safePoints = const [],
    this.selectedType = SafePointType.shelter,
    this.isLoading = false,
    this.errorMessage,
    this.position,
  });

  final List<SafePoint> safePoints;
  final SafePointType selectedType;
  final bool isLoading;
  final String? errorMessage;
  final Position? position;

  SheltersState copyWith({
    List<SafePoint>? safePoints,
    SafePointType? selectedType,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    Position? position,
  }) {
    return SheltersState(
      safePoints: safePoints ?? this.safePoints,
      selectedType: selectedType ?? this.selectedType,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      position: position ?? this.position,
    );
  }
}

class SheltersController extends StateNotifier<SheltersState> {
  SheltersController(this._ref) : super(const SheltersState()) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final Position? position = await _ref.read(locationServiceProvider).getCurrentPosition();
    try {
      final List<SafePoint> points = await _ref.read(safePointRepositoryProvider).fetchSafePoints(
            type: state.selectedType,
            lat: position?.latitude,
            lng: position?.longitude,
            radiusKm: AppConfig.defaultRadiusKm,
          );
      final List<SafePoint> withDistance = position == null
          ? points
          : (points
              .map((p) => p.copyWithDistance(
                    _ref.read(locationServiceProvider).distanceKm(
                          position.latitude,
                          position.longitude,
                          p.location.lat,
                          p.location.lng,
                        ),
                  ))
              .toList()
            ..sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0)));
      state = state.copyWith(safePoints: withDistance, isLoading: false, position: position);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void selectType(SafePointType type) {
    state = state.copyWith(selectedType: type);
    _load();
  }

  Future<void> refresh() => _load();
}

final sheltersControllerProvider =
    StateNotifierProvider.autoDispose<SheltersController, SheltersState>((ref) {
  return SheltersController(ref);
});
