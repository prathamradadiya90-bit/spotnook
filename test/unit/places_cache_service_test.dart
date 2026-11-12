import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spot_finder/features/discovery/data/datasources/places_cache_service.dart';
import 'package:spot_finder/features/discovery/domain/entities/place.dart';

void main() {
  group('PlacesCacheService Tests', () {
    late SharedPreferences prefs;
    late PlacesCacheService cacheService;

    const dummyPlace = Place(
      id: 'test_p1',
      name: 'Central Cafe',
      categoryId: 'cafe',
      latitude: 21.1702,
      longitude: 72.8311,
      formattedAddress: 'Ring Road, Surat',
      distanceInMeters: 250,
      rating: 4.5,
      reviewCount: 38,
      priceLevel: 2,
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      cacheService = PlacesCacheService(prefs: prefs);
    });

    test('buildKey normalizes coordinates to 3 decimals and category', () {
      final key1 = PlacesCacheService.buildKey(
        latitude: 21.170245,
        longitude: 72.831199,
        categoryId: 'cafe',
        query: 'Coffee',
        radiusMeters: 5000,
      );
      final key2 = PlacesCacheService.buildKey(
        latitude: 21.170201,
        longitude: 72.831111,
        categoryId: 'cafe',
        query: 'coffee',
        radiusMeters: 5200,
      );

      // Should produce the exact same key due to quantization
      expect(key1, equals(key2));
    });

    test('Stores in memory and disk cache and retrieves before expiration', () async {
      const key = 'test_cache_key';
      await cacheService.put(key: key, places: [dummyPlace]);

      final cached = cacheService.get(key);
      expect(cached, isNotNull);
      expect(cached!.places.length, equals(1));
      expect(cached.places.first.name, equals('Central Cafe'));
      expect(cached.savedAgoLabel, equals('Saved just now'));
      expect(cached.isExpired(ttlMinutes: 10), isFalse);
    });

    test('getLastSuccessfulSearch returns most recently saved result', () async {
      await cacheService.put(key: 'key1', places: [dummyPlace]);
      final last = cacheService.getLastSuccessfulSearch();
      expect(last, isNotNull);
      expect(last!.places.first.id, equals('test_p1'));
    });

    test('clearAll wipes both in-memory and disk cache', () async {
      await cacheService.put(key: 'key1', places: [dummyPlace]);
      expect(cacheService.get('key1'), isNotNull);

      await cacheService.clearAll();
      expect(cacheService.get('key1'), isNull);
      expect(cacheService.getLastSuccessfulSearch(), isNull);
    });
  });
}
