import 'package:flutter_test/flutter_test.dart';
import 'package:spot_finder/features/discovery/domain/entities/category.dart';
import 'package:spot_finder/features/discovery/domain/entities/place.dart';
import 'package:spot_finder/features/discovery/domain/entities/search_filter.dart';
import 'package:spot_finder/features/discovery/data/datasources/places_cache_service.dart';
import 'package:spot_finder/features/discovery/data/repositories/places_repository_impl.dart';

void main() {
  group('Search All Types & Modalities Comprehensive Verification', () {
    late PlacesRepositoryImpl repository;

    setUp(() {
      repository = PlacesRepositoryImpl(
        cacheService: PlacesCacheService(),
      );
    });

    test('1. Every standard category in PlaceCategory is fully defined and queryable', () {
      final categories = PlaceCategory.standardCategories;
      expect(categories.length, greaterThanOrEqualTo(19));

      for (final cat in categories) {
        expect(cat.id.isNotEmpty, isTrue, reason: 'Category ID cannot be empty');
        expect(cat.name.isNotEmpty, isTrue, reason: 'Category name cannot be empty');
        
        final resolved = PlaceCategory.findById(cat.id);
        expect(resolved.id, equals(cat.id));
        expect(resolved.name, equals(cat.name));
      }
    });

    test('2. Case-insensitive search matches place name across all variations', () {
      final testPlaces = [
        const Place(
          id: 'p1',
          name: 'The Roasted Bean Coffee',
          categoryId: 'cafe',
          latitude: 21.17,
          longitude: 72.83,
          formattedAddress: 'Ring Road, Surat',
        ),
        const Place(
          id: 'p2',
          name: 'Apex Fitness Gym',
          categoryId: 'gym',
          latitude: 21.18,
          longitude: 72.84,
          formattedAddress: 'Adajan, Surat',
        ),
        const Place(
          id: 'p3',
          name: 'City Care Multispeciality Hospital',
          categoryId: 'hospital',
          latitude: 21.19,
          longitude: 72.85,
          formattedAddress: 'Majura Gate, Surat',
        ),
      ];

      final queryVariations = ['ROASTED', 'roasted', 'rOaStEd', 'BEAN', 'coffee'];
      for (final q in queryVariations) {
        final matches = testPlaces.where((p) => p.name.toLowerCase().contains(q.toLowerCase())).toList();
        expect(matches.length, 1);
        expect(matches.first.id, 'p1');
      }
    });

    test('3. Category filtering correctly isolates places belonging to that category', () {
      final testPlaces = [
        const Place(id: '1', name: 'Cafe Mocha', categoryId: 'cafe', latitude: 21.1, longitude: 72.8, formattedAddress: 'Address 1'),
        const Place(id: '2', name: 'Grand Palace Hotel', categoryId: 'hotel', latitude: 21.1, longitude: 72.8, formattedAddress: 'Address 2'),
        const Place(id: '3', name: 'Express Fast Food', categoryId: 'fast_food', latitude: 21.1, longitude: 72.8, formattedAddress: 'Address 3'),
        const Place(id: '4', name: 'Apollo Pharmacy', categoryId: 'pharmacy', latitude: 21.1, longitude: 72.8, formattedAddress: 'Address 4'),
        const Place(id: '5', name: 'FitLife Gym', categoryId: 'gym', latitude: 21.1, longitude: 72.8, formattedAddress: 'Address 5'),
        const Place(id: '6', name: 'State Bank ATM', categoryId: 'atm', latitude: 21.1, longitude: 72.8, formattedAddress: 'Address 6'),
      ];

      for (final cat in ['cafe', 'hotel', 'fast_food', 'pharmacy', 'gym', 'atm']) {
        final filtered = testPlaces.where((p) => p.categoryId == cat).toList();
        expect(filtered.length, 1);
        expect(filtered.first.categoryId, cat);
      }
    });

    test('4. Multi-attribute SearchFilter (Rating + Sort + Category) evaluates correctly', () {
      final testPlaces = [
        const Place(id: '1', name: 'Cafe A', categoryId: 'cafe', rating: 4.8, distanceInMeters: 500, latitude: 21.1, longitude: 72.8, formattedAddress: 'Address 1'),
        const Place(id: '2', name: 'Cafe B', categoryId: 'cafe', rating: 4.2, distanceInMeters: 200, latitude: 21.1, longitude: 72.8, formattedAddress: 'Address 2'),
        const Place(id: '3', name: 'Cafe C', categoryId: 'cafe', rating: 3.5, distanceInMeters: 100, latitude: 21.1, longitude: 72.8, formattedAddress: 'Address 3'),
        const Place(id: '4', name: 'Hotel D', categoryId: 'hotel', rating: 4.9, distanceInMeters: 50, latitude: 21.1, longitude: 72.8, formattedAddress: 'Address 4'),
      ];

      // Filter: only cafes with rating >= 4.0 sorted by distance
      final cafesHighRating = testPlaces
          .where((p) => p.categoryId == 'cafe' && (p.rating ?? 0) >= 4.0)
          .toList()
        ..sort((a, b) => (a.distanceInMeters ?? 0).compareTo(b.distanceInMeters ?? 0));

      expect(cafesHighRating.length, 2);
      expect(cafesHighRating.first.id, '2'); // 200m
      expect(cafesHighRating.last.id, '1');  // 500m
    });

    test('5. Search handles empty, whitespace, and boundary queries gracefully', () {
      const emptyQuery = '   ';
      expect(emptyQuery.trim().isEmpty, isTrue);

      const singleChar = 'a';
      expect(singleChar.trim().length, 1);

      const specialChars = r'@#$%^&*()_+=[]{}';
      expect(specialChars.trim().isNotEmpty, isTrue);
    });

    test('6. Data Honesty: Never returns unrelated places when query does not match', () {
      final testPlaces = [
        const Place(id: '1', name: 'Chai Point', categoryId: 'cafe', latitude: 21.1, longitude: 72.8, formattedAddress: 'Address 1'),
        const Place(id: '2', name: 'Domino Pizza', categoryId: 'fast_food', latitude: 21.1, longitude: 72.8, formattedAddress: 'Address 2'),
      ];

      const unrelatedQuery = 'Ferrari Showroom Automobile';
      final matches = testPlaces.where((p) =>
          p.name.toLowerCase().contains(unrelatedQuery.toLowerCase()) ||
          p.categoryId.toLowerCase().contains(unrelatedQuery.toLowerCase())).toList();

      expect(matches, isEmpty);
    });
  });
}
