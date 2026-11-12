/// Utility class for calculating realistic, deterministic ratings, review counts,
/// distributions, and community review highlights for discovery venues.
class RatingHelper {
  RatingHelper._();

  /// Generates a stable, deterministic rating between 3.8 and 4.9 based on place identity.
  /// Consistent across application restarts, queries, and filters.
  static double generateRating(String id, String name, {String? categoryId}) {
    // Generate deterministic seed using id and name
    final combined = '$id:$name:${categoryId ?? ''}';
    int hash = 0;
    for (int i = 0; i < combined.length; i++) {
      hash = (31 * hash + combined.codeUnitAt(i)) & 0x7FFFFFFF;
    }

    // Category weight boost for top discovery categories
    int boost = 0;
    if (categoryId != null) {
      if (['cafe', 'restaurant', 'attraction', 'resort'].contains(categoryId)) {
        boost = 2;
      }
    }

    // Offset between 0 and 9 -> values between 3.8 and 4.9
    final rawIndex = (hash % 10) + boost;
    final clampedIndex = rawIndex.clamp(0, 11);
    final rating = 3.8 + (clampedIndex * 0.1);

    return double.parse(rating.clamp(3.8, 5.0).toStringAsFixed(1));
  }

  /// Generates a realistic deterministic review count between 24 and 490.
  static int generateReviewCount(String id, String name) {
    final combined = '$name:$id:reviews';
    int hash = 0;
    for (int i = 0; i < combined.length; i++) {
      hash = (37 * hash + combined.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return 24 + (hash % 467);
  }

  /// Calculates realistic percentage distribution across 5, 4, 3, 2, 1 stars.
  static Map<int, double> getRatingDistribution(double rating) {
    final clamped = rating.clamp(1.0, 5.0);

    // Distribution weighting based on overall score
    if (clamped >= 4.7) {
      return {5: 0.78, 4: 0.16, 3: 0.04, 2: 0.01, 1: 0.01};
    } else if (clamped >= 4.4) {
      return {5: 0.68, 4: 0.22, 3: 0.06, 2: 0.03, 1: 0.01};
    } else if (clamped >= 4.0) {
      return {5: 0.52, 4: 0.30, 3: 0.11, 2: 0.05, 1: 0.02};
    } else if (clamped >= 3.5) {
      return {5: 0.38, 4: 0.32, 3: 0.18, 2: 0.08, 1: 0.04};
    } else {
      return {5: 0.25, 4: 0.25, 3: 0.25, 2: 0.15, 1: 0.10};
    }
  }

  /// Returns contextual review highlights for a venue.
  static List<Map<String, dynamic>> getSampleReviews(String id, String name, {String? categoryId}) {
    final combined = '$id:$name';
    int hash = 0;
    for (int i = 0; i < combined.length; i++) {
      hash = (29 * hash + combined.codeUnitAt(i)) & 0x7FFFFFFF;
    }

    final authorPool = [
      'Aarav Sharma',
      'Priya Patel',
      'Rohan Mehta',
      'Sneha Desai',
      'Ananya Verma',
      'Kavita Joshi',
      'Vikram Shah',
      'Rahul Nair',
    ];

    final commentsByCategory = {
      'cafe': [
        'Exceptional coffee and cozy aesthetic. Ideal spot for quiet reading or catching up with friends.',
        'Great ambiance, delicious pastries, and very courteous staff. Will certainly visit again!',
        'Loved the pour-over brew and warm vibes. Fast Wi-Fi and comfortable seating.',
      ],
      'restaurant': [
        'Outstanding flavors, impeccable presentation, and generous portions. Truly memorable experience.',
        'One of the finest spots in town! Fresh ingredients, authentic taste, and quick service.',
        'Great family-friendly dining experience with warm hospitality and great hygiene standards.',
      ],
      'fast_food': [
        'Crispy, fresh, and served piping hot! Perfect quick bite destination with affordable prices.',
        'Super flavorful food and speedy counter service. The quality is consistently fantastic.',
        'Great value for money, clean preparation area, and very satisfying portions.',
      ],
      'hotel': [
        'Pristine rooms, polite concierge, and smooth check-in process. Very comfortable stay.',
        'Strategic location, quiet atmosphere, and excellent room service. Highly recommended!',
        'Clean amenities, lovely breakfast spread, and friendly management throughout.',
      ],
    };

    final defaultComments = [
      'Top-notch service and very pleasant atmosphere. Definitely worth visiting in the area.',
      'Well-maintained, clean environment, and attentive staff. Great experience overall.',
      'Super convenient location with reliable quality. Exceeded expectations!',
    ];

    final commentList = commentsByCategory[categoryId] ?? defaultComments;
    final r1Index = hash % authorPool.length;
    final r2Index = (hash + 3) % authorPool.length;

    return [
      {
        'author': authorPool[r1Index],
        'rating': 5.0,
        'date': '2 days ago',
        'comment': commentList[hash % commentList.length],
        'helpfulCount': (hash % 18) + 3,
      },
      {
        'author': authorPool[r2Index],
        'rating': 4.5,
        'date': '1 week ago',
        'comment': commentList[(hash + 1) % commentList.length],
        'helpfulCount': ((hash + 5) % 12) + 1,
      },
    ];
  }
}
