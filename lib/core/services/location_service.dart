import 'package:geolocator/geolocator.dart';
import '../../features/discovery/domain/entities/location_info.dart';

/// Result wrapper for location permission requests.
enum LocationPermissionResult {
  granted,
  denied,
  permanentlyDenied,
  serviceDisabled,
}

/// Service handling device geolocation and foreground permission compliance.
class LocationService {
  // Default fallback location (Surat, Gujarat, India / Global Hub)
  // Ensures the app functions 100% smoothly even if permissions are rejected.
  static const LocationInfo defaultFallbackLocation = LocationInfo(
    latitude: 21.1702,
    longitude: 72.8311,
    name: 'Surat',
    formattedAddress: 'Surat, Gujarat, India',
    isFromGps: false,
  );

  /// Checks current location permission without triggering a prompt.
  Future<LocationPermissionResult> checkPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationPermissionResult.serviceDisabled;
      }

      final permission = await Geolocator.checkPermission();
      switch (permission) {
        case LocationPermission.always:
        case LocationPermission.whileInUse:
          return LocationPermissionResult.granted;
        case LocationPermission.deniedForever:
          return LocationPermissionResult.permanentlyDenied;
        case LocationPermission.denied:
        case LocationPermission.unableToDetermine:
          return LocationPermissionResult.denied;
      }
    } catch (_) {
      return LocationPermissionResult.denied;
    }
  }

  /// Explicitly requests foreground location permission.
  /// Strictly adheres to Google Play policy: foreground only, never background.
  Future<LocationPermissionResult> requestForegroundPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationPermissionResult.serviceDisabled;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      switch (permission) {
        case LocationPermission.always:
        case LocationPermission.whileInUse:
          return LocationPermissionResult.granted;
        case LocationPermission.deniedForever:
          return LocationPermissionResult.permanentlyDenied;
        case LocationPermission.denied:
        case LocationPermission.unableToDetermine:
          return LocationPermissionResult.denied;
      }
    } catch (_) {
      return LocationPermissionResult.denied;
    }
  }

  /// Retrieves current device GPS position.
  /// Returns null if location is unavailable or permission denied.
  Future<Position?> getCurrentPosition() async {
    try {
      final status = await checkPermission();
      if (status != LocationPermissionResult.granted) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return null;
    }
  }
}

