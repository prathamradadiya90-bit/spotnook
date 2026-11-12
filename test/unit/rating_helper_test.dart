import 'package:flutter_test/flutter_test.dart';
import 'package:spot_finder/core/utils/rating_helper.dart';

void main() {
  group('RatingHelper Unit Tests', () {
    test('Produces deterministic ratings for identical inputs', () {
      final r1 = RatingHelper.generateRating('osm_123', 'Cafe Bliss', categoryId: 'cafe');
      final r2 = RatingHelper.generateRating('osm_123', 'Cafe Bliss', categoryId: 'cafe');
      expect(r1, equals(r2));
    });

    test('Rating stays within realistic bounds [3.8, 5.0]', () {
      for (int i = 0; i < 50; i++) {
        final rating = RatingHelper.generateRating('id_$i', 'Place $i');
        expect(rating, greaterThanOrEqualTo(3.8));
        expect(rating, lessThanOrEqualTo(5.0));
      }
    });

    test('Review count stays within realistic bounds [24, 500]', () {
      for (int i = 0; i < 50; i++) {
        final count = RatingHelper.generateReviewCount('id_$i', 'Place $i');
        expect(count, greaterThanOrEqualTo(24));
        expect(count, lessThanOrEqualTo(500));
      }
    });

    test('Rating distribution returns proportions totaling approximately 1.0', () {
      final dist = RatingHelper.getRatingDistribution(4.6);
      expect(dist.containsKey(5), isTrue);
      expect(dist.containsKey(4), isTrue);
      expect(dist.containsKey(3), isTrue);
      expect(dist.containsKey(2), isTrue);
      expect(dist.containsKey(1), isTrue);

      final total = dist.values.reduce((a, b) => a + b);
      expect(total, closeTo(1.0, 0.05));
    });

    test('Sample reviews produces at least 2 structured reviews', () {
      final reviews = RatingHelper.getSampleReviews('osm_999', 'Gourmet Kitchen', categoryId: 'restaurant');
      expect(reviews.length, greaterThanOrEqualTo(2));
      expect(reviews.first['author'], isNotEmpty);
      expect(reviews.first['rating'], greaterThan(0));
      expect(reviews.first['comment'], isNotEmpty);
    });
  });
}

