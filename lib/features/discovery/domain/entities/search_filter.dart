import 'package:flutter/foundation.dart';

/// Search and Discovery Filters.
@immutable
class SearchFilter {
  final double radiusInMeters;
  final String categoryId;
  final bool openNowOnly;
  final double minRating;
  final String sortBy; // 'distance', 'rating', 'name'
  final bool hasPhoneOnly;
  final bool hasWebsiteOnly;

  const SearchFilter({
    this.radiusInMeters = 5000.0,
    this.categoryId = 'all',
    this.openNowOnly = false,
    this.minRating = 0.0,
    this.sortBy = 'distance',
    this.hasPhoneOnly = false,
    this.hasWebsiteOnly = false,
  });

  SearchFilter copyWith({
    double? radiusInMeters,
    String? categoryId,
    bool? openNowOnly,
    double? minRating,
    String? sortBy,
    bool? hasPhoneOnly,
    bool? hasWebsiteOnly,
  }) {
    return SearchFilter(
      radiusInMeters: radiusInMeters ?? this.radiusInMeters,
      categoryId: categoryId ?? this.categoryId,
      openNowOnly: openNowOnly ?? this.openNowOnly,
      minRating: minRating ?? this.minRating,
      sortBy: sortBy ?? this.sortBy,
      hasPhoneOnly: hasPhoneOnly ?? this.hasPhoneOnly,
      hasWebsiteOnly: hasWebsiteOnly ?? this.hasWebsiteOnly,
    );
  }
}

