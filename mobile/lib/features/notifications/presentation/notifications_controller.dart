import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/device_token_repository.dart';
import '../domain/app_notification.dart';

final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

final deviceTokenRepositoryProvider = Provider<DeviceTokenRepository>((ref) {
  return DeviceTokenRepository(ref.watch(dioProvider));
});

/// Owns the FCM lifecycle: permission request, token registration
/// (`POST /api/v1/device-tokens`) on login and on refresh, the foreground
/// message handler, and the in-app alert list. The background handler is a
/// separate top-level function registered in `main.dart`, since
/// `onBackgroundMessage` requires a standalone isolate entry point.
class NotificationsController extends StateNotifier<List<AppNotification>> {
  NotificationsController(this._ref) : super(const []);

  final Ref _ref;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<String>? _tokenRefreshSub;

  final StreamController<AppNotification> _bannerController =
      StreamController<AppNotification>.broadcast();

  /// Emits every foreground push so a single app-level listener can show a
  /// banner/snackbar regardless of which screen is on top.
  Stream<AppNotification> get onBanner => _bannerController.stream;

  Future<void> initialize() async {
    final FirebaseMessaging messaging = _ref.read(firebaseMessagingProvider);
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    await _registerCurrentToken();

    _foregroundSub?.cancel();
    _foregroundSub = FirebaseMessaging.onMessage.listen(_handleMessage);

    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = messaging.onTokenRefresh.listen((token) {
      _ref.read(deviceTokenRepositoryProvider).registerToken(token);
    });
  }

  Future<void> _registerCurrentToken() async {
    final String? token = await _ref.read(firebaseMessagingProvider).getToken();
    if (token == null) return;
    try {
      await _ref.read(deviceTokenRepositoryProvider).registerToken(token);
    } catch (_) {
      // Best-effort: registration will retry on next app start / token
      // refresh, and push simply won't arrive in the meantime.
    }
  }

  void _handleMessage(RemoteMessage message) {
    final AppNotification notification = AppNotification.fromRemoteMessageData(
      title: message.notification?.title,
      body: message.notification?.body,
      data: message.data,
    );
    state = [notification, ...state];
    _bannerController.add(notification);
  }

  @override
  void dispose() {
    _foregroundSub?.cancel();
    _tokenRefreshSub?.cancel();
    _bannerController.close();
    super.dispose();
  }
}

final notificationsControllerProvider =
    StateNotifierProvider<NotificationsController, List<AppNotification>>((ref) {
  return NotificationsController(ref);
});
