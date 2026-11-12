import 'package:cached_network_image/cached_network_image.dart';
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
import 'category_illustration_widget.dart';
import 'rating_badge.dart';

/// Venue item card in discovery results list.
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

    final imageUrl = place.photoUrls.isNotEmpty ? place.photoUrls.first : '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: AppDecorations.cardDecoration(context),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppDecorations.borderRadiusMedium,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Image with Category Badge
                ClipRRect(
                  borderRadius: AppDecorations.borderRadiusSmall,
                  child: SizedBox(
                    width: 104,
                    height: 104,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (imageUrl.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            memCacheWidth: 208,
                            placeholder: (_, _) => Container(
                              color: isDark ? AppColors.surfaceDarkVariant : AppColors.surfaceLightVariant,
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            ),
                            errorWidget: (_, _, _) => CategoryIllustrationWidget(
                              category: place.category,
                              placeName: place.name,
                              compact: true,
                            ),
                          )
                        else
                          CategoryIllustrationWidget(
                            category: place.category,
                            placeName: place.name,
                            compact: true,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Details Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Tag & Bookmark
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (isDark ? AppColors.primaryLight : AppColors.primary).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              place.category.name,
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark ? AppColors.primaryLight : AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              ref.read(bookmarksProvider.notifier).toggle(place);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                size: 20,
                                color: isBookmarked ? AppColors.heartRose : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Name
                      Text(
                        place.name,
                        style: AppTypography.titleMedium.copyWith(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Rating & Price Level
                      Row(
                        children: [
                          RatingBadge(
                            rating: displayRating,
                            reviewCount: displayReviewCount,
                          ),
                          const SizedBox(width: 8),
                          if (place.priceLevel != null) ...[
                            Text(
                              Formatters.formatPriceLevel(place.priceLevel),
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.statusOpen,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (place.isOpenNow != null)
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
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),

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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
