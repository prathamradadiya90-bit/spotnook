import 'package:flutter_test/flutter_test.dart';
import 'package:spot_finder/core/utils/opening_hours_evaluator.dart';

void main() {
  group('OpeningHoursEvaluator Tests', () {
    test('24/7 is always open', () {
      expect(OpeningHoursEvaluator.computeIsOpenNow('24/7'), isTrue);
    });

    test('closed or off is always closed', () {
      expect(OpeningHoursEvaluator.computeIsOpenNow('off'), isFalse);
      expect(OpeningHoursEvaluator.computeIsOpenNow('closed'), isFalse);
    });

    test('Computes open status correctly on Monday within hours', () {
      // Monday 2026-11-09 14:30
      final mondayAfternoon = DateTime(2026, 11, 9, 14, 30);
      final isOpen = OpeningHoursEvaluator.computeIsOpenNow(
        'Mo-Fr 09:00-18:00; Sa 10:00-14:00',
        customNow: mondayAfternoon,
      );
      expect(isOpen, isTrue);
    });

    test('Computes closed status correctly on Monday outside hours', () {
      // Monday 2026-11-09 21:00
      final mondayNight = DateTime(2026, 11, 9, 21, 00);
      final isOpen = OpeningHoursEvaluator.computeIsOpenNow(
        'Mo-Fr 09:00-18:00; Sa 10:00-14:00',
        customNow: mondayNight,
      );
      expect(isOpen, isFalse);
    });

    test('Computes closed status on Sunday when Sunday is off', () {
      // Sunday 2026-11-08 12:00
      final sundayNoon = DateTime(2026, 11, 8, 12, 00);
      final isOpen = OpeningHoursEvaluator.computeIsOpenNow(
        'Mo-Sa 09:00-20:00; Su off',
        customNow: sundayNoon,
      );
      expect(isOpen, isFalse);
    });

    test('Computes open status correctly across midnight boundary', () {
      // Monday 23:30 for a bar open 18:00-02:00
      final mondayLate = DateTime(2026, 11, 9, 23, 30);
      final isOpenLate = OpeningHoursEvaluator.computeIsOpenNow(
        'Mo-Sa 18:00-02:00',
        customNow: mondayLate,
      );
      expect(isOpenLate, isTrue);

      // Tuesday 01:15 within the midnight boundary
      final tuesdayEarly = DateTime(2026, 11, 10, 1, 15);
      final isOpenEarly = OpeningHoursEvaluator.computeIsOpenNow(
        '18:00-02:00',
        customNow: tuesdayEarly,
      );
      expect(isOpenEarly, isTrue);
    });

    test('Returns null for unparseable or malformed opening hours', () {
      expect(OpeningHoursEvaluator.computeIsOpenNow('by appointment only'), isNull);
      expect(OpeningHoursEvaluator.computeIsOpenNow('sunrise to sunset'), isNull);
    });

    test('Returns null for null or empty string', () {
      expect(OpeningHoursEvaluator.computeIsOpenNow(null), isNull);
      expect(OpeningHoursEvaluator.computeIsOpenNow(''), isNull);
    });
  });
}

