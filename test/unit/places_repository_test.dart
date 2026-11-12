import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spot_finder/features/discovery/data/datasources/places_cache_service.dart';
import 'package:spot_finder/features/discovery/data/repositories/places_repository_impl.dart';
import 'package:spot_finder/features/discovery/domain/entities/place.dart';

void main() {
  group('PlacesRepositoryImpl Caching & Failover Tests', () {
    late SharedPreferences prefs;
    late PlacesCacheService cacheService;
    late PlacesRepositoryImpl repository;

    const dummyPlace = Place(
      id: 'repo_p1',
      name: 'Artisan Roasters',
      categoryId: 'cafe',
      latitude: 21.1702,
      longitude: 72.8311,
      formattedAddress: 'Ring Road, Surat',
      distanceInMeters: 300,
      rating: 4.6,
      reviewCount: 42,
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      cacheService = PlacesCacheService(prefs: prefs);
      repository = PlacesRepositoryImpl(cacheService: cacheService);
    });

    test('Serves cached places immediately when available in cache', () async {
      final cacheKey = PlacesCacheService.buildKey(
        latitude: 21.1702,
        longitude: 72.8311,
        categoryId: 'cafe',
        radiusMeters: 5000,
      );

      await cacheService.put(key: cacheKey, places: [dummyPlace]);

      final results = await repository.getNearbyPlaces(
        latitude: 21.1702,
        longitude: 72.8311,
        categoryId: 'cafe',
        radiusMeters: 5000,
      );

      expect(results.length, equals(1));
      expect(results.first.name, equals('Artisan Roasters'));
    });

    test('getPlaceDetails returns cached venue by placeId', () async {
      final cacheKey = PlacesCacheService.buildKey(
        latitude: 21.1702,
        longitude: 72.8311,
        categoryId: 'cafe',
        radiusMeters: 5000,
      );

      await cacheService.put(key: cacheKey, places: [dummyPlace]);
      await repository.getNearbyPlaces(
        latitude: 21.1702,
        longitude: 72.8311,
        categoryId: 'cafe',
        radiusMeters: 5000,
      );

      final detail = await repository.getPlaceDetails('repo_p1');
      expect(detail, isNotNull);
      expect(detail!.id, equals('repo_p1'));
    });

    test('searchPlacesSafe returns Result.ok when cache hit', () async {
      final cacheKey = PlacesCacheService.buildKey(
        latitude: 21.1702,
        longitude: 72.8311,
        categoryId: 'cafe',
        query: 'Artisan',
        radiusMeters: 5000,
      );

      await cacheService.put(key: cacheKey, places: [dummyPlace]);

      final safeResult = await repository.searchPlacesSafe(
        query: 'Artisan',
        latitude: 21.1702,
        longitude: 72.8311,
        categoryId: 'cafe',
      );

      expect(safeResult.isSuccess, isTrue);
      expect(safeResult.dataOrNull?.first.name, equals('Artisan Roasters'));
    });
  });
}
