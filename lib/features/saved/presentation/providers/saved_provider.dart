import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../discovery/domain/entities/place.dart';
import '../../data/bookmark_repository.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return BookmarkRepository(prefs);
});

/// Notifier managing active bookmarks list.
class BookmarksNotifier extends StateNotifier<List<Place>> {
  final BookmarkRepository _repo;

  BookmarksNotifier(this._repo) : super(_repo.getBookmarks());

  bool isBookmarked(String id) => state.any((p) => p.id == id);

  Future<bool> toggle(Place place) async {
    final result = await _repo.toggleBookmark(place);
    state = _repo.getBookmarks();
    return result;
  }

  Future<void> remove(String id) async {
    await _repo.removeBookmark(id);
    state = _repo.getBookmarks();
  }

  Future<void> clearAll() async {
    await _repo.clearBookmarks();
    state = [];
  }
}

final bookmarksProvider = StateNotifierProvider<BookmarksNotifier, List<Place>>((ref) {
  final repo = ref.watch(bookmarkRepositoryProvider);
  return BookmarksNotifier(repo);
});

/// Notifier managing recent searches.
class RecentSearchesNotifier extends StateNotifier<List<String>> {
  final BookmarkRepository _repo;

  RecentSearchesNotifier(this._repo) : super(_repo.getRecentSearches());

  Future<void> add(String query) async {
    await _repo.addRecentSearch(query);
    state = _repo.getRecentSearches();
  }

  Future<void> remove(String query) async {
    await _repo.removeRecentSearch(query);
    state = _repo.getRecentSearches();
  }

  Future<void> clear() async {
    await _repo.clearRecentSearches();
    state = [];
  }
}

final recentSearchesProvider = StateNotifierProvider<RecentSearchesNotifier, List<String>>((ref) {
  final repo = ref.watch(bookmarkRepositoryProvider);
  return RecentSearchesNotifier(repo);
});

/// Notifier managing recently viewed venues.
class RecentlyViewedNotifier extends StateNotifier<List<Place>> {
  final BookmarkRepository _repo;

  RecentlyViewedNotifier(this._repo) : super(_repo.getRecentlyViewed());

  Future<void> add(Place place) async {
    await _repo.addRecentlyViewed(place);
    state = _repo.getRecentlyViewed();
  }

  Future<void> clear() async {
    await _repo.clearRecentlyViewed();
    state = [];
  }
}

final recentlyViewedProvider = StateNotifierProvider<RecentlyViewedNotifier, List<Place>>((ref) {
  final repo = ref.watch(bookmarkRepositoryProvider);
  return RecentlyViewedNotifier(repo);
});

/// Notifier managing places marked as visited.
class VisitedPlacesNotifier extends StateNotifier<List<Place>> {
  final BookmarkRepository _repo;

  VisitedPlacesNotifier(this._repo) : super(_repo.getVisitedPlaces());

  bool isVisited(String id) => state.any((p) => p.id == id);

  Future<bool> toggle(Place place) async {
    final result = await _repo.toggleVisited(place);
    state = _repo.getVisitedPlaces();
    return result;
  }

  Future<void> clearAll() async {
    await _repo.clearVisited();
    state = [];
  }
}

final visitedPlacesProvider = StateNotifierProvider<VisitedPlacesNotifier, List<Place>>((ref) {
  final repo = ref.watch(bookmarkRepositoryProvider);
  return VisitedPlacesNotifier(repo);
});

/// Gamification Stats Model for repeat user engagement.
class ExplorerStats {
  final int visitedCount;
  final int bookmarkedCount;
  final int totalPoints;
  final String rankTitle;
  final int level;
  final int nextLevelTarget;
  final double levelProgress;

  const ExplorerStats({
    required this.visitedCount,
    required this.bookmarkedCount,
    required this.totalPoints,
    required this.rankTitle,
    required this.level,
    required this.nextLevelTarget,
    required this.levelProgress,
  });

  factory ExplorerStats.calculate(int visited, int bookmarked) {
    final points = (visited * 50) + (bookmarked * 10);
    int level;
    int prevTarget;
    int nextTarget;
    String title;

    if (points < 100) {
      level = 1;
      prevTarget = 0;
      nextTarget = 100;
      title = 'Novice Wanderer 🧭';
    } else if (points < 250) {
      level = 2;
      prevTarget = 100;
      nextTarget = 250;
      title = 'Local Scout 🥉';
    } else if (points < 500) {
      level = 3;
      prevTarget = 250;
      nextTarget = 500;
      title = 'City Pathfinder 🥈';
    } else if (points < 1000) {
      level = 4;
      prevTarget = 500;
      nextTarget = 1000;
      title = 'Urban Explorer 🥇';
    } else {
      level = 5;
      prevTarget = 1000;
      nextTarget = 2000;
      title = 'Legendary Guide 👑';
    }

    final double progress = nextTarget > prevTarget
        ? ((points - prevTarget) / (nextTarget - prevTarget)).clamp(0.0, 1.0)
        : 1.0;

    return ExplorerStats(
      visitedCount: visited,
      bookmarkedCount: bookmarked,
      totalPoints: points,
      rankTitle: title,
      level: level,
      nextLevelTarget: nextTarget,
      levelProgress: progress,
    );
  }
}

final explorerStatsProvider = Provider<ExplorerStats>((ref) {
  final visited = ref.watch(visitedPlacesProvider).length;
  final bookmarked = ref.watch(bookmarksProvider).length;
  return ExplorerStats.calculate(visited, bookmarked);
});
