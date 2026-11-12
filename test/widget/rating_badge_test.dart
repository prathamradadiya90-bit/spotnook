import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spot_finder/features/discovery/presentation/widgets/rating_badge.dart';

void main() {
  group('RatingBadge Widget Tests', () {
    testWidgets('Renders rating and review count properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RatingBadge(
              rating: 4.8,
              reviewCount: 154,
              showReviews: true,
            ),
          ),
        ),
      );

      expect(find.text('4.8'), findsOneWidget);
      expect(find.text('(154)'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });

    testWidgets('Hides reviews when showReviews is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RatingBadge(
              rating: 4.2,
              reviewCount: 88,
              showReviews: false,
            ),
          ),
        ),
      );

      expect(find.text('4.2'), findsOneWidget);
      expect(find.text('(88)'), findsNothing);
    });

    testWidgets('Returns SizedBox.shrink when rating is null or zero', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RatingBadge(rating: null),
          ),
        ),
      );

      expect(find.byType(RatingBadge), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsNothing);
    });
  });
}

