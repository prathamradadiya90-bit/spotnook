import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';

/// Floating button that animates in when the map center is panned away from the last search point.
class SearchThisAreaButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isVisible;

  const SearchThisAreaButton({
    super.key,
    required this.onTap,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedSlide(
      offset: isVisible ? Offset.zero : const Offset(0, -2),
      duration: const Duration(milliseconds: 250),
      child: AnimatedOpacity(
        opacity: isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: AppDecorations.borderRadiusFull,
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isVisible ? onTap : null,
              borderRadius: AppDecorations.borderRadiusFull,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      size: 16,
                      color: isDark ? AppColors.primaryLight : AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Search this area',
                      style: AppTypography.labelMedium.copyWith(
                        color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

