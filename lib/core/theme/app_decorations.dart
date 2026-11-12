import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Reusable decorations, shadows, and borders.
class AppDecorations {
  AppDecorations._();

  static const double radiusSmall = 10.0;
  static const double radiusMedium = 18.0;
  static const double radiusLarge = 26.0;
  static const double radiusFull = 999.0;

  static final BorderRadius borderRadiusSmall = BorderRadius.circular(radiusSmall);
  static final BorderRadius borderRadiusMedium = BorderRadius.circular(radiusMedium);
  static final BorderRadius borderRadiusLarge = BorderRadius.circular(radiusLarge);
  static final BorderRadius borderRadiusFull = BorderRadius.circular(radiusFull);

  // Zero-shadow design: Empty lists preserved for backwards compatibility
  static const List<BoxShadow> cardShadowLight = [];
  static const List<BoxShadow> cardShadowDark = [];
  static const List<BoxShadow> floatingShadow = [];

  static BoxDecoration cardDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      borderRadius: borderRadiusMedium,
      border: Border.all(
        color: isDark ? AppColors.borderDark : AppColors.borderLight,
        width: 1.0,
      ),
    );
  }
}
