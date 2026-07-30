# SafeTJ — Mobile App

Flutter client for **SafeTJ**, the disaster-management and emergency-reporting
platform for the Republic of Tajikistan. Implements clean architecture,
Riverpod state management, go_router navigation, full Tajik/Russian/English
localization, and light/dark theming inspired by the national flag
(blue `#0033A0`, white, red `#CE1126`), tuned for legibility under emergency
stress (large tap targets, high contrast).

This app talks to the Laravel backend under `../backend/` strictly through
the contract in [`../docs/API_CONTRACT.md`](../docs/API_CONTRACT.md) — that
file is the single source of truth for field names, enums, and response
envelopes on both sides.

## Getting started

> The `flutter` SDK is required locally to run any of this — it is not
> vendored in this repo.

```bash
cd mobile
flutter pub get

# Generates lib/l10n/app_localizations.dart from the ARB files in lib/l10n/.
# Re-run after editing any *.arb file.
flutter gen-l10n

# One-time Firebase setup (Phone Auth + FCM). Requires a Firebase project
# with Phone Authentication enabled. This writes native config
# (google-services.json / GoogleService-Info.plist) and, if you let it,
# lib/firebase_options.dart.
dart pub global activate flutterfire_cli
flutterfire configure

flutter run
```

If you don't run `flutterfire configure`, you can instead drop
`android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist`
in manually — `Firebase.initializeApp()` in `lib/main.dart` picks up native
config either way and does not require `firebase_options.dart`.

### Platform scaffolding

This repo ships the Dart source tree only (no `android/`, `ios/` folders —
those are generated, machine-specific, and mostly boilerplate). Run
`flutter create .` from `mobile/` once to generate them, then add:

- **Android** (`android/app/src/main/AndroidManifest.xml`): `INTERNET`,
  `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `CAMERA`,
  `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO` (or `READ_EXTERNAL_STORAGE` on
  older targets), `POST_NOTIFICATIONS` permissions, and `minSdkVersion 23`+
  (required by `firebase_auth`/`geolocator`).
- **iOS** (`ios/Runner/Info.plist`): `NSLocationWhenInUseUsageDescription`,
  `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`,
  `NSMicrophoneUsageDescription` (video capture), and enable Push
  Notifications + Background Modes → Remote notifications in the Runner
  target's capabilities.

## Configuration

The API base URL is a compile-time define, read in
`lib/core/constants/app_config.dart`:

```dart
static const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.safetj.tj/api/v1',
);
```

Point it at a local backend during development:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

(`10.0.2.2` is the Android emulator's alias for the host machine's
`localhost`; use your LAN IP for a physical device, or `localhost` for iOS
simulator.)

## Architecture

Clean-architecture-flavored, organized by feature rather than by layer at
the top level:

```
lib/
  core/           # cross-cutting: theme, router, localization, network,
                   storage, offline sync, shared constants/enums, widgets
  features/
    <feature>/
      data/        # repositories — talk to Dio / Firebase, know wire format
      domain/      # plain Dart models mirroring API_CONTRACT.md exactly
      presentation/ # Riverpod controllers (StateNotifier) + screens/widgets
  l10n/           # ARB source files + generated AppLocalizations (gitignored
                   # output, regenerate with `flutter gen-l10n`)
