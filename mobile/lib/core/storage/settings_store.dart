import 'package:hive_flutter/hive_flutter.dart';

import 'hive_boxes.dart';

/// Persists small user preferences (theme mode, language) in the Hive
/// `settings` box as plain primitives so no adapters are needed.
class SettingsStore {
  Box<dynamic> get _box => Hive.box<dynamic>(HiveBoxes.settings);

  static const String _themeModeKey = 'theme_mode';
  static const String _localeKey = 'locale';

  String? readThemeMode() => _box.get(_themeModeKey) as String?;

  Future<void> saveThemeMode(String value) => _box.put(_themeModeKey, value);

  String? readLocale() => _box.get(_localeKey) as String?;

  Future<void> saveLocale(String value) => _box.put(_localeKey, value);
}
