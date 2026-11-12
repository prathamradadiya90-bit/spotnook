import 'dart:math';

/// Immutable geographic bounding box with antimeridian normalization and pole clamping.
class GeoBoundingBox {
  final double minLat;
  final double minLon;
  final double maxLat;
  final double maxLon;
  final bool crossesAntimeridian;

  const GeoBoundingBox({
    required this.minLat,
    required this.minLon,
    required this.maxLat,
    required this.maxLon,
    this.crossesAntimeridian = false,
  });

  /// Approximate meters per degree of latitude anywhere on Earth.
  static const double metersPerLatDegree = 111320.0;

  /// Calculates a bounding box around a center [latitude] and [longitude] for a given [radiusMeters].
  ///
  /// - Latitude is clamped strictly to `[-90.0, 90.0]`.
  /// - Radian conversion is properly applied for longitude delta.
  /// - Poles (lat > 89.9 or < -89.9) are safely handled to avoid division by zero.
  /// - Antimeridian crossings (-180 / +180) are detected and normalized.
  factory GeoBoundingBox.fromCenterAndRadius({
    required double latitude,
    required double longitude,
    required double radiusMeters,
  }) {
    // Clamp radius to a sane range (10m to 500km)
    final clampedRadius = radiusMeters.clamp(10.0, 500000.0);

    // Compute latitude delta
    final latDelta = clampedRadius / metersPerLatDegree;
    final minLat = (latitude - latDelta).clamp(-90.0, 90.0);
    final maxLat = (latitude + latDelta).clamp(-90.0, 90.0);

    // Guard against pole singularities
    final absLat = latitude.abs();
    if (absLat >= 89.9) {
      return GeoBoundingBox(
        minLat: minLat,
        minLon: -180.0,
        maxLat: maxLat,
        maxLon: 180.0,
        crossesAntimeridian: false,
      );
    }

    // Longitude delta with cosine of latitude in radians
    final latRad = latitude * pi / 180.0;
    final cosLat = cos(latRad).abs();
    final effectiveCos = cosLat < 0.0001 ? 0.0001 : cosLat;
    final lonDelta = clampedRadius / (metersPerLatDegree * effectiveCos);

    final rawMinLon = longitude - lonDelta;
    final rawMaxLon = longitude + lonDelta;

    final crossesAntimeridian = rawMinLon < -180.0 || rawMaxLon > 180.0;

    final minLon = normalizeLongitude(rawMinLon);
    final maxLon = normalizeLongitude(rawMaxLon);

    return GeoBoundingBox(
      minLat: minLat,
      minLon: minLon,
      maxLat: maxLat,
      maxLon: maxLon,
      crossesAntimeridian: crossesAntimeridian,
    );
  }

  /// Normalizes any longitude degree value to `[-180.0, 180.0]`.
  static double normalizeLongitude(double lon) {
    if (lon >= -180.0 && lon <= 180.0) return lon;
    final wrapped = (lon + 180.0) % 360.0;
    final normalized = wrapped < 0.0 ? wrapped + 180.0 : wrapped - 180.0;
    // Edge case for -180 vs 180
    return normalized == -180.0 ? 180.0 : normalized;
  }

  /// Formats viewbox for Nominatim API: `minLon,maxLat,maxLon,minLat`
  String toNominatimViewbox({int precision = 5}) {
    // When crossing antimeridian or near poles, provide clamped full-range bounds
    if (crossesAntimeridian) {
      return '-180.00000,${maxLat.toStringAsFixed(precision)},180.00000,${minLat.toStringAsFixed(precision)}';
    }
    return '${minLon.toStringAsFixed(precision)},${maxLat.toStringAsFixed(precision)},${maxLon.toStringAsFixed(precision)},${minLat.toStringAsFixed(precision)}';
  }

  /// Formats bbox for Overpass QL API: `(minLat,minLon,maxLat,maxLon)`
  String toOverpassBbox({int precision = 5}) {
    if (crossesAntimeridian) {
      return '(${minLat.toStringAsFixed(precision)},-180.0,${maxLat.toStringAsFixed(precision)},180.0)';
    }
    return '(${minLat.toStringAsFixed(precision)},${minLon.toStringAsFixed(precision)},${maxLat.toStringAsFixed(precision)},${maxLon.toStringAsFixed(precision)})';
  }

  /// Checks whether a given [lat], [lon] point falls inside this bounding box.
  bool contains(double lat, double lon) {
    if (lat < minLat || lat > maxLat) return false;
    final normLon = normalizeLongitude(lon);
    if (!crossesAntimeridian) {
      return normLon >= minLon && normLon <= maxLon;
    }
    // Crosses antimeridian: point can be >= minLon OR <= maxLon
    return normLon >= minLon || normLon <= maxLon;
  }

  @override
  String toString() => 'GeoBoundingBox(lat: [$minLat, $maxLat], lon: [$minLon, $maxLon], antimeridian: $crossesAntimeridian)';
}

