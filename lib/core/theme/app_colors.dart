import 'package:flutter/material.dart';

/// Semantic Design Palette for SpotFinder.
/// Balanced, modern Vibrant Indigo & Sunset Tangerine styling.
class AppColors {
  AppColors._();

  // Primary Brand Colors (Vibrant Modern Indigo)
  static const Color primary = Color(0xFF4F46E5); // Vibrant Indigo 600
  static const Color primaryLight = Color(0xFF6366F1); // Indigo 500
  static const Color primaryDark = Color(0xFF3730A3); // Deep Indigo 800
  static const Color primaryContainer = Color(0xFFEEF2FF); // Soft Lavender-Indigo Tint

  // Secondary Colors
  static const Color secondary = Color(0xFF0F172A); // Slate 900
  static const Color secondaryLight = Color(0xFF334155); // Slate 700

  // Accent Colors (Warm Sunset & Delight)
  static const Color accent = Color(0xFFF97316); // Tangerine Accent
  static const Color accentLight = Color(0xFFFB923C); // Warm Orange Light
  static const Color accentDark = Color(0xFFC2410C); // Deep Orange
  static const Color starAmber = Color(0xFFF59E0B); // Rating Star Gold
  static const Color heartRose = Color(0xFFF43F5E); // Saved Heart / Bookmark Rose
  static const Color statusOpen = Color(0xFF10B981); // Emerald Green
  static const Color statusClosed = Color(0xFFEF4444); // Crimson Red

  // Neutral Light (Clean, soft slate)
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceLight = Color(0xFFFFFFFF); // Pure White
  static const Color surfaceLightVariant = Color(0xFFF1F5F9); // Slate 100
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate 900
  static const Color textSecondaryLight = Color(0xFF64748B); // Slate 500
  static const Color borderLight = Color(0xFFE2E8F0); // Slate 200

  // Neutral Dark (Rich Slate Navy Dark Mode)
  static const Color backgroundDark = Color(0xFF0B1120); // Deep Midnight
  static const Color surfaceDark = Color(0xFF1E293B); // Slate 800
  static const Color surfaceDarkVariant = Color(0xFF334155); // Slate 700
  static const Color textPrimaryDark = Color(0xFFF8FAFC); // Slate 50
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Slate 400
  static const Color borderDark = Color(0xFF334155); // Slate 700

  // Shimmer
  static const Color shimmerBaseLight = Color(0xFFE2E8F0);
  static const Color shimmerHighlightLight = Color(0xFFF8FAFC);
  static const Color shimmerBaseDark = Color(0xFF1E293B);
  static const Color shimmerHighlightDark = Color(0xFF334155);
}
