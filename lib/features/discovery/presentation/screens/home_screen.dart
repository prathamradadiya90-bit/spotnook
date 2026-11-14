import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../saved/presentation/providers/saved_provider.dart';
import '../providers/discovery_providers.dart';
import '../providers/location_provider.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/category_chip_group.dart';
import '../widgets/honest_state_widgets.dart';
import '../widgets/place_card.dart';
import '../widgets/place_compact_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/shimmer_loader.dart';
import '../widgets/spot_of_the_day_card.dart';
import 'filter_bottom_sheet.dart';
import 'location_picker_sheet.dart';

/// Primary discovery & explore home screen.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locationState = ref.watch(locationProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final nearbyPlacesAsync = ref.watch(nearbyPlacesProvider);
    final popularPlacesAsync = ref.watch(popularPlacesProvider);
    final recentlyViewed = ref.watch(recentlyViewedProvider);

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(nearbyPlacesProvider);
                ref.invalidate(popularPlacesProvider);
              },
              child: CustomScrollView(
            slivers: [
              // Clean Modern Top Bar: Title & Location Pill
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Explore Spots',
                              style: AppTypography.titleLarge.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Discover great places around you',
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Clean Location Selector Pill
                      InkWell(
                        onTap: () => LocationPickerSheet.show(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: (isDark ? AppColors.primaryLight : AppColors.primary).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: (isDark ? AppColors.primaryLight : AppColors.primary).withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 16,
                                color: isDark ? AppColors.primaryLight : AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 140),
                                child: Text(
                                  locationState.location.name,
                                  style: AppTypography.labelMedium.copyWith(
                                    color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Search Bar (Read-only on Home, navigates to /search)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: SearchBarWidget(
                    readOnly: true,
                    hintText: 'Search places in ${locationState.location.name}...',
                    onTap: () => context.push('/search'),
                    onFilterTap: () => FilterBottomSheet.show(context),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),

              // Category Selector
              SliverToBoxAdapter(
                child: CategoryChipGroup(
                  selectedCategoryId: selectedCategory,
                  onCategorySelected: (catId) {
                    ref.read(selectedCategoryProvider.notifier).state = catId;
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Daily Discovery "Spot of the Day"
              popularPlacesAsync.when(
                data: (places) => places.isNotEmpty
                    ? SliverToBoxAdapter(
                        child: SpotOfTheDayCard(
                          places: places,
                          onTap: (place) {
                            context.push('/place/${place.id}', extra: place);
                          },
                        ),
                      )
                    : const SliverToBoxAdapter(child: SizedBox.shrink()),
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Nearby Discovery Horizontal Carousel
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Trending Nearby', style: AppTypography.titleMedium),
                          InkWell(
                            onTap: () => context.go('/map'),
                            child: Row(
                              children: [
                                Text(
                                  'View on Map',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 156,
                      child: nearbyPlacesAsync.when(
                        data: (places) {
                          if (places.isEmpty) {
                            return const Center(child: Text('No nearby spots found.'));
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            scrollDirection: Axis.horizontal,
                            itemCount: places.length > 8 ? 8 : places.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 14),
                            itemBuilder: (context, index) {
                              final place = places[index];
                              return PlaceCompactCard(
                                place: place,
                                onTap: () {
                                  context.push('/place/${place.id}', extra: place);
                                },
                              );
                            },
                          );
                        },
                        loading: () => ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          scrollDirection: Axis.horizontal,
                          itemCount: 3,
                          separatorBuilder: (_, _) => const SizedBox(width: 14),
                          itemBuilder: (_, _) => const ShimmerBox(
                            width: 230,
                            height: 156,
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                          ),
                        ),
                        error: (_, _) => HonestErrorWidget(
                          isHorizontal: true,
                          cachedResult: ref.watch(lastCachedSearchResultProvider),
                          onRetry: () => ref.refresh(nearbyPlacesProvider),
                          onPlaceTap: (place) {
                            context.push('/place/${place.id}', extra: place);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Responsible Native AdMob Banner
              const SliverToBoxAdapter(child: AdBannerWidget()),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // Popular Spots Section Header
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.star_rounded, color: AppColors.starAmber, size: 20),
                      SizedBox(width: 6),
                      Text('Top Rated Discoveries', style: AppTypography.titleMedium),
                    ],
                  ),
                ),
              ),

              // Popular Places List Cards
              popularPlacesAsync.when(
                data: (places) {
                  if (places.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: Text('Discover more spots around your location!')),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final place = places[index];
                        return PlaceCard(
                          place: place,
                          onTap: () {
                            context.push('/place/${place.id}', extra: place);
                          },
                        );
                      },
                      childCount: places.length,
                    ),
                  );
                },
                loading: () => SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, _) => const PlaceCardSkeleton(),
                    childCount: 3,
                  ),
                ),
                error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              // Recently Viewed Section
              if (recentlyViewed.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Text('Recently Viewed', style: AppTypography.titleMedium),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 232,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: recentlyViewed.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        final place = recentlyViewed[index];
                        return PlaceCompactCard(
                          place: place,
                          onTap: () {
                            context.push('/place/${place.id}', extra: place);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    ),
  ),
);
}
}
