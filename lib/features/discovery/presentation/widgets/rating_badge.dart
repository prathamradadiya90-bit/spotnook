import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Reusable star rating indicator with review count.
class RatingBadge extends StatelessWidget {
  final double? rating;
  final int? reviewCount;
  final bool showReviews;

  const RatingBadge({
    super.key,
    required this.rating,
    this.reviewCount,
    this.showReviews = true,
  });

  @override
  Widget build(BuildContext context) {
    if (rating == null || rating! <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.starAmber.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            size: 15,
            color: AppColors.starAmber,
          ),
          const SizedBox(width: 3),
          Text(
            rating!.toStringAsFixed(1),
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.starAmber,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (showReviews && reviewCount != null && reviewCount! > 0) ...[
            const SizedBox(width: 3),
            Text(
              '($reviewCount)',
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

