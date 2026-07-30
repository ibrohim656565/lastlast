import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/emergency_contact_repository.dart';
import '../domain/emergency_contact.dart';

final emergencyContactRepositoryProvider = Provider<EmergencyContactRepository>((ref) {
  return EmergencyContactRepository(ref.watch(dioProvider));
});

class EmergencyContactsState {
  const EmergencyContactsState({
    this.contacts = const [],
    this.isLoading = true,
    this.isFallback = false,
  });

  final List<EmergencyContact> contacts;
  final bool isLoading;
  final bool isFallback;

  EmergencyContactsState copyWith({
    List<EmergencyContact>? contacts,
    bool? isLoading,
    bool? isFallback,
  }) {
    return EmergencyContactsState(
      contacts: contacts ?? this.contacts,
      isLoading: isLoading ?? this.isLoading,
      isFallback: isFallback ?? this.isFallback,
    );
  }
}

class EmergencyContactsController extends StateNotifier<EmergencyContactsState> {
  EmergencyContactsController(this._repository) : super(const EmergencyContactsState()) {
    load();
  }

  final EmergencyContactRepository _repository;

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final List<EmergencyContact> contacts = await _repository.fetchContacts();
      state = EmergencyContactsState(contacts: contacts, isLoading: false, isFallback: false);
    } catch (_) {
      state = EmergencyContactsState(
        contacts: _repository.fallbackContacts(),
        isLoading: false,
        isFallback: true,
      );
    }
  }
}

final emergencyContactsControllerProvider = StateNotifierProvider.autoDispose<
    EmergencyContactsController, EmergencyContactsState>((ref) {
  return EmergencyContactsController(ref.watch(emergencyContactRepositoryProvider));
});
