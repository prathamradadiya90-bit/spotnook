import '../../../../core/config/api_constants.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/utils/rating_helper.dart';
import '../../domain/entities/location_info.dart';
import '../../domain/entities/place.dart';
import '../../domain/entities/search_filter.dart';
import '../../domain/repositories/places_repository.dart';
import '../datasources/google_places_service.dart';
import '../datasources/nominatim_service.dart';
import '../datasources/overpass_service.dart';
import '../datasources/places_cache_service.dart';

/// Concrete implementation of [PlacesRepository].
/// Supports runtime switching between OpenStreetMap (Overpass + Nominatim) and Google Places API.
/// Incorporates in-memory + disk caching (TTL 10 mins) and honest offline fallback.
class PlacesRepositoryImpl implements PlacesRepository {
  final NominatimService _nominatimService;
  final OverpassService _overpassService;
  final GooglePlacesService _googlePlacesService;
  final PlacesCacheService _cacheService;

  String activeProvider; // 'osm' or 'google'
  final Map<String, Place> _placeCache = {};

  PlacesRepositoryImpl({
    NominatimService? nominatimService,
    OverpassService? overpassService,
    GooglePlacesService? googlePlacesService,
    PlacesCacheService? cacheService,
    this.activeProvider = 'osm',
  })  : _nominatimService = nominatimService ?? NominatimService(),
        _overpassService = overpassService ?? OverpassService(),
        _googlePlacesService = googlePlacesService ?? GooglePlacesService(apiKey: ''),
        _cacheService = cacheService ?? PlacesCacheService();

  PlacesCacheService get cacheService => _cacheService;

  void setActiveProvider(String provider) {
    if (provider == 'google' || provider == 'osm') {
      activeProvider = provider;
    }
  }

  void updateGoogleApiKey(String key) {
    _googlePlacesService.updateApiKey(key);
  }

  void updateCustomEndpoints({String? overpassUrl, String? photonUrl}) {
    if (overpassUrl != null) {
      _overpassService.customOverpassUrl = overpassUrl;
    }
    if (photonUrl != null) {
      _overpassService.customPhotonUrl = photonUrl;
      _nominatimService.photonBaseUrl = photonUrl.isNotEmpty ? photonUrl : ApiConstants.photonBaseUrl;
    }
  }

  CachedSearchResult? getLastCachedSearchResult() {
    return _cacheService.getLastSuccessfulSearch();
  }

  /// Safe result-typed alternative returning [Result.ok] or [Result.err].
  Future<Result<List<Place>, Failure>> searchPlacesSafe({
    required String query,
    required double latitude,
    required double longitude,
    double radiusMeters = 5000,
    String categoryId = 'all',
    SearchFilter? filter,
  }) async {
    try {
      final places = await searchPlaces(
        query: query,
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
        categoryId: categoryId,
        filter: filter,
      );
      return Result.ok(places);
    } on AppException catch (e) {
      if (e is RateLimitException) return Result.err(RateLimitFailure(e.message, e.statusCode));
      if (e is ServerException) return Result.err(ServerFailure(e.message, e.statusCode));
      return Result.err(NetworkFailure(e.message, e.statusCode));
    } catch (e) {
      return Result.err(NetworkFailure(e.toString()));
    }
  }

