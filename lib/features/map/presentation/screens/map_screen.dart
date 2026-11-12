import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../discovery/domain/entities/place.dart';
import '../../../discovery/presentation/providers/discovery_providers.dart';
import '../../../discovery/presentation/providers/location_provider.dart';
import '../../../discovery/presentation/screens/filter_bottom_sheet.dart';
import '../../../discovery/presentation/screens/location_picker_sheet.dart';
import '../../../discovery/presentation/widgets/category_chip_group.dart';
import '../../../discovery/presentation/widgets/location_disclosure_dialog.dart';
import '../../../../core/services/location_service.dart';
import '../widgets/custom_map_marker.dart';
import '../widgets/map_preview_sheet.dart';
import '../widgets/search_this_area_button.dart';

/// Interactive full-screen map experience with place markers, preview sheet, and area search.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _PlaceCluster {
  final List<Place> places;
  final LatLng center;

  const _PlaceCluster({required this.places, required this.center});
}

class _MapScreenState extends ConsumerState<MapScreen> with TickerProviderStateMixin {
  late final MapController _mapController;
  AnimationController? _moveAnimationController;
  LatLng? _lastSearchCenter;
  LatLng? _currentMapCenter;
  double _currentZoom = 14.0;
  bool _showSearchThisArea = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _moveAnimationController?.stop();
    _moveAnimationController?.dispose();
    _moveAnimationController = null;
    _mapController.dispose();
    super.dispose();
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    _moveAnimationController?.stop();
    _moveAnimationController?.dispose();
    _moveAnimationController = null;

    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: destZoom,
    );

    final controller = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
    _moveAnimationController = controller;

    final animation = CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      if (!mounted) return;
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        if (_moveAnimationController == controller) {
          _moveAnimationController = null;
        }
        controller.dispose();
      }
    });

    controller.forward();
  }

  void _onMapPositionChanged(MapCamera camera, bool hasGesture) {
    _currentZoom = camera.zoom;
    if (hasGesture) {
      _currentMapCenter = camera.center;
      if (_lastSearchCenter != null) {
        final distance = const Distance().as(
          LengthUnit.Meter,
          _lastSearchCenter!,
          camera.center,
        );
        if (distance > 500 && !_showSearchThisArea) {
          setState(() => _showSearchThisArea = true);
        }
      }
    }
  }

  void _searchThisArea() {
    HapticFeedback.lightImpact();
    if (_currentMapCenter != null) {
      ref.read(locationProvider.notifier).selectCoordinate(
            _currentMapCenter!.latitude,
            _currentMapCenter!.longitude,
          );
      _lastSearchCenter = _currentMapCenter;
      setState(() => _showSearchThisArea = false);
      _animatedMapMove(_currentMapCenter!, 14.5);
    }
  }

  void _recenterOnUser() async {
    HapticFeedback.lightImpact();
    final locationService = ref.read(locationServiceProvider);
    final currentPerm = await locationService.checkPermission();
    if (!mounted) return;
    if (currentPerm != LocationPermissionResult.granted) {
      final proceed = await LocationDisclosureDialog.show(context);
      if (!proceed || !mounted) return;
    }
    await ref.read(locationProvider.notifier).requestGpsLocation();
    final location = ref.read(locationProvider).location;
    final target = LatLng(location.latitude, location.longitude);
    _animatedMapMove(target, 14.5);
    _lastSearchCenter = target;
    setState(() => _showSearchThisArea = false);
  }

  List<_PlaceCluster> _clusterPlaces(List<Place> places, double clusterRadiusDeg) {
    final clusters = <_PlaceCluster>[];
    final assigned = <int>{};

    for (int i = 0; i < places.length; i++) {
      if (assigned.contains(i)) continue;
      final place = places[i];
      final group = <Place>[place];
      assigned.add(i);

      for (int j = i + 1; j < places.length; j++) {
        if (assigned.contains(j)) continue;
        final other = places[j];
        final latDiff = (place.latitude - other.latitude).abs();
        final lonDiff = (place.longitude - other.longitude).abs();
        if (latDiff < clusterRadiusDeg && lonDiff < clusterRadiusDeg) {
          group.add(other);
          assigned.add(j);
        }
      }

      final avgLat = group.fold<double>(0.0, (sum, p) => sum + p.latitude) / group.length;
      final avgLon = group.fold<double>(0.0, (sum, p) => sum + p.longitude) / group.length;
      clusters.add(_PlaceCluster(places: group, center: LatLng(avgLat, avgLon)));
    }
    return clusters;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locationState = ref.watch(locationProvider);
    final placesAsync = ref.watch(nearbyPlacesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedPlace = ref.watch(selectedMapPlaceProvider);

    final initialCenter = LatLng(
      locationState.location.latitude,
      locationState.location.longitude,
    );
    _lastSearchCenter ??= initialCenter;

    return Scaffold(
      body: Stack(
        children: [
          // FlutterMap Tile Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 14.0,
              minZoom: 3.0,
              maxZoom: 18.0,
              onPositionChanged: _onMapPositionChanged,
              onTap: (_, _) {
                if (selectedPlace != null) {
                  ref.read(selectedMapPlaceProvider.notifier).state = null;
                }
              },
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

              // Markers Layer with Clustering at lower zoom levels
              placesAsync.when(
                data: (places) {
                  final markers = <Marker>[];

                  if (_currentZoom < 13.0 && places.length > 6) {
                    final clusters = _clusterPlaces(places, 0.025);
                    for (final cluster in clusters) {
                      if (cluster.places.length == 1) {
                        final place = cluster.places.first;
                        final isSelected = selectedPlace?.id == place.id;
                        markers.add(
                          Marker(
                            point: LatLng(place.latitude, place.longitude),
                            width: isSelected ? 48 : 38,
                            height: isSelected ? 56 : 46,
                            alignment: Alignment.topCenter,
                            child: CustomMapMarker(
                              place: place,
                              isSelected: isSelected,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                ref.read(selectedMapPlaceProvider.notifier).state = place;
                              },
                            ),
                          ),
                        );
                      } else {
                        // Multi-place cluster badge
                        markers.add(
                          Marker(
                            point: cluster.center,
                            width: 44,
                            height: 44,
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _animatedMapMove(cluster.center, 14.5);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                ),
                                child: Center(
                                  child: Text(
                                    '${cluster.places.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                    }
                  } else {
                    for (final place in places) {
                      final isSelected = selectedPlace?.id == place.id;
                      markers.add(
                        Marker(
                          point: LatLng(place.latitude, place.longitude),
                          width: isSelected ? 48 : 38,
                          height: isSelected ? 56 : 46,
                          alignment: Alignment.topCenter,
                          child: CustomMapMarker(
                            place: place,
                            isSelected: isSelected,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              ref.read(selectedMapPlaceProvider.notifier).state = place;
                            },
                          ),
                        ),
                      );
                    }
                  }

                  // Add active search center marker
                  markers.add(
                    Marker(
                      point: initialCenter,
                      width: 22,
                      height: 22,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  );

                  return MarkerLayer(markers: markers);
                },
                loading: () => const MarkerLayer(markers: []),
                error: (_, _) => const MarkerLayer(markers: []),
              ),

              // OSM Legal Attribution
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),

          // Top Floating Bar (Category Pills & Search Area)
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // Active Location Pill
                      Expanded(
                        child: InkWell(
                          onTap: () => LocationPickerSheet.show(context),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    locationState.location.name,
                                    style: AppTypography.titleSmall.copyWith(
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down_rounded, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Filter Button
                      InkWell(
                        onTap: () => FilterBottomSheet.show(context),
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                          ),
                          child: const Icon(Icons.tune_rounded, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),

                // Category Pills
                CategoryChipGroup(
                  selectedCategoryId: selectedCategory,
                  onCategorySelected: (catId) {
                    ref.read(selectedCategoryProvider.notifier).state = catId;
                  },
                ),
                const SizedBox(height: 8),

                // "Search this area" Button
                SearchThisAreaButton(
                  isVisible: _showSearchThisArea,
                  onTap: _searchThisArea,
                ),
              ],
            ),
          ),

          // Floating Controls (Re-center GPS & Map/List switch)
          Positioned(
            right: 16,
            bottom: selectedPlace != null ? 180 : 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Re-center GPS Button
                FloatingActionButton.small(
                  heroTag: 'recenter_gps',
                  backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                  foregroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
                  onPressed: _recenterOnUser,
                  child: const Icon(Icons.my_location_rounded, size: 20),
                ),
                const SizedBox(height: 10),

                // Map/List Toggle Button
                FloatingActionButton.extended(
                  heroTag: 'map_list_toggle',
                  backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                  foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  icon: const Icon(Icons.format_list_bulleted_rounded, size: 18),
                  label: const Text('List View'),
                  onPressed: () {
                    // Switch to Explore tab in main scaffold
                    context.go('/');
                  },
                ),
              ],
            ),
          ),

          // Bottom Place Preview Sheet
          if (selectedPlace != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: MapPreviewSheet(
                place: selectedPlace,
                onClose: () {
                  ref.read(selectedMapPlaceProvider.notifier).state = null;
                },
                onOpenDetails: () {
                  context.push('/place/${selectedPlace.id}', extra: selectedPlace);
                },
              ),
            ),
        ],
      ),
    );
  }
}
