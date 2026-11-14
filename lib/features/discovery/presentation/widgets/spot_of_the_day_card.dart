import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/distance_calculator.dart';
import '../../../../core/utils/rating_helper.dart';
import '../../domain/entities/place.dart';

/// "Spot of the Day" Feature Card.
/// Rotates deterministically every 24 hours to give users a fresh, exciting discovery
/// every single day they open the application.
class SpotOfTheDayCard extends StatelessWidget {
  final List<Place> places;
  final ValueChanged<Place> onTap;

  const SpotOfTheDayCard({
    super.key,
    required this.places,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) return const SizedBox.shrink();

    // Deterministic rotation based on year & day of year
    final now = DateTime.now();
    final daySeed = now.year * 366 + now.day;
    final spot = places[daySeed % places.length];

    final rating = spot.rating ?? RatingHelper.generateRating(spot.id, spot.name, categoryId: spot.categoryId);
    final reviewCount = spot.reviewCount ?? RatingHelper.generateReviewCount(spot.id, spot.name);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: AppDecorations.borderRadiusLarge,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF312E81),
            Color(0xFF4F46E5),
            Color(0xFF7C3AED),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: AppDecorations.borderRadiusLarge,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onTap(spot),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Badge Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('✨', style: TextStyle(fontSize: 12)),
                                SizedBox(width: 5),
                                Text(
                                  "TODAY'S HIDDEN GEM",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Rating Chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, color: AppColors.starAmber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '($reviewCount)',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Place Name
                      Text(
                        spot.name,
                        style: AppTypography.titleLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Category and distance
                      Row(
                        children: [
                          Text(
                            spot.category.name,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (spot.distanceInMeters != null) ...[
                            Text(
                              ' • ',
                              style: TextStyle(color: Colors.white.withOpacity(0.6)),
                            ),
                            Icon(
                              Icons.near_me_rounded,
                              size: 13,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              DistanceCalculator.formatDistance(spot.distanceInMeters!),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Action Button
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Explore Today's Pick",
                                style: TextStyle(
                                  color: Color(0xFF134E5E),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: Color(0xFF134E5E),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
        ),
      ),
    );
  }
}
