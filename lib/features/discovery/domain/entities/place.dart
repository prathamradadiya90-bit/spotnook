import 'package:flutter/foundation.dart';
import 'category.dart';

/// Core domain entity representing a discovered venue or point of interest.
@immutable
class Place {
  final String id;
  final String name;
  final String categoryId;
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final double? distanceInMeters;
  final double? rating;
  final int? reviewCount;
  final int? priceLevel; // 1 to 4
  final bool? isOpenNow;
  final String? openingHours;
  final String? phoneNumber;
  final String? website;
  final List<String> photoUrls;
  final String? attribution;
  final String sourceProvider; // 'osm' or 'google'
  final List<String> amenities;
  final Map<String, dynamic> rawTags;

  const Place({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    this.distanceInMeters,
    this.rating,
    this.reviewCount,
    this.priceLevel,
    this.isOpenNow,
    this.openingHours,
    this.phoneNumber,
    this.website,
    this.photoUrls = const [],
    this.attribution,
    this.sourceProvider = 'osm',
    this.amenities = const [],
    this.rawTags = const {},
  });

  PlaceCategory get category => PlaceCategory.findById(categoryId);

  Place copyWith({
    String? id,
    String? name,
    String? categoryId,
    double? latitude,
    double? longitude,
    String? formattedAddress,
    double? distanceInMeters,
    double? rating,
    int? reviewCount,
    int? priceLevel,
    bool? isOpenNow,
    String? openingHours,
    String? phoneNumber,
    String? website,
    List<String>? photoUrls,
    String? attribution,
    String? sourceProvider,
    List<String>? amenities,
    Map<String, dynamic>? rawTags,
  }) {
    return Place(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      distanceInMeters: distanceInMeters ?? this.distanceInMeters,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      priceLevel: priceLevel ?? this.priceLevel,
      isOpenNow: isOpenNow ?? this.isOpenNow,
      openingHours: openingHours ?? this.openingHours,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      website: website ?? this.website,
      photoUrls: photoUrls ?? this.photoUrls,
      attribution: attribution ?? this.attribution,
      sourceProvider: sourceProvider ?? this.sourceProvider,
      amenities: amenities ?? this.amenities,
      rawTags: rawTags ?? this.rawTags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'latitude': latitude,
      'longitude': longitude,
      'formattedAddress': formattedAddress,
      'distanceInMeters': distanceInMeters,
      'rating': rating,
      'reviewCount': reviewCount,
      'priceLevel': priceLevel,
      'isOpenNow': isOpenNow,
      'openingHours': openingHours,
      'phoneNumber': phoneNumber,
      'website': website,
      'photoUrls': photoUrls,
      'attribution': attribution,
      'sourceProvider': sourceProvider,
      'amenities': amenities,
      'rawTags': rawTags,
    };
  }

  factory Place.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> safeRawTags = const {};
    if (json['rawTags'] is Map) {
      safeRawTags = (json['rawTags'] as Map).map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }

    return Place(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Unnamed Place',
      categoryId: json['categoryId'] as String? ?? 'all',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      formattedAddress: json['formattedAddress'] as String? ?? '',
      distanceInMeters: (json['distanceInMeters'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: (json['reviewCount'] as num?)?.toInt(),
      priceLevel: (json['priceLevel'] as num?)?.toInt(),
      isOpenNow: json['isOpenNow'] as bool?,
      openingHours: json['openingHours'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      website: json['website'] as String?,
      photoUrls: (json['photoUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      attribution: json['attribution'] as String?,
      sourceProvider: json['sourceProvider'] as String? ?? 'osm',
      amenities: (json['amenities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      rawTags: safeRawTags,
    );
  }
}

