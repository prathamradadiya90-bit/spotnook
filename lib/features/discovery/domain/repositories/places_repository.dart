import '../entities/location_info.dart';
import '../entities/place.dart';
import '../entities/search_filter.dart';

/// Abstract contract for venue discovery and geocoding operations.
abstract class PlacesRepository {
  /// Searches for places matching a keyword query around a center coordinate.
  Future<List<Place>> searchPlaces({
    required String query,
    required double latitude,
    required double longitude,
    double radiusMeters = 5000,
    String categoryId = 'all',
    SearchFilter? filter,
  });

  /// Discovers nearby places for a specific category around a center coordinate.
  Future<List<Place>> getNearbyPlaces({
    required double latitude,
    required double longitude,
    double radiusMeters = 5000,
    String categoryId = 'all',
    SearchFilter? filter,
  });

  /// Retrieves extended details for a specific place.
  Future<Place?> getPlaceDetails(String placeId);

  /// Resolves coordinate into a human-readable city/neighborhood address.
  Future<LocationInfo> reverseGeocode(double latitude, double longitude);

  /// Searches for cities, areas, or neighborhoods matching a text query.
  Future<List<LocationInfo>> searchLocations(String query);
}

