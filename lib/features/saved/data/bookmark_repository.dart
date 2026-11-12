import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../discovery/domain/entities/place.dart';

/// Repository for managing user-owned local bookmarks, recently viewed venues, and search history.
/// 100% on-device local persistence; no remote user tracking.
class BookmarkRepository {
  static const String _bookmarksKey = 'spotfinder_bookmarks_v1';
  static const String _recentSearchesKey = 'spotfinder_recent_searches_v1';
  static const String _recentlyViewedKey = 'spotfinder_recently_viewed_v1';
  static const String _visitedPlacesKey = 'spotfinder_visited_places_v1';

  final SharedPreferences _prefs;

  BookmarkRepository(this._prefs);

  /// Retrieves all saved favorite places.
  List<Place> getBookmarks() {
    final rawList = _prefs.getStringList(_bookmarksKey) ?? [];
    final places = <Place>[];
    for (final raw in rawList) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        places.add(Place.fromJson(map));
      } catch (_) {}
    }
    return places;
  }

  /// Checks if a place is bookmarked.
  bool isBookmarked(String placeId) {
    final bookmarks = getBookmarks();
    return bookmarks.any((p) => p.id == placeId);
  }

  /// Toggles bookmark state for a venue.
  Future<bool> toggleBookmark(Place place) async {
    final bookmarks = getBookmarks();
    final index = bookmarks.indexWhere((p) => p.id == place.id);
    bool isNowBookmarked;

    if (index >= 0) {
      bookmarks.removeAt(index);
      isNowBookmarked = false;
    } else {
      bookmarks.insert(0, place);
      isNowBookmarked = true;
    }

    final rawList = bookmarks.map((p) => jsonEncode(p.toJson())).toList();
    await _prefs.setStringList(_bookmarksKey, rawList);
    return isNowBookmarked;
  }

  /// Removes a bookmark by ID.
  Future<void> removeBookmark(String placeId) async {
    final bookmarks = getBookmarks();
    bookmarks.removeWhere((p) => p.id == placeId);
    final rawList = bookmarks.map((p) => jsonEncode(p.toJson())).toList();
    await _prefs.setStringList(_bookmarksKey, rawList);
  }

  /// Clears all saved bookmarks.
  Future<void> clearBookmarks() async {
    await _prefs.remove(_bookmarksKey);
  }

  /// Retrieves recent search queries.
  List<String> getRecentSearches() {
    return _prefs.getStringList(_recentSearchesKey) ?? [];
  }

  /// Adds a search query to history.
  Future<void> addRecentSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;

    final history = getRecentSearches().toList();
    history.remove(clean);
    history.insert(0, clean);
    if (history.length > 20) {
      history.removeRange(20, history.length);
    }
    await _prefs.setStringList(_recentSearchesKey, history);
  }

  /// Removes a search query from history.
  Future<void> removeRecentSearch(String query) async {
    final history = getRecentSearches().toList();
    history.remove(query);
    await _prefs.setStringList(_recentSearchesKey, history);
  }

  /// Clears search history.
  Future<void> clearRecentSearches() async {
    await _prefs.remove(_recentSearchesKey);
  }

  /// Retrieves recently viewed places.
  List<Place> getRecentlyViewed() {
    final rawList = _prefs.getStringList(_recentlyViewedKey) ?? [];
    final places = <Place>[];
    for (final raw in rawList) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        places.add(Place.fromJson(map));
      } catch (_) {}
    }
    return places;
  }

  /// Adds a place to recently viewed history.
  Future<void> addRecentlyViewed(Place place) async {
    final viewed = getRecentlyViewed().toList();
    viewed.removeWhere((p) => p.id == place.id);
    viewed.insert(0, place);
    if (viewed.length > 20) {
      viewed.removeRange(20, viewed.length);
    }
    final rawList = viewed.map((p) => jsonEncode(p.toJson())).toList();
    await _prefs.setStringList(_recentlyViewedKey, rawList);
  }

  /// Clears recently viewed history.
  Future<void> clearRecentlyViewed() async {
    await _prefs.remove(_recentlyViewedKey);
  }

  /// Retrieves all places marked as visited by the user.
  List<Place> getVisitedPlaces() {
    final rawList = _prefs.getStringList(_visitedPlacesKey) ?? [];
    final places = <Place>[];
    for (final raw in rawList) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        places.add(Place.fromJson(map));
      } catch (_) {}
    }
    return places;
  }

  /// Checks if a place is marked as visited.
  bool isVisited(String placeId) {
    final visited = getVisitedPlaces();
    return visited.any((p) => p.id == placeId);
  }

  /// Toggles visited status for a venue.
  Future<bool> toggleVisited(Place place) async {
    final visited = getVisitedPlaces();
    final index = visited.indexWhere((p) => p.id == place.id);
    bool isNowVisited;

    if (index >= 0) {
      visited.removeAt(index);
      isNowVisited = false;
    } else {
      visited.insert(0, place);
      isNowVisited = true;
    }

    final rawList = visited.map((p) => jsonEncode(p.toJson())).toList();
    await _prefs.setStringList(_visitedPlacesKey, rawList);
    return isNowVisited;
  }

  /// Clears visited places.
  Future<void> clearVisited() async {
    await _prefs.remove(_visitedPlacesKey);
  }

  /// Completely wipes all local user data (Google Play User Data deletion compliance).
  Future<void> clearAllUserData() async {
    await _prefs.remove(_bookmarksKey);
    await _prefs.remove(_recentSearchesKey);
    await _prefs.remove(_recentlyViewedKey);
    await _prefs.remove(_visitedPlacesKey);
  }
}
