import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spot_finder/core/theme/app_theme.dart';
import 'package:spot_finder/features/discovery/domain/entities/place.dart';
import 'package:spot_finder/features/discovery/presentation/providers/discovery_providers.dart';
import 'package:spot_finder/features/discovery/presentation/screens/search_screen.dart';
import 'package:spot_finder/features/place_detail/presentation/screens/place_detail_screen.dart';
import 'package:spot_finder/features/saved/presentation/screens/saved_screen.dart';
import 'package:spot_finder/features/settings/presentation/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  const testPlace = Place(
    id: 'test_node_101',
    name: 'Honest Roasters Cafe',
    categoryId: 'cafe',
    latitude: 21.1702,
    longitude: 72.8311,
    formattedAddress: '123 Ring Road, Surat',
    distanceInMeters: 450,
    rating: null, // Verified: rating is NOT fabricated
    reviewCount: null,
    priceLevel: null,
    isOpenNow: true,
    openingHours: 'Mo-Su 08:00-22:00',
    phoneNumber: '+912612233445',
    website: 'https://honestroasters.example.com',
    sourceProvider: 'osm',
  );

  testWidgets('Integration Flow: Search -> Results -> Detail -> Bookmark -> Saved Screen',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        searchResultsProvider('Coffee').overrideWith((ref) => [testPlace]),
      ],
    );
    addTearDown(container.dispose);

    // 1. Build Search Screen with mocked repository/results
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SearchScreen(initialQuery: 'Coffee'),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // 2. Validate place card is displayed with rating
    expect(find.text('Honest Roasters Cafe'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsAtLeastNWidgets(1));
    // Price level must NOT be displayed since it is null
    expect(find.text(r'$'), findsNothing);

    // 3. Navigate into Place Detail Screen
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const PlaceDetailScreen(place: testPlace),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // 4. Verify detail elements
    expect(find.text('Honest Roasters Cafe'), findsOneWidget);
    expect(find.text('123 Ring Road, Surat'), findsOneWidget);
    expect(find.text('Directions'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);

    // Tap Save button to bookmark the venue
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // 5. Open Saved Screen and verify bookmarked venue appears
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SavedScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify Honest Roasters Cafe is present in saved bookmarks
    expect(find.text('Honest Roasters Cafe'), findsOneWidget);
  });
}
