import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../location/location_service.dart';
import '../network/dio_client.dart';
import '../offline/offline_queue_store.dart';
import '../storage/secure_storage.dart';
import '../storage/settings_store.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final settingsStoreProvider = Provider<SettingsStore>((ref) {
  return SettingsStore();
});

final dioProvider = Provider<Dio>((ref) {
  return DioClient(ref.watch(secureStorageProvider)).dio;
});

final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

/// Emits `true` while the device believes it has a network path. Backed by
/// `connectivity_plus`; note this reflects link state, not true internet
/// reachability, which is an accepted trade-off for triggering queue sync.
final isOnlineProvider = StreamProvider<bool>((ref) {
  final Connectivity connectivity = ref.watch(connectivityProvider);
  return connectivity.onConnectivityChanged.map(
    (results) => results.any((r) => r != ConnectivityResult.none),
  );
});

final offlineQueueStoreProvider = Provider<OfflineQueueStore>((ref) {
  return OfflineQueueStore();
});

final uuidProvider = Provider<Uuid>((ref) => const Uuid());

final locationServiceProvider = Provider<LocationService>((ref) => LocationService());

