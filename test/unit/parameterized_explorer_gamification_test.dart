import 'package:flutter_test/flutter_test.dart';
import 'package:spot_finder/features/saved/presentation/providers/saved_provider.dart';

void main() {
  group('Parameterized Explorer Gamification Boundary Tests', () {
    final testMatrix = [
      // visited, saved, expectedPoints, expectedLevel, expectedTitleSubstring, minProgress, maxProgress
      [0, 0, 0, 1, 'Novice Wanderer', 0.0, 0.0],
      [0, 5, 50, 1, 'Novice Wanderer', 0.49, 0.51],
      [1, 4, 90, 1, 'Novice Wanderer', 0.89, 0.91],
      // Threshold 100 XP -> Level 2
      [2, 0, 100, 2, 'Local Scout', 0.0, 0.01],
      [3, 5, 200, 2, 'Local Scout', 0.65, 0.68],
      [4, 4, 240, 2, 'Local Scout', 0.92, 0.94],
      // Threshold 250 XP -> Level 3
      [5, 0, 250, 3, 'City Pathfinder', 0.0, 0.01],
      [6, 7, 370, 3, 'City Pathfinder', 0.47, 0.49],
      [9, 4, 490, 3, 'City Pathfinder', 0.95, 0.97],
      // Threshold 500 XP -> Level 4
      [10, 0, 500, 4, 'Urban Explorer', 0.0, 0.01],
      [15, 10, 850, 4, 'Urban Explorer', 0.69, 0.71],
      [19, 4, 990, 4, 'Urban Explorer', 0.97, 0.99],
      // Threshold 1000 XP -> Level 5
      [20, 0, 1000, 5, 'Legendary Guide', 0.0, 0.01],
      [30, 20, 1700, 5, 'Legendary Guide', 0.69, 0.71],
      [50, 50, 3000, 5, 'Legendary Guide', 1.0, 1.0],
      [1000, 500, 55000, 5, 'Legendary Guide', 1.0, 1.0],
    ];

    for (final row in testMatrix) {
      final visited = row[0] as int;
      final saved = row[1] as int;
      final expectedPoints = row[2] as int;
      final expectedLevel = row[3] as int;
      final expectedTitle = row[4] as String;
      final minProgress = (row[5] as num).toDouble();
      final maxProgress = (row[6] as num).toDouble();

      test('$visited Visited, $saved Saved -> $expectedPoints XP (Level $expectedLevel $expectedTitle)', () {
        final stats = ExplorerStats.calculate(visited, saved);

        expect(stats.visitedCount, visited);
        expect(stats.bookmarkedCount, saved);
        expect(stats.totalPoints, expectedPoints);
        expect(stats.level, expectedLevel);
        expect(stats.rankTitle, contains(expectedTitle));
        expect(stats.levelProgress, inInclusiveRange(minProgress, maxProgress));
      });
    }

    test('Ensures level progress never goes negative or exceeds 1.0', () {
      final sZero = ExplorerStats.calculate(0, 0);
      expect(sZero.levelProgress, 0.0);

      final sMax = ExplorerStats.calculate(10000, 5000);
      expect(sMax.levelProgress, 1.0);
    });
  });
}

