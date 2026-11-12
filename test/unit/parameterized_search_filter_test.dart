import 'package:flutter_test/flutter_test.dart';
import 'package:spot_finder/features/discovery/domain/entities/category.dart';
import 'package:spot_finder/features/discovery/domain/entities/place.dart';
import 'package:spot_finder/features/discovery/domain/entities/search_filter.dart';

void main() {
  group('Parameterized SearchFilter & Sorting Tests', () {
    const testRadii = [100.0, 500.0, 1000.0, 5000.0, 10000.0, 50000.0];
    const testSortOptions = ['distance', 'rating', 'name'];
    const testMinRatings = [0.0, 3.5, 4.0, 4.5, 5.0];

    for (final radius in testRadii) {
      test('SearchFilter correctly preserves radius: $radius meters', () {
        final filter = const SearchFilter().copyWith(radiusInMeters: radius);
        expect(filter.radiusInMeters, radius);
      });
    }

    for (final sort in testSortOptions) {
      test('SearchFilter correctly handles sort option: $sort', () {
        final filter = const SearchFilter().copyWith(sortBy: sort);
        expect(filter.sortBy, sort);
      });
    }

    for (final rating in testMinRatings) {
      test('SearchFilter correctly handles minRating: $rating', () {
        final filter = const SearchFilter().copyWith(minRating: rating);
        expect(filter.minRating, rating);
      });
    }

    test('Validates all 18+ predefined categories in PlaceCategory registry', () {
      const allCategories = PlaceCategory.standardCategories;
      expect(allCategories.length, greaterThanOrEqualTo(18));

      for (final cat in allCategories) {
        expect(cat.id.isNotEmpty, isTrue);
        expect(cat.name.isNotEmpty, isTrue);

        final found = PlaceCategory.findById(cat.id);
        expect(found.id, cat.id);
        expect(found.name, cat.name);
      }
    });

    test('Falls back gracefully to default category for unknown category IDs', () {
      final unknown = PlaceCategory.findById('completely_non_existent_category_123');
      expect(unknown.id, 'all');
    });

    test('Filters place list across multiple predicate combinations', () {
      final places = [
        const Place(
          id: '1',
          name: 'Cafe Alpha',
          categoryId: 'cafe',
          latitude: 21.17,
          longitude: 72.83,
          formattedAddress: '123 Main St',
          rating: 4.8,
          distanceInMeters: 250,
          isOpenNow: true,
          phoneNumber: '+91 9876543210',
          website: 'https://cafealpha.com',
        ),
        const Place(
          id: '2',
          name: 'Hotel Beta',
          categoryId: 'hotel',
          latitude: 21.18,
          longitude: 72.84,
          formattedAddress: '456 Grand Ave',
          rating: 3.9,
          distanceInMeters: 1200,
          isOpenNow: false,
          phoneNumber: null,
          website: null,
        ),
        const Place(
          id: '3',
          name: 'Gym Gamma',
          categoryId: 'gym',
          latitude: 21.19,
          longitude: 72.85,
          formattedAddress: '789 Fitness Blvd',
          rating: 4.5,
          distanceInMeters: 4500,
          isOpenNow: true,
          phoneNumber: '+91 1122334455',
          website: null,
        ),
      ];

      // Test 1: Open now only
      final openOnly = places.where((p) => p.isOpenNow == true).toList();
      expect(openOnly.length, 2);
      expect(openOnly.map((p) => p.id), containsAll(['1', '3']));

      // Test 2: Min rating 4.0
      final min4 = places.where((p) => (p.rating ?? 0.0) >= 4.0).toList();
      expect(min4.length, 2);
      expect(min4.map((p) => p.id), containsAll(['1', '3']));

      // Test 3: Has phone only
      final hasPhone = places.where((p) => p.phoneNumber != null && p.phoneNumber!.isNotEmpty).toList();
      expect(hasPhone.length, 2);

      // Test 4: Has website only
      final hasWeb = places.where((p) => p.website != null && p.website!.isNotEmpty).toList();
      expect(hasWeb.length, 1);
      expect(hasWeb.first.id, '1');

      // Test 5: Distance sorting (ascending)
      final sortedByDist = [...places]..sort((a, b) => (a.distanceInMeters ?? 0).compareTo(b.distanceInMeters ?? 0));
      expect(sortedByDist.map((p) => p.id).toList(), ['1', '2', '3']);

      // Test 6: Rating sorting (descending)
      final sortedByRating = [...places]..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
      expect(sortedByRating.map((p) => p.id).toList(), ['1', '3', '2']);
    });
  });
}
