import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';

/// Shimmer placeholder container for smooth loading states.
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.shimmerBaseDark : AppColors.shimmerBaseLight;
    final highlightColor = isDark ? AppColors.shimmerHighlightDark : AppColors.shimmerHighlightLight;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(baseColor, highlightColor, _controller.value),
            borderRadius: widget.borderRadius ?? AppDecorations.borderRadiusSmall,
          ),
        );
      },
    );
  }
}

/// Loading placeholder for place cards in lists.
class PlaceCardSkeleton extends StatelessWidget {
  const PlaceCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: AppDecorations.cardDecoration(context),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ShimmerBox(
            width: 44,
            height: 44,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ShimmerBox(width: 140, height: 16),
                SizedBox(height: 6),
                ShimmerBox(width: 180, height: 13),
                SizedBox(height: 6),
                ShimmerBox(width: 110, height: 11),
              ],
            ),
          ),
          SizedBox(width: 8),
          ShimmerBox(
            width: 24,
            height: 24,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ],
      ),
    );
  }
}
