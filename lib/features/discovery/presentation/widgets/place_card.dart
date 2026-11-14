import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/distance_calculator.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/rating_helper.dart';
import '../../../place_detail/presentation/providers/user_ratings_provider.dart';
import '../../../saved/presentation/providers/saved_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/entities/place.dart';
import 'rating_badge.dart';

/// Venue item card in discovery results list.
/// Renders a fast, clean, image-free list item prioritizing typography, rating,
/// distance, and quick interactions.
class PlaceCard extends ConsumerWidget {
  final Place place;
  final VoidCallback? onTap;

  const PlaceCard({
    super.key,
    required this.place,
    this.onTap,
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: AppDecorations.cardDecoration(context),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppDecorations.borderRadiusMedium,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Category Icon Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.primaryLight : AppColors.primary).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      place.category.icon,
                      color: isDark ? AppColors.primaryLight : AppColors.primary,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Details Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Venue Name & Open/Closed Badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              place.name,
                              style: AppTypography.titleSmall.copyWith(
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (place.isOpenNow != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (place.isOpenNow! ? AppColors.statusOpen : AppColors.statusClosed).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                place.isOpenNow! ? 'Open' : 'Closed',
                                style: AppTypography.labelSmall.copyWith(
                                  color: place.isOpenNow! ? AppColors.statusOpen : AppColors.statusClosed,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Rating & Category & Price
                      Row(
                        children: [
                          RatingBadge(
                            rating: displayRating,
                            reviewCount: displayReviewCount,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            place.category.name,
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark ? AppColors.primaryLight : AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          if (place.priceLevel != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              '•',
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              Formatters.formatPriceLevel(place.priceLevel),
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.statusOpen,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Distance & Address
                      Row(
                        children: [
                          if (place.distanceInMeters != null) ...[
                            Icon(
                              Icons.near_me_outlined,
                              size: 13,
                              color: isDark ? AppColors.primaryLight : AppColors.primary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              DistanceCalculator.formatDistance(place.distanceInMeters!, useMiles: useMiles),
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark ? AppColors.primaryLight : AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '•',
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              place.formattedAddress,
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                // Bookmark Icon Button
                IconButton(
                  onPressed: () {
                    ref.read(bookmarksProvider.notifier).toggle(place);
                  },
                  icon: Icon(
                    isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    size: 22,
                    color: isBookmarked ? AppColors.heartRose : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  ),
                  splashRadius: 20,
                  tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark place',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
