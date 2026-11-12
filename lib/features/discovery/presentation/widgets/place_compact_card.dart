import 'package:cached_network_image/cached_network_image.dart';
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
import 'category_illustration_widget.dart';
import 'rating_badge.dart';

/// Compact card used in horizontal discovery carousels and map preview overlays.
class PlaceCompactCard extends ConsumerWidget {
  final Place place;
  final VoidCallback? onTap;
  final double width;

  const PlaceCompactCard({
    super.key,
    required this.place,
    this.onTap,
    this.width = 240,
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
      width: width,
      decoration: AppDecorations.cardDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppDecorations.borderRadiusMedium,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image Header with Distance & Bookmark
              SizedBox(
                height: 100,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        memCacheWidth: 480,
                        placeholder: (_, _) => Container(
                          color: isDark ? AppColors.surfaceDarkVariant : AppColors.surfaceLightVariant,
                          child: const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
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
                    // Distance Tag Top-Left
                    if (place.distanceInMeters != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.near_me, size: 11, color: Colors.white),
                              const SizedBox(width: 3),
                              Text(
                                DistanceCalculator.formatDistance(place.distanceInMeters!, useMiles: useMiles),
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Bookmark Top-Right
                    Positioned(
                      top: 8,
                      right: 8,
                      child: InkWell(
                        onTap: () {
                          ref.read(bookmarksProvider.notifier).toggle(place);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            size: 16,
                            color: isBookmarked ? AppColors.heartRose : Colors.white,
                          ),
                        ),
                      ),
                    ),

                    // Open/Closed Tag Bottom-Right of Image
                    if (place.isOpenNow != null)
                      Positioned(
                        bottom: 6,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (place.isOpenNow! ? AppColors.statusOpen : AppColors.statusClosed).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            place.isOpenNow! ? 'Open' : 'Closed',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Details Body
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category & Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: (isDark ? AppColors.primaryLight : AppColors.primary).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            place.category.name,
                            style: AppTypography.labelSmall.copyWith(
                              color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        RatingBadge(
                          rating: displayRating,
                          reviewCount: displayReviewCount,
                          showReviews: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

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
                    const SizedBox(height: 3),

                    // Address
                    Text(
                      place.formattedAddress,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Quick Directions Button
                    SizedBox(
                      width: double.infinity,
                      height: 34,
                      child: FilledButton.tonalIcon(
                        onPressed: () {
                          const NavigationService().launchDirections(
                            latitude: place.latitude,
                            longitude: place.longitude,
                            placeName: place.name,
                          );
                        },
                        icon: const Icon(Icons.near_me_rounded, size: 14),
                        label: const Text('Directions'),
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.zero,
                          textStyle: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w700),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
