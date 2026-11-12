import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../discovery/domain/entities/place.dart';
import '../../../saved/presentation/providers/saved_provider.dart';

/// One-tap action buttons row: Directions, Call, Website, Share, Save.
class ActionButtonsRow extends ConsumerWidget {
  final Place place;

  const ActionButtonsRow({super.key, required this.place});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bookmarks = ref.watch(bookmarksProvider);
    final isBookmarked = bookmarks.any((p) => p.id == place.id);
    const navService = NavigationService();

    final hasPhone = place.phoneNumber != null && place.phoneNumber!.trim().isNotEmpty;
    final hasWebsite = place.website != null && place.website!.trim().isNotEmpty;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // Directions
        _ActionButton(
          icon: Icons.directions_rounded,
          label: 'Directions',
          color: isDark ? AppColors.primaryLight : AppColors.primary,
          onTap: () {
            navService.launchDirections(
              latitude: place.latitude,
              longitude: place.longitude,
              placeName: place.name,
            );
          },
        ),

        // Call
        _ActionButton(
          icon: Icons.call_rounded,
          label: 'Call',
          color: hasPhone ? AppColors.statusOpen : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          isEnabled: hasPhone,
          onTap: () {
            if (hasPhone) {
              navService.launchDialer(place.phoneNumber!);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Phone number not available for this venue.')),
              );
            }
          },
        ),

        // Website
        _ActionButton(
          icon: Icons.language_rounded,
          label: 'Website',
          color: hasWebsite ? (isDark ? AppColors.primaryLight : AppColors.primary) : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          isEnabled: hasWebsite,
          onTap: () {
            if (hasWebsite) {
              navService.launchWebsite(place.website!);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Website link not available for this venue.')),
              );
            }
          },
        ),

        // Bookmark
        _ActionButton(
          icon: isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          label: isBookmarked ? 'Saved' : 'Save',
          color: isBookmarked ? AppColors.heartRose : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          onTap: () async {
            final saved = await ref.read(bookmarksProvider.notifier).toggle(place);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(saved ? 'Saved to your favorites!' : 'Removed from favorites'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        ),

        // Share
        Builder(
          builder: (btnContext) => _ActionButton(
            icon: Icons.share_rounded,
            label: 'Share',
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            onTap: () {
              final box = btnContext.findRenderObject() as RenderBox?;
              final origin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;
              navService.sharePlace(place, sharePositionOrigin: origin);
            },
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isEnabled;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.45,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

