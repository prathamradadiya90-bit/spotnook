import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spot_finder/features/discovery/data/datasources/places_cache_service.dart';
import 'package:spot_finder/features/discovery/domain/entities/place.dart';
import 'package:spot_finder/features/discovery/presentation/widgets/honest_state_widgets.dart';
import 'package:spot_finder/features/settings/presentation/providers/settings_provider.dart';

void main() {
  group('Honest State Widgets Tests', () {
    late SharedPreferences prefs;

    const testPlace = Place(
      id: 'widget_p1',
      name: 'Coffee House',
      categoryId: 'cafe',
      latitude: 21.1702,
      longitude: 72.8311,
      formattedAddress: 'Main St, City',
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('HonestErrorWidget renders honest message and triggers retry', (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: HonestErrorWidget(
                onRetry: () => retried = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text("Couldn't load places. Check your connection and retry"), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retried, isTrue);
    });

    testWidgets('HonestErrorWidget displays cached results and saved ago label', (tester) async {
      final cachedResult = CachedSearchResult(
        places: const [testPlace],
        cachedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        key: 'test_key',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: HonestErrorWidget(
                onRetry: () {},
                cachedResult: cachedResult,
              ),
            ),
          ),
        ),
      );

      expect(find.text("Couldn't load fresh places."), findsOneWidget);
      expect(find.textContaining('Saved 5 min ago'), findsOneWidget);
      expect(find.text('Coffee House'), findsOneWidget);
    });

    testWidgets('HonestEmptyWidget renders title, subtitle, and filter button', (tester) async {
      bool filterTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HonestEmptyWidget(
              title: 'No Cafes Found',
              subtitle: 'Try expanding your radius.',
              onResetFilter: () => filterTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('No Cafes Found'), findsOneWidget);
      expect(find.text('Try expanding your radius.'), findsOneWidget);
      expect(find.text('Adjust Search Radius'), findsOneWidget);

      await tester.tap(find.text('Adjust Search Radius'));
      await tester.pump();

      expect(filterTapped, isTrue);
    });
  });
}
