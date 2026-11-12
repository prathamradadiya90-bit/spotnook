import 'package:flutter_test/flutter_test.dart';
import 'package:spot_finder/features/saved/presentation/providers/saved_provider.dart';

void main() {
  group('ExplorerStats Gamification Unit Tests', () {
    test('Calculates Level 1 Novice Wanderer for initial zero state', () {
      final stats = ExplorerStats.calculate(0, 0);

      expect(stats.totalPoints, 0);
      expect(stats.level, 1);
      expect(stats.rankTitle, contains('Novice Wanderer'));
      expect(stats.levelProgress, 0.0);
    });

    test('Awards 50 XP per visited spot and 10 XP per bookmark', () {
      final stats = ExplorerStats.calculate(2, 3);

      // (2 * 50) + (3 * 10) = 130 XP -> Level 2
      expect(stats.totalPoints, 130);
      expect(stats.level, 2);
      expect(stats.rankTitle, contains('Local Scout'));
      expect(stats.visitedCount, 2);
      expect(stats.bookmarkedCount, 3);
      expect(stats.levelProgress, greaterThan(0.0));
      expect(stats.levelProgress, lessThan(1.0));
    });

    test('Advances to higher ranks with increased exploration', () {
      // 6 visited = 300 XP -> Level 3
      final level3 = ExplorerStats.calculate(6, 0);
      expect(level3.level, 3);
      expect(level3.rankTitle, contains('City Pathfinder'));

      // 12 visited = 600 XP -> Level 4
      final level4 = ExplorerStats.calculate(12, 0);
      expect(level4.level, 4);
      expect(level4.rankTitle, contains('Urban Explorer'));

      // 25 visited = 1250 XP -> Level 5
      final level5 = ExplorerStats.calculate(25, 0);
      expect(level5.level, 5);
      expect(level5.rankTitle, contains('Legendary Guide'));
      expect(level5.levelProgress, greaterThanOrEqualTo(0.0));
    });
  });
}

