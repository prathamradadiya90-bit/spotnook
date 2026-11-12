import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/entities/search_filter.dart';
import '../providers/discovery_providers.dart';

/// Filter and sorting modal sheet for venue discovery.
class FilterBottomSheet extends ConsumerStatefulWidget {
  const FilterBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FilterBottomSheet(),
    );
  }

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  late double _radiusMeters;
  late bool _openNowOnly;
  late double _minRating;
  late String _sortBy;
  late bool _hasPhoneOnly;
  late bool _hasWebsiteOnly;

  @override
  void initState() {
    super.initState();
    final current = ref.read(searchFilterProvider);
    _radiusMeters = current.radiusInMeters;
    _openNowOnly = current.openNowOnly;
    _minRating = current.minRating;
    _sortBy = current.sortBy;
    _hasPhoneOnly = current.hasPhoneOnly;
    _hasWebsiteOnly = current.hasWebsiteOnly;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter & Sort',
                style: AppTypography.titleLarge.copyWith(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              TextButton(
                onPressed: () {
                  final defaultRadius = ref.read(settingsProvider).defaultRadiusMeters;
                  setState(() {
                    _radiusMeters = defaultRadius;
                    _openNowOnly = false;
                    _minRating = 0.0;
                    _sortBy = 'distance';
                    _hasPhoneOnly = false;
                    _hasWebsiteOnly = false;
                  });
                },
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Search Radius
          Text(
            'Distance Radius: ${(_radiusMeters / 1000).toStringAsFixed(0)} km',
            style: AppTypography.titleSmall,
          ),
          Slider(
            value: _radiusMeters,
            min: 1000.0,
            max: 25000.0,
            divisions: 24,
            activeColor: AppColors.primary,
            label: '${(_radiusMeters / 1000).toStringAsFixed(0)} km',
            onChanged: (val) => setState(() => _radiusMeters = val),
          ),
          const SizedBox(height: 12),

          // Minimum Rating
          const Text('Minimum Rating', style: AppTypography.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [0.0, 3.5, 4.0, 4.5].map((rating) {
              final isSelected = _minRating == rating;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(rating == 0.0 ? 'Any' : '★ $rating+'),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _minRating = rating),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Sort By
          const Text('Sort Results By', style: AppTypography.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              {'id': 'distance', 'label': 'Nearest First'},
              {'id': 'rating', 'label': 'Highest Rated'},
              {'id': 'name', 'label': 'Name (A-Z)'},
            ].map((option) {
              final isSelected = _sortBy == option['id'];
              return ChoiceChip(
                label: Text(option['label']!),
                selected: isSelected,
                onSelected: (_) => setState(() => _sortBy = option['id']!),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Toggle Open Now
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Open Now Only', style: AppTypography.bodyLarge),
            value: _openNowOnly,
            activeThumbColor: AppColors.primary,
            onChanged: (val) => setState(() => _openNowOnly = val),
          ),

          const SizedBox(height: 16),

          // Apply Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                final updated = SearchFilter(
                  radiusInMeters: _radiusMeters,
                  openNowOnly: _openNowOnly,
                  minRating: _minRating,
                  sortBy: _sortBy,
                  hasPhoneOnly: _hasPhoneOnly,
                  hasWebsiteOnly: _hasWebsiteOnly,
                  categoryId: ref.read(searchFilterProvider).categoryId,
                );
                ref.read(searchFilterProvider.notifier).state = updated;
                Navigator.of(context).pop();
              },
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}
