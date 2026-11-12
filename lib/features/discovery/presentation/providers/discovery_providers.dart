import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/places_cache_service.dart';
import '../../data/repositories/places_repository_impl.dart';
import '../../domain/entities/place.dart';
import '../../domain/entities/search_filter.dart';
import '../../domain/repositories/places_repository.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import 'location_provider.dart';

/// Places cache service provider backed by SharedPreferences.
final placesCacheServiceProvider = Provider<PlacesCacheService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PlacesCacheService(prefs: prefs);
});

/// Exposes the most recent successful search result for offline/error display.
final lastCachedSearchResultProvider = Provider<CachedSearchResult?>((ref) {
  final cache = ref.watch(placesCacheServiceProvider);
  return cache.getLastSuccessfulSearch();
});

/// Global singleton PlacesRepository provider.
final placesRepositoryProvider = Provider<PlacesRepository>((ref) {
  final settings = ref.watch(settingsProvider);
  final cache = ref.watch(placesCacheServiceProvider);
  final repo = PlacesRepositoryImpl(
    activeProvider: settings.provider,
    cacheService: cache,
  );
  if (settings.googleApiKey.isNotEmpty) {
    repo.updateGoogleApiKey(settings.googleApiKey);
  }
  repo.updateCustomEndpoints(
    overpassUrl: settings.overpassBaseUrl,
    photonUrl: settings.photonBaseUrl,
  );
  return repo;
});

/// Selected category ID on Home & Map screens ('all', 'cafe', 'restaurant', etc.).
final selectedCategoryProvider = StateProvider<String>((ref) => 'all');

/// Selected mood / vibe ID on Home screen ('all', 'work', 'outdoor', 'latenight', 'romantic', 'quick').
final selectedMoodProvider = StateProvider<String>((ref) => 'all');

/// Current search filter settings (radius, open-now, min rating, sort order).
final searchFilterProvider = StateProvider<SearchFilter>((ref) {
  final settings = ref.watch(settingsProvider);
  return SearchFilter(radiusInMeters: settings.defaultRadiusMeters);
});

/// Active search input text.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Selected place for map preview bottom card.
final selectedMapPlaceProvider = StateProvider<Place?>((ref) => null);

/// Reactive provider fetching nearby venues for current location and category.
final nearbyPlacesProvider = FutureProvider<List<Place>>((ref) async {
  final locationState = ref.watch(locationProvider);
  final categoryId = ref.watch(selectedCategoryProvider);
  final filter = ref.watch(searchFilterProvider);
  final repo = ref.watch(placesRepositoryProvider);

  return await repo.getNearbyPlaces(
    latitude: locationState.location.latitude,
    longitude: locationState.location.longitude,
    radiusMeters: filter.radiusInMeters,
    categoryId: categoryId,
    filter: filter,
  );
});

/// Reactive search provider for explicit keyword searches.
final searchResultsProvider = FutureProvider.autoDispose.family<List<Place>, String>((ref, query) async {
  final cleanQuery = query.trim();
  if (cleanQuery.isEmpty) return [];

  final locationState = ref.watch(locationProvider);
  final filter = ref.watch(searchFilterProvider);
  final repo = ref.watch(placesRepositoryProvider);

  return await repo.searchPlaces(
    query: cleanQuery,
    latitude: locationState.location.latitude,
    longitude: locationState.location.longitude,
    radiusMeters: filter.radiusInMeters,
    categoryId: filter.categoryId,
    filter: filter,
  );
});

/// Curated top discoveries (highest rated venues) around current location.
final popularPlacesProvider = FutureProvider<List<Place>>((ref) async {
  final locationState = ref.watch(locationProvider);
  final repo = ref.watch(placesRepositoryProvider);

  final places = await repo.getNearbyPlaces(
    latitude: locationState.location.latitude,
    longitude: locationState.location.longitude,
    radiusMeters: 8000,
    categoryId: 'all',
  );

  final sorted = places.toList()..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
  return sorted.take(6).toList();
});

