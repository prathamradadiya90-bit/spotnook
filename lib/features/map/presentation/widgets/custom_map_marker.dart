import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../discovery/domain/entities/place.dart';

/// Interactive map marker widget with selected glow state.
class CustomMapMarker extends StatelessWidget {
  final Place place;
  final bool isSelected;
  final VoidCallback onTap;

  const CustomMapMarker({
    super.key,
    required this.place,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.25 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2.2,
                ),
              ),
              child: Icon(
                place.category.icon,
                color: Colors.white,
                size: 18,
              ),
            ),
            // Pin Point Triangle
            CustomPaint(
              size: const Size(10, 6),
              painter: _TrianglePainter(
                color: isSelected ? AppColors.accent : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) => oldDelegate.color != color;
}

