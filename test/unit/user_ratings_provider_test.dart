import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spot_finder/features/place_detail/presentation/providers/user_ratings_provider.dart';

void main() {
  group('UserRatingsNotifier Unit Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('Initial user ratings map is empty', () {
      final notifier = UserRatingsNotifier(prefs);
      expect(notifier.state, isEmpty);
    });

    test('submitRating adds record to state and persists to SharedPreferences', () async {
      final notifier = UserRatingsNotifier(prefs);
      await notifier.submitRating(
        placeId: 'test_place_1',
        rating: 4.5,
        comment: 'Great atmosphere!',
      );

      expect(notifier.state.containsKey('test_place_1'), isTrue);
      final record = notifier.state['test_place_1']!;
      expect(record.rating, equals(4.5));
      expect(record.comment, equals('Great atmosphere!'));

      // Check new notifier loads the persisted value
      final reloadedNotifier = UserRatingsNotifier(prefs);
      expect(reloadedNotifier.state.containsKey('test_place_1'), isTrue);
      expect(reloadedNotifier.state['test_place_1']!.rating, equals(4.5));
    });

    test('removeRating removes venue rating and updates storage', () async {
      final notifier = UserRatingsNotifier(prefs);
      await notifier.submitRating(
        placeId: 'test_place_2',
        rating: 5.0,
      );

      expect(notifier.state.containsKey('test_place_2'), isTrue);

      await notifier.removeRating('test_place_2');
      expect(notifier.state.containsKey('test_place_2'), isFalse);

      final reloaded = UserRatingsNotifier(prefs);
      expect(reloaded.state.containsKey('test_place_2'), isFalse);
    });
  });
}

