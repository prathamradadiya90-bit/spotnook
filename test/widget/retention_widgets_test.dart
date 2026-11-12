import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spot_finder/features/discovery/domain/entities/place.dart';
import 'package:spot_finder/features/discovery/presentation/widgets/explorer_progress_card.dart';
import 'package:spot_finder/features/discovery/presentation/widgets/location_disclosure_dialog.dart';
import 'package:spot_finder/features/discovery/presentation/widgets/mood_chip_group.dart';
import 'package:spot_finder/features/discovery/presentation/widgets/spot_of_the_day_card.dart';
import 'package:spot_finder/features/saved/presentation/providers/saved_provider.dart';

void main() {
  group('Retention & Engagement Widgets Parameterized Tests', () {
    testWidgets('SpotOfTheDayCard renders spot name, badge, and triggers tap callback', (tester) async {
      final samplePlaces = [
        const Place(
          id: 'spot_1',
          name: 'The Daily Brew Cafe',
          categoryId: 'cafe',
          latitude: 21.17,
          longitude: 72.83,
          formattedAddress: 'Ring Road, Surat',
          rating: 4.8,
          distanceInMeters: 350,
        ),
      ];

      Place? tappedPlace;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpotOfTheDayCard(
              places: samplePlaces,
              onTap: (p) => tappedPlace = p,
            ),
          ),
        ),
      );

      expect(find.text("TODAY'S HIDDEN GEM"), findsOneWidget);
      expect(find.text('The Daily Brew Cafe'), findsOneWidget);
      expect(find.text("Explore Today's Pick"), findsOneWidget);

      await tester.tap(find.byType(SpotOfTheDayCard));
      await tester.pumpAndSettle();

      expect(tappedPlace, isNotNull);
      expect(tappedPlace!.id, 'spot_1');
    });

    testWidgets('SpotOfTheDayCard handles empty list without throwing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpotOfTheDayCard(
              places: const [],
              onTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(SpotOfTheDayCard), findsOneWidget);
      expect(find.text("TODAY'S HIDDEN GEM"), findsNothing);
    });

    testWidgets('ExplorerProgressCard displays level, rank, XP, and progress bar', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            explorerStatsProvider.overrideWithValue(
              const ExplorerStats(
                visitedCount: 4,
                bookmarkedCount: 5,
                totalPoints: 250,
                rankTitle: 'City Pathfinder 🥈',
                level: 3,
                nextLevelTarget: 500,
                levelProgress: 0.5,
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ExplorerProgressCard(),
            ),
          ),
        ),
      );

      expect(find.text('City Pathfinder 🥈'), findsOneWidget);
      expect(find.text('Level 3 Explorer'), findsOneWidget);
      expect(find.text('250 XP'), findsOneWidget);
      expect(find.text('4 Visited • 5 Saved'), findsOneWidget);
      expect(find.text('50% to Next Rank'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('MoodChipGroup renders all vibes and fires callback on selection', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      String selected = 'all';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return MoodChipGroup(
                  selectedMoodId: selected,
                  onMoodSelected: (mood) {
                    setState(() => selected = mood);
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('All Vibes'), findsOneWidget);
      expect(find.text('Work & Study'), findsOneWidget);
      expect(find.text('Outdoor & Chill'), findsOneWidget);
      expect(find.text('Late Night'), findsOneWidget);
      expect(find.text('Date Night'), findsOneWidget);
      expect(find.text('Quick Bite'), findsOneWidget);

      await tester.tap(find.text('Work & Study'));
      await tester.pumpAndSettle();

      expect(selected, 'work');
    });

    testWidgets('LocationDisclosureDialog displays prominent in-app disclosure with actions', (tester) async {
      bool? userChoice;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  userChoice = await LocationDisclosureDialog.show(context);
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Location Access'), findsOneWidget);
      expect(find.text('Nearby Place Discovery'), findsOneWidget);
      expect(find.text('Ephemeral & Private'), findsOneWidget);
      expect(find.text('No Background Tracking'), findsOneWidget);
      expect(find.text('Not Now'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      // Tap Continue
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(userChoice, isTrue);
    });
  });
}
