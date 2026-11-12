import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Vibe / Mood Filter Definition
class SpotMood {
  final String id;
  final String label;
  final String emoji;

  const SpotMood({
    required this.id,
    required this.label,
    required this.emoji,
  });
}

const List<SpotMood> availableMoods = [
  SpotMood(id: 'all', label: 'All Vibes', emoji: '✨'),
  SpotMood(id: 'work', label: 'Work & Study', emoji: '💻'),
  SpotMood(id: 'outdoor', label: 'Outdoor & Chill', emoji: '🌿'),
  SpotMood(id: 'latenight', label: 'Late Night', emoji: '🌙'),
  SpotMood(id: 'romantic', label: 'Date Night', emoji: '💖'),
  SpotMood(id: 'quick', label: 'Quick Bite', emoji: '⚡'),
];

/// Horizontal mood & vibe selector for context-aware instant filtering.
class MoodChipGroup extends StatelessWidget {
  final String selectedMoodId;
  final ValueChanged<String> onMoodSelected;

  const MoodChipGroup({
    super.key,
    required this.selectedMoodId,
    required this.onMoodSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: availableMoods.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final mood = availableMoods[index];
          final isSelected = mood.id == selectedMoodId;

          return InkWell(
            onTap: () => onMoodSelected(mood.id),
            borderRadius: BorderRadius.circular(19),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? AppColors.primaryLight : AppColors.primary)
                    : (isDark ? AppColors.surfaceDarkVariant : AppColors.surfaceLightVariant),
                borderRadius: BorderRadius.circular(19),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : Colors.grey.withOpacity(isDark ? 0.2 : 0.15),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(mood.emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    mood.label,
                    style: AppTypography.labelMedium.copyWith(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
