import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/incident_constants.dart';
import '../providers/core_providers.dart';
import '../storage/settings_store.dart';

class LocaleController extends StateNotifier<Locale> {
  LocaleController(this._store) : super(_initialLocale(_store));

  final SettingsStore _store;

  static Locale _initialLocale(SettingsStore store) {
    final String? saved = store.readLocale();
    if (saved != null) return Locale(saved);
    return const Locale('en');
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = Locale(language.wireValue);
    await _store.saveLocale(language.wireValue);
  }
}

final localeControllerProvider = StateNotifierProvider<LocaleController, Locale>((ref) {
  return LocaleController(ref.watch(settingsStoreProvider));
});

const List<Locale> kSupportedLocales = [
  Locale('en'),
  Locale('ru'),
  Locale('tg'),
];
