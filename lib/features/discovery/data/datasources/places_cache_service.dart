import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/place.dart';

/// Result container for cached searches with timestamp and staleness tracking.
class CachedSearchResult {
  final List<Place> places;
  final DateTime cachedAt;
  final String key;

  const CachedSearchResult({
    required this.places,
    required this.cachedAt,
    required this.key,
  });

  /// Age of the cached result in minutes.
  int get ageInMinutes => DateTime.now().difference(cachedAt).inMinutes;

  /// Returns true if cache age exceeds [ttlMinutes] (default 10 minutes).
  bool isExpired({int ttlMinutes = 10}) {
    return DateTime.now().difference(cachedAt).inMinutes >= ttlMinutes;
  }

  /// Human-readable label (e.g. "Saved 3 min ago", "Saved just now").
  String get savedAgoLabel {
    final mins = ageInMinutes;
    if (mins <= 0) return 'Saved just now';
    if (mins == 1) return 'Saved 1 min ago';
    if (mins < 60) return 'Saved $mins min ago';
    final hours = mins ~/ 60;
    return hours == 1 ? 'Saved 1 hr ago' : 'Saved $hours hrs ago';
  }

  Map<String, dynamic> toJson() => {
        'cachedAt': cachedAt.toIso8601String(),
        'key': key,
        'places': places.map((p) => p.toJson()).toList(),
      };

  factory CachedSearchResult.fromJson(Map<String, dynamic> json) {
    final placesRaw = json['places'] as List? ?? [];
    final places = <Place>[];
    for (final item in placesRaw) {
      if (item is Map) {
        try {
          places.add(Place.fromJson(Map<String, dynamic>.from(item)));
        } catch (e) {
          debugPrint('[CachedSearchResult] Skipped corrupted place: $e');
        }
      }
    }
    final cachedAt = DateTime.tryParse(json['cachedAt']?.toString() ?? '') ?? DateTime.now();
    final key = json['key']?.toString() ?? '';
    return CachedSearchResult(places: places, cachedAt: cachedAt, key: key);
  }
}

/// Dual-tier (In-Memory + SharedPreferences) caching service for places discovery.
/// TTL: 10 minutes per query/location/category to cut redundant API requests.
class PlacesCacheService {
  final SharedPreferences? prefs;
  final Map<String, CachedSearchResult> _memoryCache = {};
  CachedSearchResult? _lastSuccessfulSearch;

  static const String _diskCachePrefix = 'spotfinder_cache_v1_';
  static const String _lastSearchKey = 'spotfinder_cache_last_search';
  static const Duration defaultTtl = Duration(minutes: 10);
  static const int maxMemoryEntries = 60;

  PlacesCacheService({this.prefs}) {
    _loadLastSuccessfulSearchFromDisk();
  }

  void _loadLastSuccessfulSearchFromDisk() {
    if (prefs == null) return;
    try {
      final raw = prefs!.getString(_lastSearchKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _lastSuccessfulSearch = CachedSearchResult.fromJson(decoded);
      }
    } catch (e) {
      debugPrint('[PlacesCacheService] Error reading last search from disk: $e');
    }
  }

  /// Generates a standardized cache key for location, category, and query.
  /// Coordinates are quantized to 3 decimals (~110m) to reuse cache for microscopic GPS drift.
  static String buildKey({
    required double latitude,
    required double longitude,
    String categoryId = 'all',
    String query = '',
    double radiusMeters = 5000,
  }) {
    final qLat = latitude.toStringAsFixed(3);
    final qLon = longitude.toStringAsFixed(3);
    final qRad = (radiusMeters / 500).round() * 500;
    final cleanQuery = query.trim().toLowerCase();
    return 'cache_${cleanQuery}_${categoryId}_${qLat}_${qLon}_${qRad}m';
  }

  /// Stores search results in both in-memory and persistent disk cache.
  Future<void> put({
    required String key,
    required List<Place> places,
  }) async {
    if (places.isEmpty) return;

    final entry = CachedSearchResult(
      places: List.unmodifiable(places),
      cachedAt: DateTime.now(),
      key: key,
    );

    if (_memoryCache.length >= maxMemoryEntries) {
      final oldestKey = _memoryCache.keys.first;
      _memoryCache.remove(oldestKey);
    }

    _memoryCache[key] = entry;
    _lastSuccessfulSearch = entry;

    if (prefs != null) {
      try {
        final encoded = jsonEncode(entry.toJson());
        await prefs!.setString('$_diskCachePrefix$key', encoded);
        await prefs!.setString(_lastSearchKey, encoded);
      } catch (e) {
        debugPrint('[PlacesCacheService] Disk cache write failed: $e');
      }
    }
  }

  /// Retrieves cached results if they exist and are within the [defaultTtl].
  CachedSearchResult? get(String key) {
    // 1. Check in-memory cache
    final memResult = _memoryCache[key];
    if (memResult != null) {
      if (!memResult.isExpired(ttlMinutes: defaultTtl.inMinutes)) {
        return memResult;
      }
    }

    // 2. Check disk cache if in-memory missed
    if (prefs != null) {
      try {
        final raw = prefs!.getString('$_diskCachePrefix$key');
        if (raw != null && raw.isNotEmpty) {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          final diskResult = CachedSearchResult.fromJson(decoded);
          if (!diskResult.isExpired(ttlMinutes: defaultTtl.inMinutes)) {
            _memoryCache[key] = diskResult;
            return diskResult;
          }
        }
      } catch (e) {
        debugPrint('[PlacesCacheService] Disk cache read failed: $e');
      }
    }

    return null;
  }

  /// Returns the most recent successful search result, even if expired or for another query.
  /// Used exclusively as an honest fallback when offline or network fails.
  CachedSearchResult? getLastSuccessfulSearch() {
    return _lastSuccessfulSearch;
  }

  /// Completely wipes memory and disk cache (e.g. on "Delete all my data").
  Future<void> clearAll() async {
    _memoryCache.clear();
    _lastSuccessfulSearch = null;

    if (prefs != null) {
      final keys = prefs!.getKeys().where((k) => k.startsWith(_diskCachePrefix) || k == _lastSearchKey);
      for (final k in keys) {
        await prefs!.remove(k);
      }
    }
  }
}
