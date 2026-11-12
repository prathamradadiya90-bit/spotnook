import 'package:flutter/foundation.dart';

/// Represents a geographic point and its resolved reverse-geocoded name.
@immutable
class LocationInfo {
  final double latitude;
  final double longitude;
  final String name;
  final String formattedAddress;
  final bool isFromGps;

  const LocationInfo({
    required this.latitude,
    required this.longitude,
    required this.name,
    required this.formattedAddress,
    this.isFromGps = false,
  });

  LocationInfo copyWith({
    double? latitude,
    double? longitude,
    String? name,
    String? formattedAddress,
    bool? isFromGps,
  }) {
    return LocationInfo(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      name: name ?? this.name,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      isFromGps: isFromGps ?? this.isFromGps,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'name': name,
      'formattedAddress': formattedAddress,
      'isFromGps': isFromGps,
    };
  }

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      name: json['name'] as String? ?? 'Custom Location',
      formattedAddress: json['formattedAddress'] as String? ?? '',
      isFromGps: json['isFromGps'] as bool? ?? false,
    );
  }
}

