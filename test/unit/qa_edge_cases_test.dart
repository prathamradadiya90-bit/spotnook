import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spot_finder/core/utils/formatters.dart';
import 'package:spot_finder/features/discovery/data/datasources/places_cache_service.dart';
import 'package:spot_finder/features/discovery/data/repositories/places_repository_impl.dart';
import 'package:spot_finder/features/discovery/domain/entities/place.dart';
import 'package:spot_finder/features/discovery/domain/entities/search_filter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QA Comprehensive Bug Audit Tests', () {
    late SharedPreferences prefs;
    late PlacesCacheService cacheService;
    late PlacesRepositoryImpl repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      cacheService = PlacesCacheService(prefs: prefs);
      repository = PlacesRepositoryImpl(cacheService: cacheService);
    });

    test('QA Bug 1: Repository Cache accurately filters and sorts cached responses on filter changes', () async {
      final samplePlaces = [
        const Place(
          id: 'p1',
          name: 'Zebra Club',
          categoryId: 'nightlife',
          latitude: 21.17,
          longitude: 72.83,
          formattedAddress: 'Addr 1',
          rating: 4.2,
          isOpenNow: true,
          phoneNumber: '+1234567890',
          website: 'https://zebra.com',
          distanceInMeters: 800,
        ),
        const Place(
          id: 'p2',
          name: 'apple bakery',
          categoryId: 'bakery',
          latitude: 21.18,
          longitude: 72.84,
          formattedAddress: 'Addr 2',
          rating: 4.9,
          isOpenNow: false,
          distanceInMeters: 200,
        ),
      ];

      final key = PlacesCacheService.buildKey(
        latitude: 21.1702,
        longitude: 72.8311,
        categoryId: 'all',
        radiusMeters: 5000,
      );

      // Pre-warm cache
      await cacheService.put(key: key, places: samplePlaces);

      // 1. Query with openNowOnly: true -> should only get Zebra Club
      final openResults = await repository.getNearbyPlaces(
        latitude: 21.1702,
        longitude: 72.8311,
        radiusMeters: 5000,
        categoryId: 'all',
        filter: const SearchFilter(openNowOnly: true),
      );
      expect(openResults.length, 1);
      expect(openResults.first.id, 'p1');

      // 2. Query with minRating: 4.5 -> should only get apple bakery
      final highRatedResults = await repository.getNearbyPlaces(
        latitude: 21.1702,
        longitude: 72.8311,
        radiusMeters: 5000,
        categoryId: 'all',
        filter: const SearchFilter(minRating: 4.5),
      );
      expect(highRatedResults.length, 1);
      expect(highRatedResults.first.id, 'p2');

      // 3. Query with hasPhoneOnly: true -> should only get Zebra Club
      final phoneResults = await repository.getNearbyPlaces(
        latitude: 21.1702,
        longitude: 72.8311,
        radiusMeters: 5000,
        categoryId: 'all',
        filter: const SearchFilter(hasPhoneOnly: true),
      );
      expect(phoneResults.length, 1);
      expect(phoneResults.first.id, 'p1');

      // 4. Query with sortBy: 'name' -> 'apple bakery' must precede 'Zebra Club' (case-insensitive)
      final nameSortedResults = await repository.getNearbyPlaces(
        latitude: 21.1702,
        longitude: 72.8311,
        radiusMeters: 5000,
        categoryId: 'all',
        filter: const SearchFilter(sortBy: 'name'),
      );
      expect(nameSortedResults.length, 2);
      expect(nameSortedResults[0].name, 'apple bakery');
      expect(nameSortedResults[1].name, 'Zebra Club');
    });

    test('QA Bug 2: Venues with null distance are sorted to the bottom, not treated as 0m', () async {
      final samplePlaces = [
        const Place(
          id: 'p_null',
          name: 'Unknown Distance Venue',
          categoryId: 'cafe',
          latitude: 21.17,
          longitude: 72.83,
          formattedAddress: 'Addr 1',
          distanceInMeters: null, // Distance unknown
        ),
        const Place(
          id: 'p_near',
          name: 'Very Close Venue',
          categoryId: 'cafe',
          latitude: 21.17,
          longitude: 72.83,
          formattedAddress: 'Addr 2',
          distanceInMeters: 150, // 150 meters
        ),
      ];

      final key = PlacesCacheService.buildKey(
        latitude: 21.1702,
        longitude: 72.8311,
        categoryId: 'all',
        radiusMeters: 5000,
      );
      await cacheService.put(key: key, places: samplePlaces);

      final results = await repository.getNearbyPlaces(
        latitude: 21.1702,
        longitude: 72.8311,
        radiusMeters: 5000,
        categoryId: 'all',
        filter: const SearchFilter(sortBy: 'distance'),
      );

      // Very Close Venue (150m) MUST come first, Unknown Distance must come second
      expect(results.first.id, 'p_near');
      expect(results.last.id, 'p_null');
    });

    test('QA Security: Formatters strictly reject malicious URL schemes and invalid dialer inputs', () {
      // Rejects script injection
      expect(Formatters.sanitizeHttpUrl('javascript:alert(1)'), isNull);
      expect(Formatters.sanitizeHttpUrl('data:text/html,<script>alert(1)</script>'), isNull);
      expect(Formatters.sanitizeHttpUrl('file:///etc/passwd'), isNull);
      expect(Formatters.sanitizeHttpUrl('content://media/external/images'), isNull);

      // Accepts and normalizes legitimate URLs
      expect(Formatters.sanitizeHttpUrl('https://example.com/menu'), 'https://example.com/menu');
      expect(Formatters.sanitizeHttpUrl('http://insecure-site.org'), 'http://insecure-site.org');
      expect(Formatters.sanitizeHttpUrl('mycafe.com'), 'https://mycafe.com');

      // Phone validation
      expect(Formatters.isValidPhoneNumber(''), isFalse);
      expect(Formatters.isValidPhoneNumber('12'), isFalse); // Too short
      expect(Formatters.isValidPhoneNumber('abc-def-ghij'), isFalse); // Non-numeric
      expect(Formatters.isValidPhoneNumber('+1 (555) 234-5678'), isTrue);
      expect(Formatters.isValidPhoneNumber('+919876543210'), isTrue);
    });
  });
}
