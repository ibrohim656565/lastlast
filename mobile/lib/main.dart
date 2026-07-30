import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/localization/l10n_extensions.dart';
import 'core/localization/locale_provider.dart';
import 'core/offline/offline_sync_service.dart';
import 'core/providers/core_providers.dart';
import 'core/router/app_router.dart';
import 'core/storage/hive_boxes.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/notifications/domain/app_notification.dart';
import 'features/notifications/presentation/notifications_controller.dart';
import 'features/report_incident/presentation/report_incident_providers.dart';
import 'l10n/app_localizations.dart';

/// Must be a top-level (or static) function annotated with
/// `vm:entry-point`: FCM runs it in its own background isolate, which has
/// no access to app state, so it re-initializes Firebase from scratch.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveBoxes.init();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const ProviderScope(child: SafeTjApp()));
}

class SafeTjApp extends ConsumerStatefulWidget {
  const SafeTjApp({super.key});

  @override
  ConsumerState<SafeTjApp> createState() => _SafeTjAppState();
}

class _SafeTjAppState extends ConsumerState<SafeTjApp> {
  @override
  void initState() {
    super.initState();
    // Runs once for the app's lifetime: keeps flushing the offline report
    // queue whenever connectivity returns, independent of which screen (if
    // any) is currently visible.
    ref.read(offlineSyncServiceProvider).start(
          ref.read(connectivityStreamProvider),
        );

    ref.listenManual<AuthState>(authControllerProvider, (previous, next) {
      if (next.step == AuthStep.authenticated &&
          previous?.step != AuthStep.authenticated) {
        ref.read(notificationsControllerProvider.notifier).initialize();
      }
    }, fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) {
    final GoRouter router = ref.watch(appRouterProvider);
    final Locale locale = ref.watch(localeControllerProvider);
    final ThemeMode themeMode = ref.watch(themeModeControllerProvider);

    return MaterialApp.router(
      title: 'SafeTJ',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: kSupportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => _ForegroundNotificationBanner(child: child),
    );
  }
}

/// App-wide listener that shows a snackbar/banner for every foreground FCM
/// push, regardless of which screen is currently on top — satisfies "in-app
/// alert" without every screen needing its own listener.
class _ForegroundNotificationBanner extends ConsumerStatefulWidget {
  const _ForegroundNotificationBanner({required this.child});

  final Widget? child;

  @override
  ConsumerState<_ForegroundNotificationBanner> createState() =>
      _ForegroundNotificationBannerState();
}

class _ForegroundNotificationBannerState extends ConsumerState<_ForegroundNotificationBanner> {
  final GlobalKey<ScaffoldMessengerState> _messengerKey = GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<AppNotification>? _bannerSub;
  StreamSubscription<SyncBatchResult>? _syncSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bannerSub = ref.read(notificationsControllerProvider.notifier).onBanner.listen(
        (notification) {
          _messengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text('${notification.title}: ${notification.body}'),
              duration: const Duration(seconds: 6),
            ),
          );
        },
      );
      _syncSub = ref.read(offlineSyncServiceProvider).results.listen((batch) {
        _messengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(context.l10n.reportSyncedNotice(batch.succeeded)),
            duration: const Duration(seconds: 4),
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _bannerSub?.cancel();
    _syncSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _messengerKey,
      child: _ConnectivityBanner(child: widget.child ?? const SizedBox.shrink()),
    );
  }
}

/// Thin persistent strip (not a transient snackbar) shown while the device
/// has no network path, since "offline" is an ongoing state the user should
/// stay aware of throughout the report flow, not a one-off event.
class _ConnectivityBanner extends ConsumerWidget {
  const _ConnectivityBanner({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isOnline = ref.watch(isOnlineProvider).valueOrNull ?? true;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: isOnline ? 0 : 28,
          width: double.infinity,
          color: Colors.orange.shade800,
          alignment: Alignment.center,
          child: isOnline
              ? null
              : Text(
                  context.l10n.commonOffline,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
