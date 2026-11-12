import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spot_finder/features/discovery/domain/entities/place.dart';
import 'package:spot_finder/features/saved/data/bookmark_repository.dart';

void main() {
  group('BookmarkRepository Unit Tests', () {
    late SharedPreferences prefs;
    late BookmarkRepository repository;

    const testPlace = Place(
      id: 'spot_1',
      name: 'Coffee Workshop',
      categoryId: 'cafe',
      latitude: 21.17,
      longitude: 72.83,
      formattedAddress: 'Vesu, Surat',
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repository = BookmarkRepository(prefs);
    });

    test('Initial bookmarks list is empty', () {
      expect(repository.getBookmarks(), isEmpty);
      expect(repository.isBookmarked('spot_1'), isFalse);
    });

    test('Toggling a place adds it to bookmarks and returns true', () async {
      final isSaved = await repository.toggleBookmark(testPlace);
      expect(isSaved, isTrue);
      expect(repository.isBookmarked('spot_1'), isTrue);
      expect(repository.getBookmarks().length, equals(1));
      expect(repository.getBookmarks().first.name, equals('Coffee Workshop'));
    });

    test('Toggling an already bookmarked place removes it and returns false', () async {
      await repository.toggleBookmark(testPlace);
      final isSaved = await repository.toggleBookmark(testPlace);
      expect(isSaved, isFalse);
      expect(repository.isBookmarked('spot_1'), isFalse);
      expect(repository.getBookmarks(), isEmpty);
    });

    test('Recent searches stores up to 20 unique items in LIFO order', () async {
      await repository.addRecentSearch('Cafes in Surat');
      await repository.addRecentSearch('Hotels in Ahmedabad');
      await repository.addRecentSearch('Cafes in Surat'); // duplicate should move to front

      final searches = repository.getRecentSearches();
      expect(searches.length, equals(2));
      expect(searches.first, equals('Cafes in Surat'));
      expect(searches[1], equals('Hotels in Ahmedabad'));

      await repository.removeRecentSearch('Hotels in Ahmedabad');
      expect(repository.getRecentSearches(), equals(['Cafes in Surat']));

      await repository.clearRecentSearches();
      expect(repository.getRecentSearches(), isEmpty);
    });

    test('Clear all user data wipes bookmarks, history, and recently viewed', () async {
      await repository.toggleBookmark(testPlace);
      await repository.addRecentSearch('Gyms near me');
      await repository.addRecentlyViewed(testPlace);

      expect(repository.getBookmarks().isNotEmpty, isTrue);
      expect(repository.getRecentSearches().isNotEmpty, isTrue);
      expect(repository.getRecentlyViewed().isNotEmpty, isTrue);

      await repository.clearAllUserData();

      expect(repository.getBookmarks(), isEmpty);
      expect(repository.getRecentSearches(), isEmpty);
      expect(repository.getRecentlyViewed(), isEmpty);
    });
  });
}

