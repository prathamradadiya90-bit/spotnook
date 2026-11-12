import 'package:flutter_test/flutter_test.dart';
import 'package:spot_finder/core/utils/bounding_box.dart';

void main() {
  group('Parameterized GeoBoundingBox Stress & Boundary Tests', () {
    const latitudes = [-90.0, -89.9, -45.0, -21.17, 0.0, 21.17, 45.0, 51.5, 89.9, 90.0];
    const longitudes = [-180.0, -179.9, -74.0, 0.0, 72.83, 139.7, 179.9, 180.0];
    const radii = [1.0, 10.0, 500.0, 5000.0, 25000.0, 100000.0, 999999.0];

    for (final lat in latitudes) {
      for (final lon in longitudes) {
        test('Lat $lat, Lon $lon always stays clamped within [-90, 90] and [-180, 180]', () {
          final box = GeoBoundingBox.fromCenterAndRadius(
            latitude: lat,
            longitude: lon,
            radiusMeters: 5000.0,
          );

          expect(box.minLat, greaterThanOrEqualTo(-90.0));
          expect(box.maxLat, lessThanOrEqualTo(90.0));
          expect(box.minLat, lessThanOrEqualTo(box.maxLat));
          expect(box.minLon, greaterThanOrEqualTo(-180.0));
          expect(box.maxLon, lessThanOrEqualTo(180.0));
        });
      }
    }

    for (final r in radii) {
      test('Extreme radius $r meters handles clamping gracefully', () {
        final box = GeoBoundingBox.fromCenterAndRadius(
          latitude: 21.1702,
          longitude: 72.8311,
          radiusMeters: r,
        );

        expect(box.minLat, lessThanOrEqualTo(box.maxLat));
        expect(box.minLat, inInclusiveRange(-90.0, 90.0));
        expect(box.maxLat, inInclusiveRange(-90.0, 90.0));
      });
    }

    test('Antimeridian crossing detection at longitude 179.9', () {
      final box = GeoBoundingBox.fromCenterAndRadius(
        latitude: 0.0,
        longitude: 179.9,
        radiusMeters: 50000.0, // ~50km crosses 180
      );

      expect(box.crossesAntimeridian, isTrue);
    });

    test('North Pole singularity (89.95) expands longitude to full [-180, 180]', () {
      final box = GeoBoundingBox.fromCenterAndRadius(
        latitude: 89.95,
        longitude: 45.0,
        radiusMeters: 5000.0,
      );

      expect(box.minLon, -180.0);
      expect(box.maxLon, 180.0);
      expect(box.maxLat, lessThanOrEqualTo(90.0));
    });

    test('South Pole singularity (-90.0) expands longitude to full [-180, 180]', () {
      final box = GeoBoundingBox.fromCenterAndRadius(
        latitude: -90.0,
        longitude: 0.0,
        radiusMeters: 10000.0,
      );

      expect(box.minLon, -180.0);
      expect(box.maxLon, 180.0);
      expect(box.minLat, -90.0);
    });
  });
}