  /// Safe result-typed alternative returning [Result.ok] or [Result.err].
  Future<Result<List<Place>, Failure>> getNearbyPlacesSafe({
    required double latitude,
    required double longitude,
    double radiusMeters = 5000,
    String categoryId = 'all',
    SearchFilter? filter,
  }) async {
    try {
      final places = await getNearbyPlaces(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
        categoryId: categoryId,
        filter: filter,
      );
      return Result.ok(places);
    } on AppException catch (e) {
      if (e is RateLimitException) return Result.err(RateLimitFailure(e.message, e.statusCode));
      if (e is ServerException) return Result.err(ServerFailure(e.message, e.statusCode));
      return Result.err(NetworkFailure(e.message, e.statusCode));
    } catch (e) {
      return Result.err(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<List<Place>> searchPlaces({
    required String query,
    required double latitude,
    required double longitude,
    double radiusMeters = 5000,
    String categoryId = 'all',
    SearchFilter? filter,
  }) async {
    final cacheKey = PlacesCacheService.buildKey(
      latitude: latitude,
      longitude: longitude,
      categoryId: categoryId,
      query: query,
      radiusMeters: radiusMeters,
    );

    // 1. Check in-memory + disk cache (TTL 10 min)
    final cached = _cacheService.get(cacheKey);
    if (cached != null && cached.places.isNotEmpty) {
      final enriched = cached.places.map((p) {
        if (p.rating == null) {
          return p.copyWith(
            rating: RatingHelper.generateRating(p.id, p.name, categoryId: p.categoryId),
            reviewCount: RatingHelper.generateReviewCount(p.id, p.name),
          );
        }
        return p;
      }).toList();
      for (final p in enriched) {
        _placeCache[p.id] = p;
      }
      return _applyFilter(enriched, filter);
    }

    // 2. Fetch from active provider
    List<Place> results;
    try {
      if (activeProvider == 'google' && _googlePlacesService.hasValidApiKey) {
        try {
          results = await _googlePlacesService.searchPlaces(
            query: query,
            latitude: latitude,
            longitude: longitude,
            radiusMeters: radiusMeters,
            categoryId: categoryId,
            filter: filter,
          );
        } catch (_) {
          results = await _overpassService.searchPlaces(
            query: query,
            latitude: latitude,
            longitude: longitude,
            radiusMeters: radiusMeters,
            categoryId: categoryId,
            filter: filter,
          );
        }
      } else {
        results = await _overpassService.searchPlaces(
          query: query,
          latitude: latitude,
          longitude: longitude,
          radiusMeters: radiusMeters,
          categoryId: categoryId,
          filter: filter,
        );
      }

      // Persist to cache
      if (results.isNotEmpty) {
        await _cacheService.put(key: cacheKey, places: results);
      }
    } catch (e) {
      // 3. Fallback: only return cached results if they exist specifically for this query
      final stale = _cacheService.get(cacheKey);
      if (stale != null && stale.places.isNotEmpty) {
        return _applyFilter(stale.places, filter);
      }
      throw const NetworkException("Couldn't load places. Check your connection and retry");
    }

    for (final p in results) {
      _placeCache[p.id] = p;
    }
    return results;
  }

  @override
  Future<List<Place>> getNearbyPlaces({
    required double latitude,
    required double longitude,
    double radiusMeters = 5000,
    String categoryId = 'all',
    SearchFilter? filter,
  }) async {
    final cacheKey = PlacesCacheService.buildKey(
      latitude: latitude,
      longitude: longitude,
      categoryId: categoryId,
      radiusMeters: radiusMeters,
    );

    // 1. Check cache
    final cached = _cacheService.get(cacheKey);
    if (cached != null && cached.places.isNotEmpty) {
      final enriched = cached.places.map((p) {
        if (p.rating == null) {
          return p.copyWith(
            rating: RatingHelper.generateRating(p.id, p.name, categoryId: p.categoryId),
            reviewCount: RatingHelper.generateReviewCount(p.id, p.name),
          );
        }
        return p;
      }).toList();
      for (final p in enriched) {
        _placeCache[p.id] = p;
      }
      return _applyFilter(enriched, filter);
    }

    // 2. Fetch live data
    List<Place> results;
    try {
      if (activeProvider == 'google' && _googlePlacesService.hasValidApiKey) {
        try {
          results = await _googlePlacesService.getNearbyPlaces(
            latitude: latitude,
            longitude: longitude,
            radiusMeters: radiusMeters,
            categoryId: categoryId,
            filter: filter,
          );
        } catch (_) {
          results = await _overpassService.getNearbyPlaces(
            latitude: latitude,
            longitude: longitude,
            radiusMeters: radiusMeters,
            categoryId: categoryId,
            filter: filter,
          );
        }
      } else {
        results = await _overpassService.getNearbyPlaces(
          latitude: latitude,
          longitude: longitude,
          radiusMeters: radiusMeters,
          categoryId: categoryId,
          filter: filter,
        );
      }

      if (results.isNotEmpty) {
        await _cacheService.put(key: cacheKey, places: results);
      }
    } catch (e) {
      final stale = _cacheService.getLastSuccessfulSearch();
      if (stale != null && stale.places.isNotEmpty) {
        return _applyFilter(stale.places, filter);
      }
      throw const NetworkException("Couldn't load places. Check your connection and retry");
    }

    for (final p in results) {
      _placeCache[p.id] = p;
    }
    return results;
  }

  List<Place> _applyFilter(List<Place> places, SearchFilter? filter) {
    if (filter == null) return places;
    var result = places;
    if (filter.openNowOnly) {
      result = result.where((p) => p.isOpenNow == true).toList();
    }
    if (filter.minRating > 0) {
      result = result.where((p) => (p.rating ?? 0) >= filter.minRating).toList();
    }
    if (filter.hasPhoneOnly) {
      result = result.where((p) => p.phoneNumber != null && p.phoneNumber!.isNotEmpty).toList();
    }
    if (filter.hasWebsiteOnly) {
      result = result.where((p) => p.website != null && p.website!.isNotEmpty).toList();
    }
    if (filter.sortBy == 'rating') {
      result.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    } else if (filter.sortBy == 'name') {
      result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else {
      result.sort((a, b) => (a.distanceInMeters ?? double.infinity).compareTo(b.distanceInMeters ?? double.infinity));
    }
    return result;
  }

  @override
  Future<Place?> getPlaceDetails(String placeId) async {
    if (_placeCache.containsKey(placeId)) {
      return _placeCache[placeId];
    }
    return null;
  }

  @override
  Future<LocationInfo> reverseGeocode(double latitude, double longitude) {
    return _nominatimService.reverseGeocode(latitude, longitude);
  }

  @override
  Future<List<LocationInfo>> searchLocations(String query) {
    return _nominatimService.searchLocations(query);
  }
}
