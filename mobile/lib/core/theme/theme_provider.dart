import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/core_providers.dart';
import '../storage/settings_store.dart';

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController(this._store) : super(_initial(_store));

  final SettingsStore _store;

  static ThemeMode _initial(SettingsStore store) {
    switch (store.readThemeMode()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _store.saveThemeMode(mode.name);
  }
}

final themeModeControllerProvider = StateNotifierProvider<ThemeModeController, ThemeMode>((ref) {
  return ThemeModeController(ref.watch(settingsStoreProvider));
});
