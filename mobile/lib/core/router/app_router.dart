import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/otp_entry_screen.dart';
import '../../features/auth/presentation/phone_entry_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/emergency_contacts/presentation/emergency_contacts_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/incident_map/presentation/incident_map_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/report_incident/presentation/report_incident_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/shelters/presentation/shelters_screen.dart';
import '../constants/incident_constants.dart';

class AppRoutes {
  const AppRoutes._();

  static const String splash = '/splash';
  static const String phoneEntry = '/auth/phone';
  static const String otpEntry = '/auth/otp';
  static const String home = '/';
  static const String reportIncident = '/report/:type';
  static const String incidentMap = '/map';
  static const String shelters = '/shelters';
  static const String emergencyContacts = '/emergency-contacts';
  static const String notifications = '/notifications';
  static const String settings = '/settings';

  static String reportIncidentPath(IncidentType type) => '/report/${type.wireValue}';
}

/// Bridges Riverpod state changes into a [Listenable] go_router can use for
/// `refreshListenable`, so navigation re-evaluates [GoRouter.redirect]
/// whenever auth state changes (login, logout, session restored).
class _AuthRouterRefresh extends ChangeNotifier {
  _AuthRouterRefresh(Ref ref) {
    ref.listen<AuthState>(authControllerProvider, (_, __) => notifyListeners());
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final _AuthRouterRefresh refresh = _AuthRouterRefresh(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final AuthState authState = ref.read(authControllerProvider);
      final String location = state.matchedLocation;

      if (authState.step == AuthStep.unknown) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final bool loggedIn = authState.step == AuthStep.authenticated;
      final bool onAuthFlow =
          location == AppRoutes.phoneEntry || location == AppRoutes.otpEntry;

      if (!loggedIn) {
        if (location == AppRoutes.splash) return AppRoutes.phoneEntry;
        if (authState.step == AuthStep.enterOtp && location != AppRoutes.otpEntry) {
          return AppRoutes.otpEntry;
        }
        if (authState.step == AuthStep.enterPhone && location == AppRoutes.otpEntry) {
          return AppRoutes.phoneEntry;
        }
        return onAuthFlow ? null : AppRoutes.phoneEntry;
      }

      if (loggedIn && (location == AppRoutes.splash || onAuthFlow)) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: AppRoutes.phoneEntry, builder: (context, state) => const PhoneEntryScreen()),
      GoRoute(path: AppRoutes.otpEntry, builder: (context, state) => const OtpEntryScreen()),
      GoRoute(path: AppRoutes.home, builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: AppRoutes.reportIncident,
        builder: (context, state) {
          final String typeParam = state.pathParameters['type'] ?? 'other';
          return ReportIncidentScreen(initialType: IncidentType.fromWire(typeParam));
        },
      ),
      GoRoute(path: AppRoutes.incidentMap, builder: (context, state) => const IncidentMapScreen()),
      GoRoute(path: AppRoutes.shelters, builder: (context, state) => const SheltersScreen()),
      GoRoute(
        path: AppRoutes.emergencyContacts,
        builder: (context, state) => const EmergencyContactsScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(path: AppRoutes.settings, builder: (context, state) => const SettingsScreen()),
    ],
  );
});
