import 'package:flutter/material.dart';
import '../../domain/entities/category.dart';

/// Renders an honest, beautifully stylized category illustration and icon badge.
/// Used whenever a venue does not have verified real photos from the provider,
/// ensuring the app never presents stock photography as genuine venue photos.
class CategoryIllustrationWidget extends StatelessWidget {
  final PlaceCategory category;
  final String? placeName;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool compact;

  const CategoryIllustrationWidget({
    super.key,
    required this.category,
    this.placeName,
    this.width,
    this.height,
    this.borderRadius,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _getCategoryPalette(category.id, placeName);

    return Semantics(
      label: 'Category illustration for ${category.name}',
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Container(
          width: width ?? double.infinity,
          height: height ?? double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [palette.start, palette.end],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              // Radial highlight overlay for luminous modern depth
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.4, -0.5),
                      radius: 1.1,
                      colors: [
                        palette.highlight.withOpacity(0.45),
                        palette.highlight.withOpacity(0.10),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // Decorative subtle background concentric ring
              Positioned(
                right: compact ? -15 : -25,
                top: compact ? -15 : -25,
                child: Container(
                  width: compact ? 90 : 160,
                  height: compact ? 90 : 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.10),
                      width: compact ? 12 : 20,
                    ),
                  ),
                ),
              ),

              // Decorative background watermark category icon
              Positioned(
                right: compact ? -8 : -12,
                bottom: compact ? -8 : -14,
                child: Icon(
                  category.icon,
                  size: compact ? 68 : 120,
                  color: Colors.white.withOpacity(0.14),
                ),
              ),

              // Centered Frosted Glass Category Icon & Label
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(compact ? 9 : 15),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.32),
                            Colors.white.withOpacity(0.14),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.65),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        category.icon,
                        size: compact ? 24 : 38,
                        color: Colors.white,
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 8),
                      Text(
                        category.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static ({Color start, Color end, Color highlight}) _getCategoryPalette(String id, [String? name]) {
    // Hash name to provide subtle, pleasing gradient variations between adjacent spots in the same category
    final variation = (name != null && name.isNotEmpty)
        ? (name.codeUnits.fold<int>(0, (acc, c) => acc + c) % 3)
        : 0;

    switch (id) {
      case 'fast_food':
        switch (variation) {
          case 1:
            // Sunset Coral Amber
            return (
              start: const Color(0xFFF05033),
              end: const Color(0xFFFF8A00),
              highlight: const Color(0xFFFFD180),
            );
          case 2:
            // Golden Flame
            return (
              start: const Color(0xFFE65100),
              end: const Color(0xFFFFA000),
              highlight: const Color(0xFFFFE082),
            );
          default:
            // Radiant Citrus Glow
            return (
              start: const Color(0xFFFF3D00),
              end: const Color(0xFFFF9100),
              highlight: const Color(0xFFFFD54F),
            );
        }

      case 'restaurant':
        switch (variation) {
          case 1:
            // Rich Ruby Rose
            return (
              start: const Color(0xFFC2185B),
              end: const Color(0xFFE91E63),
              highlight: const Color(0xFFF48FB1),
            );
          case 2:
            // Tuscan Crimson
            return (
              start: const Color(0xFFB71C1C),
              end: const Color(0xFFE53935),
              highlight: const Color(0xFFFF8A80),
            );
          default:
            // Gourmet Raspberry Wine
            return (
              start: const Color(0xFF880E4F),
              end: const Color(0xFFD81B60),
              highlight: const Color(0xFFFF80AB),
            );
        }

      case 'cafe':
        switch (variation) {
          case 1:
            // Warm Caramel Macchiato
            return (
              start: const Color(0xFF8D6E63),
              end: const Color(0xFFD7CCC8),
              highlight: const Color(0xFFFFFFFF),
            );
          case 2:
            // Cinnamon Amber Latte
            return (
              start: const Color(0xFFB45309),
              end: const Color(0xFFF59E0B),
              highlight: const Color(0xFFFEF3C7),
            );
          default:
            // Rich Roast Espresso
            return (
              start: const Color(0xFF5D4037),
              end: const Color(0xFFA1887F),
              highlight: const Color(0xFFEFEBE9),
            );
        }

      case 'hotel':
      case 'resort':
        switch (variation) {
          case 1:
            // Deep Sapphire to Royal Blue
            return (
              start: const Color(0xFF1E3A8A),
              end: const Color(0xFF3B82F6),
              highlight: const Color(0xFF93C5FD),
            );
          case 2:
            // Twilight Indigo
            return (
              start: const Color(0xFF312E81),
              end: const Color(0xFF6366F1),
              highlight: const Color(0xFFA5B4FC),
            );
          default:
            // Azure Ocean
            return (
              start: const Color(0xFF0C4A6E),
              end: const Color(0xFF0284C7),
              highlight: const Color(0xFF7DD3FC),
            );
        }

      case 'gym':
        return (
          start: const Color(0xFF047857),
          end: const Color(0xFF10B981),
          highlight: const Color(0xFFA7F3D0),
        );

      case 'shopping':
      case 'clothing':
        return (
          start: const Color(0xFF6D28D9),
          end: const Color(0xFFA855F7),
          highlight: const Color(0xFFE9D5FF),
        );

      case 'hospital':
      case 'pharmacy':
        return (
          start: const Color(0xFF0369A1),
          end: const Color(0xFF0EA5E9),
          highlight: const Color(0xFFBAE6FD),
        );

      case 'attraction':
      case 'park':
        return (
          start: const Color(0xFF15803D),
          end: const Color(0xFF22C55E),
          highlight: const Color(0xFFBBF7D0),
        );

      case 'cinema':
        return (
          start: const Color(0xFF9D174D),
          end: const Color(0xFFF43F5E),
          highlight: const Color(0xFFFECDD3),
        );

      case 'fuel':
      case 'atm':
        return (
          start: const Color(0xFF334155),
          end: const Color(0xFF64748B),
          highlight: const Color(0xFFCBD5E1),
        );

      case 'salon':
        return (
          start: const Color(0xFFBE185D),
          end: const Color(0xFFFB7185),
          highlight: const Color(0xFFFFE4E6),
        );

      case 'business':
        return (
          start: const Color(0xFF0F172A),
          end: const Color(0xFF2563EB),
          highlight: const Color(0xFF60A5FA),
        );

      case 'education':
        return (
          start: const Color(0xFF312E81),
          end: const Color(0xFF4F46E5),
          highlight: const Color(0xFFA5B4FC),
        );

      default:
        return (
          start: const Color(0xFF0F766E),
          end: const Color(0xFF14B8A6),
          highlight: const Color(0xFF99F6E4),
        );
    }
  }
}
