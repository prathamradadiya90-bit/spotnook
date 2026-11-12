import 'dart:math' as math;

/// Utility for geographic distance calculations using the Haversine formula.
class DistanceCalculator {
  DistanceCalculator._();

  static const double earthRadiusMeters = 6371000.0;
  static const double earthRadiusMiles = 3958.8;

  /// Calculates the geodesic distance between two coordinates in meters.
  static double calculateDistanceInMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  /// Calculates the geodesic distance between two coordinates in kilometers.
  static double calculateDistanceInKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return calculateDistanceInMeters(lat1, lon1, lat2, lon2) / 1000.0;
  }

  /// Formats distance in a human-friendly string (e.g. "350 m", "2.4 km", "1.5 mi").
  static String formatDistance(double distanceInMeters, {bool useMiles = false}) {
    if (distanceInMeters.isNaN || distanceInMeters.isInfinite || distanceInMeters < 0) {
      return '';
    }

    if (useMiles) {
      final miles = distanceInMeters / 1609.344;
      if (miles < 0.1) {
        final feet = (distanceInMeters * 3.28084).round();
        return '$feet ft';
      }
      return '${miles.toStringAsFixed(1)} mi';
    } else {
      if (distanceInMeters < 1000) {
        return '${distanceInMeters.round()} m';
      } else {
        final km = distanceInMeters / 1000.0;
        return '${km.toStringAsFixed(1)} km';
      }
    }
  }

  static double _toRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }
}

