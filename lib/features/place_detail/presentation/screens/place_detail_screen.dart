import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' hide DistanceCalculator;
import '../../../../core/config/app_config.dart';
import '../../../../core/services/ad_service.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/distance_calculator.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/rating_helper.dart';
import '../../../discovery/domain/entities/place.dart';
import '../../../discovery/presentation/widgets/ad_banner_widget.dart';
import '../../../discovery/presentation/widgets/category_illustration_widget.dart';
import '../../../discovery/presentation/widgets/rating_badge.dart';
import '../../../saved/presentation/providers/saved_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/user_ratings_provider.dart';
import '../widgets/action_buttons_row.dart';
import '../widgets/opening_hours_table.dart';
import '../widgets/place_attribution_card.dart';
import '../widgets/rating_breakdown_widget.dart';

/// Full venue details inspection screen.
class PlaceDetailScreen extends ConsumerStatefulWidget {
  final Place place;

  const PlaceDetailScreen({super.key, required this.place});

  @override
  ConsumerState<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends ConsumerState<PlaceDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Record recently viewed and trigger AdMob frequency cap check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recentlyViewedProvider.notifier).add(widget.place);
      AdService.instance.recordPlaceViewAndMaybeShowInterstitial();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final place = widget.place;
    final useMiles = ref.watch(settingsProvider).useMiles;
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
    final hasPhone = place.phoneNumber != null && place.phoneNumber!.trim().isNotEmpty;
    final imageUrl = place.primaryImageUrl;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Sliver App Bar
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black45,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Builder(
                  builder: (iconContext) => CircleAvatar(
                    backgroundColor: Colors.black45,
                    child: IconButton(
                      icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                      onPressed: () {
                        final box = iconContext.findRenderObject() as RenderBox?;
                        final origin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;
                        const NavigationService().sharePlace(place, sharePositionOrigin: origin);
                      },
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 800,
                      placeholder: (_, _) => Container(color: AppColors.surfaceDarkVariant),
                      errorWidget: (_, _, _) => CategoryIllustrationWidget(
                        category: place.category,
                        placeName: place.name,
                        compact: false,
                      ),
                    )
                  else
                    CategoryIllustrationWidget(
                      category: place.category,
                      placeName: place.name,
                      compact: false,
                    ),
                  // Dark Gradient Overlay at bottom of hero
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                        stops: [0.6, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Venue Content Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Pill & Price Level
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.primaryLight : AppColors.primary).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          place.category.name,
                          style: AppTypography.labelMedium.copyWith(
                            color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (place.priceLevel != null)
                        Text(
                          Formatters.formatPriceLevel(place.priceLevel),
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.statusOpen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Venue Name
                  Text(
                    place.name,
                    style: AppTypography.displayLarge.copyWith(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Rating, Reviews & Distance
                  Row(
                    children: [
                      RatingBadge(
                        rating: displayRating,
                        reviewCount: displayReviewCount,
                      ),
                      const SizedBox(width: 10),
                      if (place.distanceInMeters != null) ...[
                        Icon(
                          Icons.near_me_rounded,
                          size: 16,
                          color: isDark ? AppColors.primaryLight : AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DistanceCalculator.formatDistance(place.distanceInMeters!, useMiles: useMiles),
                          style: AppTypography.titleSmall.copyWith(
                            color: isDark ? AppColors.primaryLight : AppColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Quick Action Buttons
                  ActionButtonsRow(place: place),
                  const SizedBox(height: 18),

                  // Explorer Passport Check-in Stamp
                  Consumer(
                    builder: (context, ref, _) {
                      final isVisited = ref.watch(visitedPlacesProvider).any((p) => p.id == place.id);
                      return InkWell(
                        onTap: () async {
                          final wasVisited = await ref.read(visitedPlacesProvider.notifier).toggle(place);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  wasVisited
                                      ? '🎉 Stamped in your Explorer Passport! (+50 XP)'
                                      : 'Removed from visited passport stamps',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        borderRadius: AppDecorations.borderRadiusMedium,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isVisited
                                ? AppColors.statusOpen.withOpacity(0.12)
                                : (isDark ? AppColors.surfaceDarkVariant : AppColors.surfaceLightVariant),
                            borderRadius: AppDecorations.borderRadiusMedium,
                            border: Border.all(
                              color: isVisited
                                  ? AppColors.statusOpen.withOpacity(0.5)
                                  : Colors.grey.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isVisited
                                      ? AppColors.statusOpen
                                      : Colors.grey.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isVisited ? Icons.check_rounded : Icons.add_location_alt_rounded,
                                  color: isVisited ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isVisited ? 'Visited • Explorer Passport Stamped' : 'Mark as Visited',
                                      style: AppTypography.titleSmall.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: isVisited
                                            ? AppColors.statusOpen
                                            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isVisited ? 'You visited this venue! (+50 XP earned)' : 'Tap to stamp your passport & earn +50 XP',
                                      style: AppTypography.bodySmall.copyWith(
                                        fontSize: 11,
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isVisited)
                                const Text('🏅', style: TextStyle(fontSize: 20)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Location & Address Section
                  const Text('Location & Address', style: AppTypography.titleMedium),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: AppDecorations.cardDecoration(context),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            place.formattedAddress,
                            style: AppTypography.bodyMedium,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          tooltip: 'Copy address',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: place.formattedAddress));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Address copied to clipboard!')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Interactive Mini Map
                  ClipRRect(
                    borderRadius: AppDecorations.borderRadiusMedium,
                    child: SizedBox(
                      height: 160,
                      child: Stack(
                        children: [
                          FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(place.latitude, place.longitude),
                              initialZoom: 15.0,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: AppConfig.mapTileUrl,
                                userAgentPackageName: 'com.spotnook.app',
                                tileBuilder: isDark
                                    ? (context, tileWidget, tile) {
                                        return ColorFiltered(
                                          colorFilter: const ColorFilter.matrix(<double>[
                                            -0.85, 0, 0, 0, 255,
                                            0, -0.85, 0, 0, 255,
                                            0, 0, -0.85, 0, 255,
                                            0, 0, 0, 1, 0,
                                          ]),
                                          child: tileWidget,
                                        );
                                      }
                                    : null,
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(place.latitude, place.longitude),
                                    width: 36,
                                    height: 36,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: Icon(place.category.icon, color: Colors.white, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                const NavigationService().launchDirections(
                                  latitude: place.latitude,
                                  longitude: place.longitude,
                                  placeName: place.name,
                                );
                              },
                              icon: const Icon(Icons.directions, size: 14),
                              label: const Text('Navigate'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                textStyle: AppTypography.labelSmall,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Opening Hours
                  OpeningHoursTable(
                    openingHours: place.openingHours,
                    isOpenNow: place.isOpenNow,
                  ),
                  const SizedBox(height: 20),

                  // Amenities & Features
                  if (place.amenities.isNotEmpty) ...[
                    const Text('Amenities & Features', style: AppTypography.titleMedium),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: place.amenities.map((amenity) {
                        return Chip(
                          avatar: const Icon(Icons.check_circle_outline, size: 16, color: AppColors.statusOpen),
                          label: Text(amenity, style: AppTypography.bodySmall),
                          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                          side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Ratings & Reviews Breakdown
                  RatingBreakdownWidget(place: place),
                  const SizedBox(height: 20),

                  // Verified Place Attribution Card
                  PlaceAttributionCard(place: place),
                  const SizedBox(height: 20),

                  // Responsible AdMob Banner (SPONSORED)
                  const AdBannerWidget(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1.0,
            ),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: isBookmarked ? AppColors.heartRose : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              ),
              tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark place',
              onPressed: () async {
                HapticFeedback.selectionClick();
                final saved = await ref.read(bookmarksProvider.notifier).toggle(place);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(saved ? 'Saved to favorites!' : 'Removed from favorites'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            if (hasPhone) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.call_rounded, color: AppColors.statusOpen),
                tooltip: 'Call venue',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  const NavigationService().launchDialer(place.phoneNumber!);
                },
              ),
            ],
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  const NavigationService().launchDirections(
                    latitude: place.latitude,
                    longitude: place.longitude,
                    placeName: place.name,
                  );
                },
                icon: const Icon(Icons.directions_rounded),
                label: const Text('Get Directions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
