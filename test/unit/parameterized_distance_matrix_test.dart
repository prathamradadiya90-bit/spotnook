import 'package:flutter_test/flutter_test.dart';
import 'package:spot_finder/core/utils/distance_calculator.dart';

void main() {
  group('Parameterized Distance Matrix & Unit Tests', () {
    test('Distance between identical coordinates is strictly 0.0', () {
      final d = DistanceCalculator.calculateDistanceInMeters(21.1702, 72.8311, 21.1702, 72.8311);
      expect(d, closeTo(0.0, 0.001));
    });

    test('Distance between Surat (21.1702, 72.8311) and Mumbai (19.0760, 72.8777)', () {
      final km = DistanceCalculator.calculateDistanceInKm(21.1702, 72.8311, 19.0760, 72.8777);
      // Actual ground distance ~230-240 km geodesic
      expect(km, inInclusiveRange(220.0, 250.0));
    });

    test('Distance between London (51.5074, -0.1278) and Paris (48.8566, 2.3522)', () {
      final km = DistanceCalculator.calculateDistanceInKm(51.5074, -0.1278, 48.8566, 2.3522);
      // London to Paris ~340 km
      expect(km, inInclusiveRange(335.0, 350.0));
    });

    final metricFormatCases = {
      0.0: '0 m',
      45.2: '45 m',
      350.8: '351 m',
      999.4: '999 m',
      1000.0: '1.0 km',
      1550.0: '1.6 km',
      2400.0: '2.4 km',
      15200.0: '15.2 km',
      120500.0: '120.5 km',
    };

    metricFormatCases.forEach((meters, expected) {
      test('Formats metric $meters m -> "$expected"', () {
        expect(DistanceCalculator.formatDistance(meters, useMiles: false), expected);
      });
    });

    final imperialFormatCases = {
      10.0: '33 ft',
      50.0: '164 ft',
      500.0: '0.3 mi',
      1609.344: '1.0 mi',
      3218.688: '2.0 mi',
      8046.72: '5.0 mi',
    };

    imperialFormatCases.forEach((meters, expected) {
      test('Formats imperial $meters m -> "$expected"', () {
        expect(DistanceCalculator.formatDistance(meters, useMiles: true), expected);
      });
    });

    test('Handles negative, NaN, and Infinite distance values safely', () {
      expect(DistanceCalculator.formatDistance(-100.0), '');
      expect(DistanceCalculator.formatDistance(double.nan), '');
      expect(DistanceCalculator.formatDistance(double.infinity), '');
    });
  });
}

