import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../discovery/domain/entities/category.dart';
import '../../../discovery/domain/entities/place.dart';
import '../../../discovery/presentation/widgets/explorer_progress_card.dart';
import '../../../discovery/presentation/widgets/place_card.dart';
import '../providers/saved_provider.dart';

/// Saved venues / favorites management screen.
class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  int _selectedTabIndex = 0; // 0: Bookmarks, 1: Visited Passport
  String _selectedCategoryFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bookmarks = ref.watch(bookmarksProvider);
    final visited = ref.watch(visitedPlacesProvider);

    final currentList = _selectedTabIndex == 0 ? bookmarks : visited;
    final filteredList = _selectedCategoryFilter == 'all'
        ? currentList
        : currentList.where((p) => p.categoryId == _selectedCategoryFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedTabIndex == 0 ? 'Saved Places' : 'Explorer Passport'),
        actions: [
          if (currentList.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear all',
              onPressed: () {
                _confirmClearAll(context);
              },
            ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: CustomScrollView(
            slivers: [
              // Gamified City Explorer Progress Card
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: ExplorerProgressCard(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Segmented Tab Selector (Bookmarks vs Visited Passport)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SegmentedButton<int>(
                    segments: [
                      ButtonSegment(
                        value: 0,
                        icon: const Icon(Icons.bookmark_rounded, size: 18),
                        label: Text('Bookmarks (${bookmarks.length})'),
                      ),
                      ButtonSegment(
                        value: 1,
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: Text('Visited (${visited.length})'),
                      ),
                    ],
                    selected: {_selectedTabIndex},
                    onSelectionChanged: (val) {
                      setState(() {
                        _selectedTabIndex = val.first;
                        _selectedCategoryFilter = 'all';
                      });
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // Category Filter Pills
              if (currentList.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ChoiceChip(
                            label: Text('All (${currentList.length})'),
                            selected: _selectedCategoryFilter == 'all',
                            onSelected: (_) => setState(() => _selectedCategoryFilter = 'all'),
                          ),
                          const SizedBox(width: 8),
                          ..._buildCategoryChips(currentList),
                        ],
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // Empty State
              if (currentList.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(context, isDark),
                )
              else
                // Cards List
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final place = filteredList[index];
                      return Dismissible(
                        key: ValueKey('${_selectedTabIndex}_${place.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: AppColors.statusClosed,
                          child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                        ),
                        onDismissed: (_) {
                          if (_selectedTabIndex == 0) {
                            ref.read(bookmarksProvider.notifier).remove(place.id);
                          } else {
                            ref.read(visitedPlacesProvider.notifier).toggle(place);
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Removed ${place.name}'),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () {
                                  if (_selectedTabIndex == 0) {
                                    ref.read(bookmarksProvider.notifier).toggle(place);
                                  } else {
                                    ref.read(visitedPlacesProvider.notifier).toggle(place);
                                  }
                                },
                              ),
                            ),
                          );
                        },
                        child: PlaceCard(
                          place: place,
                          onTap: () {
                            context.push('/place/${place.id}', extra: place);
                          },
                        ),
                      );
                    },
                    childCount: filteredList.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCategoryChips(List<Place> bookmarks) {
    final categoryIds = bookmarks.map((p) => p.categoryId).toSet().toList();
    return categoryIds.map((catId) {
      final count = bookmarks.where((p) => p.categoryId == catId).length;
      final category = PlaceCategory.findById(catId);
      final isSelected = _selectedCategoryFilter == catId;

      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text('${category.name} ($count)'),
          selected: isSelected,
          onSelected: (_) => setState(() => _selectedCategoryFilter = catId),
        ),
      );
    }).toList();
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    final isVisitedTab = _selectedTabIndex == 1;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.primaryLight : AppColors.primary).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isVisitedTab ? Icons.verified_outlined : Icons.bookmark_border_rounded,
                size: 64,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isVisitedTab ? 'No Visited Places Yet' : 'No Saved Places Yet',
              style: AppTypography.titleLarge.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isVisitedTab
                  ? "Mark places you've visited on their details page to stamp your explorer passport and earn XP!"
                  : 'Save your favorite cafes, restaurants, and spots to access them quickly anytime.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Discover Places'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearAll(BuildContext context) {
    final isVisitedTab = _selectedTabIndex == 1;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isVisitedTab ? 'Clear Visited Passport?' : 'Clear All Bookmarks?'),
        content: Text(
          isVisitedTab
              ? 'This will clear all visited passport stamps from your device.'
              : 'This will remove all saved places from your device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusClosed),
            onPressed: () {
              if (isVisitedTab) {
                ref.read(visitedPlacesProvider.notifier).clearAll();
              } else {
                ref.read(bookmarksProvider.notifier).clearAll();
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
