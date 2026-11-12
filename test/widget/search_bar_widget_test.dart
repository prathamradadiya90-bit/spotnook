import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spot_finder/features/discovery/presentation/widgets/search_bar_widget.dart';

void main() {
  group('SearchBarWidget Widget Tests', () {
    testWidgets('Renders hint text and responds to tap in read-only mode', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              readOnly: true,
              hintText: 'Search places...',
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Search places...'), findsOneWidget);
      await tester.tap(find.byType(SearchBarWidget));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('Interactive mode allows typing and triggers filter tap', (tester) async {
      final controller = TextEditingController();
      bool filterTapped = false;
      String submittedQuery = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              controller: controller,
              readOnly: false,
              onSubmitted: (q) => submittedQuery = q,
              onFilterTap: () => filterTapped = true,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Italian Restaurant');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(submittedQuery, equals('Italian Restaurant'));

      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      expect(filterTapped, isTrue);
    });
  });
}

