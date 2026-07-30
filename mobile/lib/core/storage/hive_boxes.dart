import 'package:hive_flutter/hive_flutter.dart';

/// Box name constants and one-shot Hive initialization. Called once from
/// `main.dart` before `runApp`.
class HiveBoxes {
  const HiveBoxes._();

  static const String settings = 'settings_box';
  static const String offlineQueue = 'offline_report_queue_box';
  static const String cachedAuthUser = 'cached_auth_user_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox<dynamic>(settings),
      Hive.openBox<Map<dynamic, dynamic>>(offlineQueue),
      Hive.openBox<Map<dynamic, dynamic>>(cachedAuthUser),
    ]);
  }
}
