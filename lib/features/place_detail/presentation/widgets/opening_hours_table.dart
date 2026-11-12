import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/opening_hours_evaluator.dart';

/// Structured, collapsible opening hours table with computed live open/closed status.
class OpeningHoursTable extends StatefulWidget {
  final String? openingHours;
  final bool? isOpenNow;

  const OpeningHoursTable({
    super.key,
    required this.openingHours,
    this.isOpenNow,
  });

  @override
  State<OpeningHoursTable> createState() => _OpeningHoursTableState();
}

class _OpeningHoursTableState extends State<OpeningHoursTable> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cleanHours = Formatters.cleanOpeningHours(widget.openingHours);

    // Compute live status if not explicitly provided
    final effectiveIsOpen = widget.isOpenNow ?? OpeningHoursEvaluator.computeIsOpenNow(widget.openingHours);

    final lines = cleanHours.split('\n');
    final hasMultipleLines = lines.length > 2;

    return Container(
      decoration: AppDecorations.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: hasMultipleLines ? () => setState(() => _isExpanded = !_isExpanded) : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text('Opening Hours', style: AppTypography.titleMedium),
                      if (hasMultipleLines) ...[
                        const SizedBox(width: 4),
                        Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 20,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ],
                    ],
                  ),
                  if (effectiveIsOpen != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (effectiveIsOpen ? AppColors.statusOpen : AppColors.statusClosed).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: effectiveIsOpen ? AppColors.statusOpen : AppColors.statusClosed,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            effectiveIsOpen ? 'Open Now' : 'Closed',
                            style: AppTypography.labelSmall.copyWith(
                              color: effectiveIsOpen ? AppColors.statusOpen : AppColors.statusClosed,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: (_isExpanded || !hasMultipleLines)
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Text(
                cleanHours,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  height: 1.6,
                ),
              ),
              secondChild: Text(
                lines.take(2).join('\n') + (lines.length > 2 ? '...' : ''),
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  height: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
