import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/debouncer.dart';
import '../../domain/entities/location_info.dart';
import '../providers/discovery_providers.dart';
import '../providers/location_provider.dart';
import '../../../../core/services/location_service.dart';
import '../widgets/location_disclosure_dialog.dart';

/// Modal bottom sheet allowing users to select or search their active discovery location.
class LocationPickerSheet extends ConsumerStatefulWidget {
  const LocationPickerSheet({super.key});

  static Future<LocationInfo?> show(BuildContext context) {
    return showModalBottomSheet<LocationInfo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LocationPickerSheet(),
    );
  }

  @override
  ConsumerState<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends ConsumerState<LocationPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _debouncer = Debouncer(delay: const Duration(milliseconds: 450));
  CancelToken? _cancelToken;
  List<LocationInfo> _searchResults = [];
  bool _isSearching = false;

  static const List<Map<String, dynamic>> _popularCities = [
    {'name': 'Surat', 'lat': 21.1702, 'lon': 72.8311, 'addr': 'Surat, Gujarat, India'},
    {'name': 'Ahmedabad', 'lat': 23.0225, 'lon': 72.5714, 'addr': 'Ahmedabad, Gujarat, India'},
    {'name': 'Mumbai', 'lat': 19.0760, 'lon': 72.8777, 'addr': 'Mumbai, Maharashtra, India'},
    {'name': 'Delhi', 'lat': 28.6139, 'lon': 77.2090, 'addr': 'New Delhi, Delhi, India'},
    {'name': 'Bengaluru', 'lat': 12.9716, 'lon': 77.5946, 'addr': 'Bengaluru, Karnataka, India'},
    {'name': 'London', 'lat': 51.5074, 'lon': -0.1278, 'addr': 'London, United Kingdom'},
    {'name': 'New York', 'lat': 40.7128, 'lon': -74.0060, 'addr': 'New York, NY, USA'},
  ];

  @override
  void dispose() {
    _cancelToken?.cancel('LocationPickerSheet disposed');
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _cancelToken?.cancel('Query changed');
    _cancelToken = CancelToken();

    if (query.trim().isEmpty) {
      _debouncer.cancel();
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final activeToken = _cancelToken;
    _debouncer.run(() async {
      try {
        final repo = ref.read(placesRepositoryProvider);
        final results = await repo.searchLocations(query);
        if (mounted && activeToken == _cancelToken && !(activeToken?.isCancelled ?? false)) {
          setState(() {
            _searchResults = results;
            _isSearching = false;
          });
        }
      } catch (_) {
        if (mounted && activeToken == _cancelToken) {
          setState(() => _isSearching = false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLocation = ref.watch(locationProvider).location;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Choose Location',
                  style: AppTypography.titleLarge.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search city, area, or neighborhood...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // GPS Location Action Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: InkWell(
              onTap: () async {
                final navigator = Navigator.of(context);
                final locationService = ref.read(locationServiceProvider);
                final currentPerm = await locationService.checkPermission();
                if (!context.mounted) return;
                if (currentPerm != LocationPermissionResult.granted) {
                  final proceed = await LocationDisclosureDialog.show(context);
                  if (!proceed || !context.mounted) return;
                }
                final success = await ref.read(locationProvider.notifier).requestGpsLocation();
                if (context.mounted && success) {
                  navigator.pop(ref.read(locationProvider).location);
                }
              },
              borderRadius: AppDecorations.borderRadiusMedium,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.primaryLight : AppColors.primary).withOpacity(0.08),
                  borderRadius: AppDecorations.borderRadiusMedium,
                  border: Border.all(
                    color: (isDark ? AppColors.primaryLight : AppColors.primary).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.primaryLight : AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Use Current GPS Location',
                            style: AppTypography.titleSmall.copyWith(
                              color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Foreground location only • Tap to detect',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 20),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Results or Popular Cities
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isNotEmpty
                    ? ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (context, index) {
                          final loc = _searchResults[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                            title: Text(loc.name, style: AppTypography.titleSmall),
                            subtitle: Text(
                              loc.formattedAddress,
                              style: AppTypography.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              ref.read(locationProvider.notifier).setLocation(loc);
                              Navigator.of(context).pop(loc);
                            },
                          );
                        },
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          Text(
                            'Popular Cities',
                            style: AppTypography.labelLarge.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _popularCities.map((city) {
                              final isSelected = city['name'] == currentLocation.name;
                              return ChoiceChip(
                                label: Text(city['name'] as String),
                                selected: isSelected,
                                onSelected: (_) {
                                  final selectedLoc = LocationInfo(
                                    latitude: city['lat'] as double,
                                    longitude: city['lon'] as double,
                                    name: city['name'] as String,
                                    formattedAddress: city['addr'] as String,
                                    isFromGps: false,
                                  );
                                  ref.read(locationProvider.notifier).setLocation(selectedLoc);
                                  Navigator.of(context).pop(selectedLoc);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
