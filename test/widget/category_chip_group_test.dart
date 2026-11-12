import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spot_finder/features/discovery/presentation/widgets/category_chip_group.dart';

void main() {
  group('CategoryChipGroup Widget Tests', () {
    testWidgets('Displays categories and responds to tap selection', (tester) async {
      String selectedCat = 'all';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryChipGroup(
              selectedCategoryId: selectedCat,
              onCategorySelected: (catId) {
                selectedCat = catId;
              },
            ),
          ),
        ),
      );

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Cafes'), findsOneWidget);
      expect(find.text('Restaurants'), findsOneWidget);

      await tester.tap(find.text('Cafes'));
      await tester.pumpAndSettle();

      expect(selectedCat, equals('cafe'));
    });
  });
}

