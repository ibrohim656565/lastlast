import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// Shared GPS access used by the report form (auto-capture) and the
/// shelters/map features (distance sort, "near me").
class LocationService {
  /// Requests the OS runtime permission via `permission_handler` first
  /// (consistent with how we ask for camera/photos elsewhere), then
  /// double-checks with `geolocator`'s own status, since on some OEM
  /// Android builds the two plugins can disagree right after a grant.
  Future<bool> ensurePermission() async {
    final ph.PermissionStatus status = await ph.Permission.locationWhenInUse.request();
    if (!status.isGranted) return false;

    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<Position?> getCurrentPosition() async {
    final bool granted = await ensurePermission();
    if (!granted) return null;
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  double distanceKm(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000;
  }
}
