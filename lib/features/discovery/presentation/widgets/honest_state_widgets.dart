import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/datasources/places_cache_service.dart';
import '../../domain/entities/place.dart';
import 'place_card.dart';
import 'place_compact_card.dart';

/// Honest error state displaying an honest error message, a retry action,
/// and optional cached results with a clear "Saved X min ago" label.
class HonestErrorWidget extends StatelessWidget {
  final VoidCallback onRetry;
  final CachedSearchResult? cachedResult;
  final bool isHorizontal;
  final void Function(Place)? onPlaceTap;

  const HonestErrorWidget({
    super.key,
    required this.onRetry,
    this.cachedResult,
    this.isHorizontal = false,
    this.onPlaceTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasCachedPlaces = cachedResult != null && cachedResult!.places.isNotEmpty;

    if (isHorizontal) {
      return _buildHorizontalView(context, isDark, hasCachedPlaces);
    }

    return _buildVerticalView(context, isDark, hasCachedPlaces);
  }

  Widget _buildHorizontalView(BuildContext context, bool isDark, bool hasCached) {
    if (hasCached) {
      final places = cachedResult!.places;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accent, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.offline_pin_outlined, size: 14, color: AppColors.accentDark),
                      const SizedBox(width: 4),
                      Text(
                        'Offline • ${cachedResult!.savedAgoLabel}',
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark ? AppColors.accentLight : AppColors.accentDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onRetry();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 14),
                  label: const Text('Retry', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: places.length > 8 ? 8 : places.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final place = places[index];
                return PlaceCompactCard(
                  place: place,
                  onTap: () => onPlaceTap?.call(place),
                );
              },
            ),
          ),
        ],
      );
    }

    // Horizontal without cache
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 36, color: AppColors.statusClosed),
            const SizedBox(height: 8),
            Text(
              "Couldn't load places. Check your connection and retry",
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                onRetry();
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalView(BuildContext context, bool isDark, bool hasCached) {
    if (hasCached) {
      final places = cachedResult!.places;
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          // Offline Banner with Retry
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade700, width: 0.8),
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud_off_rounded, color: Colors.amber, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Couldn't load fresh places.",
                        style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Showing cached results • ${cachedResult!.savedAgoLabel}',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onRetry();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
          ...places.map((place) {
            return PlaceCard(
              place: place,
              onTap: () => onPlaceTap?.call(place),
            );
          }),
        ],
      );
    }

    // Vertical without cache
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.statusClosed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: AppColors.statusClosed,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Couldn't load places. Check your connection and retry",
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your network connection or try again in a few moments.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                onRetry();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Honest empty state when genuine zero results were returned.
class HonestEmptyWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onResetFilter;

  const HonestEmptyWidget({
    super.key,
    this.title = 'No Places Found',
    this.subtitle = "We couldn't find any places matching your criteria in this area. Try adjusting filters or expanding search radius.",
    this.onResetFilter,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.primaryLight : AppColors.primary).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 48,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            if (onResetFilter != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onResetFilter!();
                },
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: const Text('Adjust Search Radius'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

