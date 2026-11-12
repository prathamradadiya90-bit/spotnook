import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/distance_calculator.dart';
import '../../../../core/utils/rating_helper.dart';
import '../../domain/entities/place.dart';

/// "Surprise Me!" Decision Maker Modal Sheet.
/// Solves indecision ("Where should we eat/go?") by spinning through nearby places
/// and picking a top-rated destination with playful animations and haptics.
class SurpriseMeModal extends StatefulWidget {
  final List<Place> candidatePlaces;
  final ValueChanged<Place> onSelectPlace;

  const SurpriseMeModal({
    super.key,
    required this.candidatePlaces,
    required this.onSelectPlace,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Place> places,
    required ValueChanged<Place> onSelectPlace,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SurpriseMeModal(
        candidatePlaces: places,
        onSelectPlace: onSelectPlace,
      ),
    );
  }

  @override
  State<SurpriseMeModal> createState() => _SurpriseMeModalState();
}

class _SurpriseMeModalState extends State<SurpriseMeModal> {
  late List<Place> _filtered;
  Place? _currentPick;
  bool _isSpinning = false;
  Timer? _spinTimer;
  int _spinTicks = 0;

  @override
  void initState() {
    super.initState();
    _filtered = widget.candidatePlaces.isNotEmpty
        ? widget.candidatePlaces
        : [];
    if (_filtered.isNotEmpty) {
      _startSpin();
    }
  }

  @override
  void dispose() {
    _spinTimer?.cancel();
    super.dispose();
  }

  void _startSpin() {
    if (_filtered.isEmpty) return;

    setState(() {
      _isSpinning = true;
      _spinTicks = 0;
    });

    final random = Random();
    const totalTicks = 12;
    int intervalMs = 60;

    _spinTimer?.cancel();
    _spinTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _spinTicks++;
      final nextIndex = random.nextInt(_filtered.length);
      HapticFeedback.selectionClick();

      setState(() {
        _currentPick = _filtered[nextIndex];
      });

      if (_spinTicks >= totalTicks) {
        timer.cancel();
        HapticFeedback.heavyImpact();
        setState(() {
          _isSpinning = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Text('🎲', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 10),
              Text(
                _isSpinning ? 'Picking a Great Spot...' : 'Your Next Discovery!',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Picked Place Card
          if (_currentPick != null) ...[
            Builder(
              builder: (context) {
                final photoUrl = _currentPick!.photoUrls.isNotEmpty ? _currentPick!.photoUrls.first : null;
                final rating = _currentPick!.rating ?? RatingHelper.generateRating(_currentPick!.id, _currentPick!.name, categoryId: _currentPick!.categoryId);

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  transform: Matrix4.identity()..scale(_isSpinning ? 0.98 : 1.0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDarkVariant : AppColors.surfaceLightVariant,
                    borderRadius: AppDecorations.borderRadiusLarge,
                    border: Border.all(
                      color: _isSpinning
                          ? AppColors.accent.withOpacity(0.4)
                          : AppColors.primary.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Photo Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 76,
                          height: 76,
                          color: Colors.grey.withOpacity(0.2),
                          child: photoUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: photoUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, _, _) => const Icon(Icons.place_rounded),
                                )
                              : const Icon(Icons.place_rounded),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentPick!.name,
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentPick!.category.name,
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: AppColors.starAmber, size: 16),
                                const SizedBox(width: 3),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                ),
                                if (_currentPick!.distanceInMeters != null) ...[
                                  const Text(' • ', style: TextStyle(color: Colors.grey)),
                                  Text(
                                    DistanceCalculator.formatDistance(_currentPick!.distanceInMeters!),
                                    style: AppTypography.bodySmall.copyWith(fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ] else ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Text('Finding spots nearby...'),
            ),
          ],
          const SizedBox(height: 24),

          // Actions Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSpinning ? null : _startSpin,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Spin Again'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppDecorations.borderRadiusFull,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: (_isSpinning || _currentPick == null)
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          widget.onSelectPlace(_currentPick!);
                        },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Take Me There'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppDecorations.borderRadiusFull,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
