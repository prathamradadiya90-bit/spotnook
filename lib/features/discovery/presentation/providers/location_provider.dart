import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/location_service.dart';
import '../../domain/entities/location_info.dart';
import '../../domain/repositories/places_repository.dart';
import 'discovery_providers.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

class LocationState {
  final LocationInfo location;
  final bool isLoading;
  final LocationPermissionResult permissionResult;
  final String? errorMessage;

  const LocationState({
    required this.location,
    this.isLoading = false,
    this.permissionResult = LocationPermissionResult.denied,
    this.errorMessage,
  });

  LocationState copyWith({
    LocationInfo? location,
    bool? isLoading,
    LocationPermissionResult? permissionResult,
    String? errorMessage,
  }) {
    return LocationState(
      location: location ?? this.location,
      isLoading: isLoading ?? this.isLoading,
      permissionResult: permissionResult ?? this.permissionResult,
      errorMessage: errorMessage,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  final LocationService _locationService;
  final Ref _ref;

  LocationNotifier(this._locationService, this._ref)
      : super(
          const LocationState(
            location: LocationService.defaultFallbackLocation,
            isLoading: false,
          ),
        );

  PlacesRepository get _placesRepo => _ref.read(placesRepositoryProvider);

  /// Silently checks permission on app launch without prompting the user.
  Future<void> checkInitialLocation() async {
    final status = await _locationService.checkPermission();
    if (status == LocationPermissionResult.granted) {
      await requestGpsLocation();
    }
  }

  /// Explicitly requests GPS location when user taps the "My Location" button.
  Future<bool> requestGpsLocation() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final status = await _locationService.requestForegroundPermission();
    if (status != LocationPermissionResult.granted) {
      state = state.copyWith(
        isLoading: false,
        permissionResult: status,
        errorMessage: status == LocationPermissionResult.serviceDisabled
            ? 'Location services are disabled on your device.'
            : 'Location permission was denied. You can still select any city manually.',
      );
      return false;
    }

    final pos = await _locationService.getCurrentPosition();
    if (pos == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to retrieve current coordinates. Check device GPS.',
      );
      return false;
    }

    try {
      final resolved = await _placesRepo.reverseGeocode(pos.latitude, pos.longitude);
      state = state.copyWith(
        location: resolved.copyWith(isFromGps: true),
        isLoading: false,
        permissionResult: LocationPermissionResult.granted,
      );
      return true;
    } catch (_) {
      state = state.copyWith(
        location: LocationInfo(
          latitude: pos.latitude,
          longitude: pos.longitude,
          name: 'Current Location',
          formattedAddress: '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}',
          isFromGps: true,
        ),
        isLoading: false,
        permissionResult: LocationPermissionResult.granted,
      );
      return true;
    }
  }

  /// Sets an explicitly selected location (from City Search or Map Pin).
  void setLocation(LocationInfo location) {
    state = state.copyWith(location: location, errorMessage: null);
  }

  /// Reverse-geocodes and sets a location from map pin coordinate.
  Future<void> selectCoordinate(double lat, double lon) async {
    state = state.copyWith(isLoading: true);
    try {
      final resolved = await _placesRepo.reverseGeocode(lat, lon);
      state = state.copyWith(location: resolved, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        location: LocationInfo(
          latitude: lat,
          longitude: lon,
          name: 'Selected Pin',
          formattedAddress: '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}',
          isFromGps: false,
        ),
        isLoading: false,
      );
    }
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  final service = ref.watch(locationServiceProvider);
  return LocationNotifier(service, ref);
});

