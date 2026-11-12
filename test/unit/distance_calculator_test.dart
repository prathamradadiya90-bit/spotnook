import 'package:flutter_test/flutter_test.dart';
import 'package:spot_finder/core/utils/distance_calculator.dart';

void main() {
  group('DistanceCalculator Tests', () {
    test('Calculates distance between Surat and Ahmedabad accurately (~200 km)', () {
      // Surat coordinates: 21.1702, 72.8311
      // Ahmedabad coordinates: 23.0225, 72.5714
      final distanceKm = DistanceCalculator.calculateDistanceInKm(
        21.1702,
        72.8311,
        23.0225,
        72.5714,
      );

      expect(distanceKm, greaterThan(200.0));
      expect(distanceKm, lessThan(215.0));
    });

    test('Distance between identical coordinates is 0 meters', () {
      final distanceMeters = DistanceCalculator.calculateDistanceInMeters(
        40.7128,
        -74.0060,
        40.7128,
        -74.0060,
      );

      expect(distanceMeters, closeTo(0.0, 0.001));
    });

    test('Formats distance under 1000m in meters', () {
      final formatted = DistanceCalculator.formatDistance(450.0);
      expect(formatted, equals('450 m'));
    });

    test('Formats distance over 1000m in kilometers', () {
      final formatted = DistanceCalculator.formatDistance(2450.0);
      expect(formatted, equals('2.5 km'));
    });

    test('Formats distance in miles when requested', () {
      // 1609.34 meters ≈ 1.0 mi
      final formatted = DistanceCalculator.formatDistance(1609.34, useMiles: true);
      expect(formatted, equals('1.0 mi'));
    });

    test('Handles negative or invalid distances gracefully', () {
      expect(DistanceCalculator.formatDistance(-10.0), equals(''));
      expect(DistanceCalculator.formatDistance(double.nan), equals(''));
    });
  });
}

