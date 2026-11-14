import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../saved/presentation/providers/saved_provider.dart';
import '../../domain/entities/category.dart';
import '../providers/discovery_providers.dart';
import '../providers/location_provider.dart';
import '../widgets/honest_state_widgets.dart';
import '../widgets/place_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/shimmer_loader.dart';
import 'filter_bottom_sheet.dart';

/// Full-screen discovery search interface with instant autocomplete and history.
class SearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller;
  final Debouncer _debouncer = Debouncer(delay: const Duration(milliseconds: 450));
  String _activeQuery = '';

  @override
  void initState() {
    super.initState();
    _activeQuery = (widget.initialQuery ?? '').trim();
    _controller = TextEditingController(text: _activeQuery);
    _controller.addListener(_onControllerTextChanged);
  }

  void _onControllerTextChanged() {
    // Rebuild to update the clear button visibility
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(SearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != oldWidget.initialQuery && widget.initialQuery != null) {
      final newQuery = widget.initialQuery!.trim();
      _controller.text = newQuery;
      _debouncer.cancel();
      setState(() {
        _activeQuery = newQuery;
      });
      if (newQuery.isNotEmpty) {
        ref.read(recentSearchesProvider.notifier).add(newQuery);
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerTextChanged);
    _controller.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debouncer.run(() {
      if (!mounted) return;
      setState(() {
        _activeQuery = query.trim();
      });
      if (_activeQuery.isNotEmpty) {
        ref.read(recentSearchesProvider.notifier).add(_activeQuery);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final location = ref.watch(locationProvider).location;
    final recentSearches = ref.watch(recentSearchesProvider);
    final searchResultsAsync = _activeQuery.isNotEmpty
        ? ref.watch(searchResultsProvider(_activeQuery))
        : null;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: SearchBarWidget(
            controller: _controller,
            hintText: 'Search places in ${location.name}...',
            autoFocus: _activeQuery.isEmpty,
            onChanged: _onQueryChanged,
            onSubmitted: (val) {
              _onQueryChanged(val);
              if (val.trim().isNotEmpty) {
                ref.read(recentSearchesProvider.notifier).add(val.trim());
              }
            },
            onClear: () {
              _debouncer.cancel();
              setState(() => _activeQuery = '');
            },
            onFilterTap: () => FilterBottomSheet.show(context),
          ),
        ),
      ),
      body: _activeQuery.isEmpty
          ? _buildSearchSuggestions(context, recentSearches, isDark)
          : searchResultsAsync!.when(
              data: (places) {
                if (places.isEmpty) {
                  return HonestEmptyWidget(
                    title: 'No Places Found',
                    subtitle: 'We couldn\'t find any spots matching "$_activeQuery". Try checking spelling or expanding your radius.',
                    onResetFilter: () => FilterBottomSheet.show(context),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: places.length,
                  itemBuilder: (context, index) {
                    final place = places[index];
                    return PlaceCard(
                      place: place,
                      onTap: () {
                        context.push('/place/${place.id}', extra: place);
                      },
                    );
                  },
                );
              },
              loading: () => ListView.builder(
                itemCount: 6,
                itemBuilder: (_, _) => const PlaceCardSkeleton(),
              ),
              error: (err, _) => HonestErrorWidget(
                cachedResult: ref.watch(lastCachedSearchResultProvider),
                onRetry: () => ref.refresh(searchResultsProvider(_activeQuery)),
                onPlaceTap: (place) {
                  context.push('/place/${place.id}', extra: place);
                },
              ),
            ),
    );
  }

  Widget _buildSearchSuggestions(
    BuildContext context,
    List<String> recentSearches,
    bool isDark,
  ) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Category Shortcuts
        Text(
          'Popular Categories',
          style: AppTypography.titleSmall.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PlaceCategory.standardCategories.where((c) => c.id != 'all').map((cat) {
            return ActionChip(
              avatar: Icon(cat.icon, size: 16, color: AppColors.primary),
              label: Text(cat.name, style: AppTypography.labelSmall),
              onPressed: () {
                _controller.text = cat.name;
                _debouncer.cancel();
                setState(() => _activeQuery = cat.name);
                ref.read(recentSearchesProvider.notifier).add(cat.name);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 28),

        // Recent Searches
        if (recentSearches.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: AppTypography.titleSmall.copyWith(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              TextButton(
                onPressed: () => ref.read(recentSearchesProvider.notifier).clear(),
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...recentSearches.map((query) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history_rounded, size: 20),
              title: Text(query, style: AppTypography.bodyMedium),
              trailing: IconButton(
                icon: const Icon(Icons.close_rounded, size: 16),
                onPressed: () => ref.read(recentSearchesProvider.notifier).remove(query),
              ),
              onTap: () {
                _controller.text = query;
                _debouncer.cancel();
                setState(() => _activeQuery = query);
              },
            );
          }),
        ],
      ],
    );
  }
}
