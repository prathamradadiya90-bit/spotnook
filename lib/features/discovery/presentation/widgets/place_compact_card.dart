import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/distance_calculator.dart';
import '../../../../core/utils/rating_helper.dart';
import '../../../place_detail/presentation/providers/user_ratings_provider.dart';
import '../../../saved/presentation/providers/saved_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/entities/place.dart';
import 'rating_badge.dart';

/// Compact card used in horizontal discovery carousels.
/// Renders a fast, clean, image-free card with clear typography and quick actions.
class PlaceCompactCard extends ConsumerWidget {
  final Place place;
  final VoidCallback? onTap;
  final double width;

  const PlaceCompactCard({
    super.key,
    required this.place,
    this.onTap,
    this.width = 230,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bookmarks = ref.watch(bookmarksProvider);
    final userRatings = ref.watch(userRatingsProvider);
    final userRating = userRatings[place.id];
    final baseRating = place.rating ?? RatingHelper.generateRating(place.id, place.name, categoryId: place.categoryId);
    final baseReviews = place.reviewCount ?? RatingHelper.generateReviewCount(place.id, place.name);
    final displayRating = userRating != null
        ? double.parse((((baseRating * baseReviews) + userRating.rating) / (baseReviews + 1)).toStringAsFixed(1))
        : baseRating;
    final displayReviewCount = userRating != null ? baseReviews + 1 : baseReviews;
    final isBookmarked = bookmarks.any((p) => p.id == place.id);
    final useMiles = ref.watch(settingsProvider).useMiles;

    return Container(
      width: width,
      decoration: AppDecorations.cardDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppDecorations.borderRadiusMedium,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Category Pill & Bookmark
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.primaryLight : AppColors.primary).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            place.category.icon,
                            size: 13,
                            color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            place.category.name,
                            style: AppTypography.labelSmall.copyWith(
                              color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        ref.read(bookmarksProvider.notifier).toggle(place);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: Icon(
                          isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          size: 18,
                          color: isBookmarked ? AppColors.heartRose : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Name
                Text(
                  place.name,
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Rating & Distance Row
                Row(
                  children: [
                    RatingBadge(
                      rating: displayRating,
                      reviewCount: displayReviewCount,
                      showReviews: false,
                    ),
                    if (place.distanceInMeters != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '•',
                        style: TextStyle(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.near_me_outlined,
                        size: 11,
                        color: isDark ? AppColors.primaryLight : AppColors.primary,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        DistanceCalculator.formatDistance(place.distanceInMeters!, useMiles: useMiles),
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark ? AppColors.primaryLight : AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),

                // Address
                Text(
                  place.formattedAddress,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // Directions Button
                SizedBox(
                  width: double.infinity,
                  height: 32,
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      const NavigationService().launchDirections(
                        latitude: place.latitude,
                        longitude: place.longitude,
                        placeName: place.name,
                      );
                    },
                    icon: const Icon(Icons.near_me_rounded, size: 13),
                    label: const Text('Directions'),
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      textStyle: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