```

- **State management**: `flutter_riverpod`. Each feature exposes its
  repository and controller as providers; screens are `ConsumerWidget`s that
  `watch` a `StateNotifierProvider` and call methods on its `.notifier`.
- **Navigation**: `go_router`, single `GoRouter` provider
  (`core/router/app_router.dart`) with a `redirect` callback driven by auth
  state (`AuthStep.unknown → enterPhone/enterOtp → authenticated`), refreshed
  via a small `ChangeNotifier` bridge (`refreshListenable`) so login/logout
  immediately re-routes without manual `context.go` calls scattered around.
- **Networking**: one `Dio` instance (`core/network/dio_client.dart`) with
  two interceptors — `AuthInterceptor` attaches
  `Authorization: Bearer <sanctum-token>` from secure storage to every
  request, and `ErrorInterceptor` normalizes every failure into an
  `ApiException` (wraps Laravel's `{ data, message, errors }` envelope) so
  UI code never touches raw `DioException`s.
- **Offline-first incident reporting**: `core/offline/` holds the queue
  infrastructure independent of any feature — `QueuedReport` /
  `OfflineQueueStore` (Hive-backed) / `OfflineSyncService`. The service
  depends only on the `IncidentSyncClient` interface (also in `core/offline`)
  rather than importing the `report_incident` feature directly, so `core/`
  stays free of feature imports; `features/report_incident/data/
  incident_repository.dart` implements that interface against
  `POST /api/v1/incidents/sync`. `OfflineSyncService.start()` is called once
  from `main.dart` with the app-wide connectivity stream and keeps flushing
  the queue for the whole process lifetime — not just while the report
  screen happens to be open.
- **Auth**: Firebase Phone Auth (`verifyPhoneNumber` → SMS OTP →
  `signInWithCredential`) gets a Firebase ID token, which is exchanged once
  for a Laravel Sanctum token via `POST /api/v1/auth/login`
  (`features/auth/data/auth_repository.dart`). Only the Sanctum token is
  persisted (in `flutter_secure_storage`); Firebase's own session is left to
  the Firebase SDK.
- **Push notifications**: `firebase_messaging` requests permission and
  registers/refreshes the FCM token via `POST /api/v1/device-tokens` once
  the user is authenticated (wired in `main.dart` via a listener on auth
  state). Foreground pushes are surfaced through a broadcast stream
  (`NotificationsController.onBanner`) consumed by a root-level
  `ScaffoldMessenger` so a snackbar shows up regardless of which screen is
  active; `main.dart` also registers the required top-level
  `firebaseMessagingBackgroundHandler` for `onBackgroundMessage`.
- **Localization**: ARB files in `lib/l10n/` (`app_en.arb` is the template,
  `app_ru.arb`, `app_tg.arb` the translations) drive `flutter gen-l10n`.
  `core/localization/l10n_extensions.dart` exposes `context.l10n` as
  shorthand for `AppLocalizations.of(context)`. The active locale is a
  Riverpod `StateNotifierProvider` persisted to a Hive box
  (`core/localization/locale_provider.dart`), switchable from Settings.
- **Theming**: `core/theme/app_theme.dart` builds light/dark `ThemeData`
  from the flag palette in `core/theme/app_colors.dart` (blue = primary/
  trust actions, red = emergency/destructive actions). `ThemeMode` is a
  Riverpod provider persisted the same way as locale. All interactive
  controls default to a 56dp minimum tap target
  (`AppTheme.minTapTarget`) for use under stress.

### Notable gotchas already handled

- `POST /api/v1/incidents` is idempotent by `client_uuid` (a `uuid` v4
  generated on-device, see `core/providers/core_providers.dart`'s
  `uuidProvider`) — this is what lets the same locally-queued report be
  safely retried by the sync worker without risking a duplicate incident.
- If an online submission's HTTP call itself fails (e.g. connectivity drops
  mid-request), `ReportFormController.submit()` falls back to enqueueing the
  report locally rather than losing it, so "online but flaky" degrades
  gracefully into the same offline path as "no connection at submit time".
- `GET /api/v1/safe-points` and `GET /api/v1/emergency-contacts` are
  documented as bare JSON arrays (unlike the `{ data: ... }`-wrapped
  endpoints), so both repositories defensively check whether the response
  root is a `Map` or a `List` before decoding.
- Location permission is requested through `permission_handler` first (kept
  consistent with how camera/photo permissions are requested for report
  media), then double-checked against `geolocator`'s own permission status,
  since the two plugins can briefly disagree on some Android OEM builds
  right after a grant.

## Things that need a real Flutter SDK to verify

This sandbox has no `flutter` binary, so nothing here has been run through
`flutter analyze`, `flutter test`, or a compiler. Dart syntax was checked by
eye. In particular, please verify after cloning:

1. `flutter gen-l10n` succeeds against the three ARB files and every
   `context.l10n.xxx` call in `lib/` matches a generated getter.
2. `flutter_map` / `flutter_riverpod` / `go_router` major versions pinned in
   `pubspec.yaml` are mutually compatible with whatever `flutter` stable is
   current at build time — version ranges were chosen from what was current
   knowledge at write time, not resolved against `pub.dev`.
3. `image_picker`'s `pickMultiImage(limit: ...)` parameter name/behavior
   against the pinned version.
4. Firebase native setup (`flutterfire configure` or manual
   `google-services.json` / `GoogleService-Info.plist`) — nothing here
   simulates that.
5. Android manifest permissions / iOS `Info.plist` usage-description keys
   listed above — required for `geolocator`, `image_picker`,
   `permission_handler`, and `firebase_messaging` to work at runtime, not
   generated in this repo (see "Platform scaffolding" above).
