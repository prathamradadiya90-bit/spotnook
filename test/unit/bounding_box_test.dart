import 'package:flutter_test/flutter_test.dart';
import 'package:spot_finder/core/utils/bounding_box.dart';

void main() {
  group('GeoBoundingBox Math & Clamping Tests', () {
    test('Standard coordinates (Surat, Gujarat, India)', () {
      final bbox = GeoBoundingBox.fromCenterAndRadius(
        latitude: 21.1702,
        longitude: 72.8311,
        radiusMeters: 5000,
      );

      expect(bbox.minLat, lessThan(21.1702));
      expect(bbox.maxLat, greaterThan(21.1702));
      expect(bbox.minLon, lessThan(72.8311));
      expect(bbox.maxLon, greaterThan(72.8311));
      expect(bbox.crossesAntimeridian, isFalse);

      expect(bbox.contains(21.1702, 72.8311), isTrue);
      expect(bbox.contains(25.0, 72.8311), isFalse);

      final viewbox = bbox.toNominatimViewbox();
      expect(viewbox.split(',').length, equals(4));
    });

    test('Equator boundary test (0, 0)', () {
      final bbox = GeoBoundingBox.fromCenterAndRadius(
        latitude: 0.0,
        longitude: 0.0,
        radiusMeters: 10000,
      );

      expect(bbox.minLat, closeTo(-0.0898, 0.005));
      expect(bbox.maxLat, closeTo(0.0898, 0.005));
      expect(bbox.minLon, closeTo(-0.0898, 0.005));
      expect(bbox.maxLon, closeTo(0.0898, 0.005));
      expect(bbox.crossesAntimeridian, isFalse);
    });

    test('North pole latitude clamping (89.95 degrees)', () {
      final bbox = GeoBoundingBox.fromCenterAndRadius(
        latitude: 89.95,
        longitude: 0.0,
        radiusMeters: 50000,
      );

      // Must clamp maxLat to 90.0 without crash
      expect(bbox.maxLat, equals(90.0));
      expect(bbox.minLon, equals(-180.0));
      expect(bbox.maxLon, equals(180.0));
    });

    test('South pole latitude clamping (-89.95 degrees)', () {
      final bbox = GeoBoundingBox.fromCenterAndRadius(
        latitude: -89.95,
        longitude: 45.0,
        radiusMeters: 50000,
      );

      expect(bbox.minLat, equals(-90.0));
      expect(bbox.minLon, equals(-180.0));
      expect(bbox.maxLon, equals(180.0));
    });

    test('Antimeridian crossing (Fiji / Bering Strait at 179.95 degrees)', () {
      final bbox = GeoBoundingBox.fromCenterAndRadius(
        latitude: -16.0,
        longitude: 179.95,
        radiusMeters: 25000, // spans across 180° into negative longitudes
      );

      expect(bbox.crossesAntimeridian, isTrue);
      // Contains the center point
      expect(bbox.contains(-16.0, 179.95), isTrue);
      // Contains a point just across the antimeridian (-179.95)
      expect(bbox.contains(-16.0, -179.95), isTrue);
      // Does not contain point halfway across globe (0, 0)
      expect(bbox.contains(0.0, 0.0), isFalse);

      final viewbox = bbox.toNominatimViewbox();
      expect(viewbox, startsWith('-180.00000'));
      expect(viewbox, contains('180.00000'));
    });

    test('Normalize longitude utility', () {
      expect(GeoBoundingBox.normalizeLongitude(0.0), equals(0.0));
      expect(GeoBoundingBox.normalizeLongitude(180.0), equals(180.0));
      expect(GeoBoundingBox.normalizeLongitude(185.0), closeTo(-175.0, 0.0001));
      expect(GeoBoundingBox.normalizeLongitude(-185.0), closeTo(175.0, 0.0001));
      expect(GeoBoundingBox.normalizeLongitude(540.0), equals(180.0));
    });
  });
}

