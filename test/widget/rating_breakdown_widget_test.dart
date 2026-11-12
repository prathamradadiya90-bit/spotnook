import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spot_finder/features/discovery/domain/entities/place.dart';
import 'package:spot_finder/features/place_detail/presentation/widgets/rating_breakdown_widget.dart';
import 'package:spot_finder/features/settings/presentation/providers/settings_provider.dart';

void main() {
  group('RatingBreakdownWidget Widget Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    const testPlace = Place(
      id: 'test_place_detail_1',
      name: 'Grand Horizon Cafe',
      categoryId: 'cafe',
      latitude: 21.17,
      longitude: 72.83,
      formattedAddress: 'Ring Road, Surat',
      rating: 4.7,
      reviewCount: 145,
    );

    testWidgets('Renders score, reviews count, star distribution, and community section', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: RatingBreakdownWidget(place: testPlace),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Ratings & Reviews'), findsOneWidget);
      expect(find.text('4.7'), findsOneWidget);
      expect(find.text('145 reviews'), findsOneWidget);
      expect(find.text('5★'), findsOneWidget);
      expect(find.text('Community Reviews'), findsOneWidget);
      expect(find.text('Rate Spot'), findsOneWidget);
    });
  });
}

