import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/rating_helper.dart';
import '../../../discovery/domain/entities/place.dart';
import '../providers/user_ratings_provider.dart';

/// Comprehensive Ratings & Reviews widget displaying score breakdown,
/// star distribution, community reviews, and interactive user rating submission.
class RatingBreakdownWidget extends ConsumerWidget {
  final Place place;

  const RatingBreakdownWidget({
    super.key,
    required this.place,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userRatings = ref.watch(userRatingsProvider);
    final userRating = userRatings[place.id];

    // Compute effective rating and reviews taking user input into account
    final baseRating = place.rating ?? RatingHelper.generateRating(place.id, place.name, categoryId: place.categoryId);
    final baseReviews = place.reviewCount ?? RatingHelper.generateReviewCount(place.id, place.name);

    final effectiveRating = userRating != null
        ? double.parse((((baseRating * baseReviews) + userRating.rating) / (baseReviews + 1)).toStringAsFixed(1))
        : baseRating;
    final effectiveReviews = userRating != null ? baseReviews + 1 : baseReviews;

    final distribution = RatingHelper.getRatingDistribution(effectiveRating);
    final sampleReviews = RatingHelper.getSampleReviews(
      place.id,
      place.name,
      categoryId: place.categoryId,
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.star_rounded, color: AppColors.starAmber, size: 24),
                  SizedBox(width: 8),
                  Text('Ratings & Reviews', style: AppTypography.titleMedium),
                ],
              ),
              if (userRating == null)
                TextButton.icon(
                  onPressed: () => _showRatingDialog(context, ref, null),
                  icon: const Icon(Icons.rate_review_outlined, size: 16),
                  label: const Text('Rate Spot'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    textStyle: AppTypography.labelMedium,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Rating Overview: Big Number + Distribution Bars
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Big Score & Stars
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    Text(
                      effectiveRating.toStringAsFixed(1),
                      style: AppTypography.displayLarge.copyWith(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildStarIcons(effectiveRating),
                    const SizedBox(height: 6),
                    Text(
                      '$effectiveReviews reviews',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Right: Distribution Bars (5 to 1)
              Expanded(
                flex: 6,
                child: Column(
                  children: [5, 4, 3, 2, 1].map((star) {
                    final ratio = distribution[star] ?? 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.5),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 22,
                            child: Text(
                              '$star★',
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 6,
                                backgroundColor: isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.starAmber),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 30,
                            child: Text(
                              '${(ratio * 100).toInt()}%',
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 12),

          // User's Rating Banner (if already rated) or Quick Rating Bar
          if (userRating != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.starAmber.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.starAmber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.statusOpen, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Your Rating: ',
                              style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '★ ${userRating.rating.toStringAsFixed(1)}',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.starAmber,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        if (userRating.comment != null && userRating.comment!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            '"${userRating.comment}"',
                            style: AppTypography.bodySmall.copyWith(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: 'Edit your rating',
                    onPressed: () => _showRatingDialog(context, ref, userRating),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.statusClosed),
                    tooltip: 'Remove your rating',
                    onPressed: () async {
                      await ref.read(userRatingsProvider.notifier).removeRating(place.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Rating removed')),
                        );
                      }
                    },
                  ),
                ],
              ),
            )
          else ...[
            Text(
              'How was your visit?',
              style: AppTypography.titleSmall.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = (index + 1).toDouble();
                return InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showRatingDialog(context, ref, null, initialRating: starValue);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Icon(
                      Icons.star_border_rounded,
                      size: 32,
                      color: AppColors.starAmber.withOpacity(0.85),
                    ),
                  ),
                );
              }),
            ),
            const Center(
              child: Text(
                'Tap a star to rate this place',
                style: AppTypography.bodySmall,
              ),
            ),
          ],

          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 12),

          // Community Reviews
          Text(
            'Community Reviews',
            style: AppTypography.titleSmall.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 10),

          ...sampleReviews.map((rev) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDarkVariant : AppColors.surfaceLightVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.primary.withOpacity(0.18),
                          child: Text(
                            (rev['author'] as String).substring(0, 1),
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rev['author'] as String,
                                style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                rev['date'] as String,
                                style: AppTypography.bodySmall.copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.starAmber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 13, color: AppColors.starAmber),
                              const SizedBox(width: 2),
                              Text(
                                (rev['rating'] as double).toStringAsFixed(1),
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.starAmber,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      rev['comment'] as String,
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.thumb_up_alt_outlined, size: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        const SizedBox(width: 4),
                        Text(
                          'Helpful (${rev['helpfulCount']})',
                          style: AppTypography.bodySmall.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStarIcons(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        if (rating >= starIndex) {
          return const Icon(Icons.star_rounded, size: 18, color: AppColors.starAmber);
        } else if (rating >= starIndex - 0.5) {
          return const Icon(Icons.star_half_rounded, size: 18, color: AppColors.starAmber);
        } else {
          return const Icon(Icons.star_outline_rounded, size: 18, color: AppColors.starAmber);
        }
      }),
    );
  }

  void _showRatingDialog(
    BuildContext context,
    WidgetRef ref,
    UserRatingRecord? current, {
    double initialRating = 5.0,
  }) {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    Widget buildModal(BuildContext ctx) => _RatePlaceModal(
          placeId: place.id,
          placeName: place.name,
          initialRating: current?.rating ?? initialRating,
          initialComment: current?.comment,
          onRatingSubmitted: (rating, comment) async {
            await ref.read(userRatingsProvider.notifier).submitRating(
                  placeId: place.id,
                  rating: rating,
                  comment: comment,
                );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thank you! Your rating has been recorded.')),
              );
            }
          },
        );

    if (isDesktop) {
      showDialog(
        context: context,
        useRootNavigator: true,
        builder: (dialogCtx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: buildModal(dialogCtx),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        builder: (sheetCtx) => buildModal(sheetCtx),
      );
    }
  }
}

class _RatePlaceModal extends StatefulWidget {
  final String placeId;
  final String placeName;
  final double initialRating;
  final String? initialComment;
  final Future<void> Function(double rating, String? comment) onRatingSubmitted;

  const _RatePlaceModal({
    required this.placeId,
    required this.placeName,
    required this.initialRating,
    this.initialComment,
    required this.onRatingSubmitted,
  });

  @override
  State<_RatePlaceModal> createState() => _RatePlaceModalState();
}

class _RatePlaceModalState extends State<_RatePlaceModal> {
  late double _rating;
  late TextEditingController _commentController;
  bool _isSubmitting = false;

  final Map<int, String> _ratingLabels = {
    1: 'Needs Improvement',
    2: 'Below Average',
    3: 'Decent Experience',
    4: 'Very Good Spot',
    5: 'Exceptional Discovery!',
  };

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
    _commentController = TextEditingController(text: widget.initialComment ?? '');
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Rate ${widget.placeName}',
            style: AppTypography.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Rating Label Description
          Text(
            _ratingLabels[_rating.toInt()] ?? 'Rate this venue',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.starAmber,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Interactive 5 Stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = (index + 1).toDouble();
              final isFilled = _rating >= starValue;
              return IconButton(
                iconSize: 38,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _rating = starValue);
                },
                icon: Icon(
                  isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                  color: AppColors.starAmber,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Review Comment Text Field
          TextField(
            controller: _commentController,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Share your experience (optional)...',
              filled: true,
              fillColor: isDark ? AppColors.surfaceDarkVariant : AppColors.surfaceLightVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Submit Button
          ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : () async {
                    setState(() => _isSubmitting = true);
                    final nav = Navigator.of(context);
                    await widget.onRatingSubmitted(_rating, _commentController.text);
                    if (mounted) {
                      nav.pop();
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Submit Rating', style: AppTypography.labelLarge),
          ),
        ],
      ),
    );
  }
}
