import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/config/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/nominatim_rate_limiter.dart';
import '../../domain/entities/location_info.dart';

/// Geocoding & Reverse Geocoding Service compliant with OpenStreetMap and Komoot policies:
/// - As-you-type autocomplete uses Komoot Photon with CancelToken support.
/// - Reverse geocoding & fallbacks use Nominatim, strictly rate-limited to <= 1 request/sec.
/// - User-Agent header is properly populated on mobile/desktop.
/// - Base URLs are configurable for self-hosting.
class NominatimService {
  final DioClient _dioClient;
  String photonBaseUrl;
  String nominatimBaseUrl;

  NominatimService({
    DioClient? dioClient,
    String? customPhotonUrl,
    String? customNominatimUrl,
  })  : _dioClient = dioClient ?? DioClient(),
        photonBaseUrl = customPhotonUrl ?? ApiConstants.photonBaseUrl,
        nominatimBaseUrl = customNominatimUrl ?? ApiConstants.nominatimBaseUrl;

  /// Resolves geographic coordinates into a human-readable city/area name.
  /// Throttled by [NominatimRateLimiter] to guarantee at most 1 req/second.
  Future<LocationInfo> reverseGeocode(double latitude, double longitude) async {
    return NominatimRateLimiter.instance.schedule<LocationInfo>(() async {
      try {
        final response = await _dioClient.dio.get(
          '$nominatimBaseUrl${ApiConstants.nominatimReverse}',
          queryParameters: {
            'lat': latitude,
            'lon': longitude,
            'format': 'jsonv2',
            'zoom': 14,
            'addressdetails': 1,
          },
          options: Options(
            headers: {if (!kIsWeb) 'User-Agent': ApiConstants.appUserAgent},
            receiveTimeout: const Duration(seconds: 8),
          ),
        );

        final data = response.data;
        if (data is Map<String, dynamic>) {
          final address = data['address'] as Map<String, dynamic>? ?? {};
          final displayName = data['display_name'] as String? ?? 'Selected Location';

          final areaName = address['suburb'] ??
              address['neighbourhood'] ??
              address['quarter'] ??
              address['city_district'] ??
              address['city'] ??
              address['town'] ??
              address['village'] ??
              'Selected Location';

          final cityName = address['city'] ??
              address['town'] ??
              address['county'] ??
              address['state'] ??
              '';

          final label = cityName.isNotEmpty && areaName != cityName
              ? '$areaName, $cityName'
              : areaName;

          return LocationInfo(
            latitude: latitude,
            longitude: longitude,
            name: label.toString(),
            formattedAddress: displayName,
            isFromGps: false,
          );
        }
      } catch (_) {
        // Fallback below
      }

      return LocationInfo(
        latitude: latitude,
        longitude: longitude,
        name: 'Custom Location',
        formattedAddress: '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
        isFromGps: false,
      );
    });
  }

  /// Searches for locations.
  /// Strictly adheres to policy: Uses Photon for as-you-type autocomplete with [CancelToken].
  /// Nominatim is NEVER hit for rapid typing, preserving compliance.
  Future<List<LocationInfo>> searchLocations(
    String query, {
    CancelToken? cancelToken,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    // Step 1: Query Komoot Photon (Fast, CORS-friendly, designed for autocomplete)
    final photonResults = await _searchLocationsWithPhoton(cleanQuery, cancelToken: cancelToken);
    if (photonResults.isNotEmpty) {
      return photonResults;
    }

    // Step 2: Rate-limited Nominatim fallback only if Photon returned empty and wasn't cancelled
    if (cancelToken?.isCancelled == true) return [];

    return _searchLocationsWithNominatim(cleanQuery);
  }

  /// Photon geocoding for fast as-you-type autocomplete.
  Future<List<LocationInfo>> _searchLocationsWithPhoton(
    String query, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        photonBaseUrl,
        queryParameters: {'q': query, 'limit': 8},
        cancelToken: cancelToken,
        options: Options(
          receiveTimeout: const Duration(seconds: 6),
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['features'] is List) {
        final features = data['features'] as List;
        return features.map<LocationInfo>((feature) {
          final geom = feature['geometry'] as Map<String, dynamic>? ?? {};
          final coords = geom['coordinates'] as List? ?? [0.0, 0.0];
          final props = feature['properties'] as Map<String, dynamic>? ?? {};

          final lon = (coords[0] as num).toDouble();
          final lat = (coords[1] as num).toDouble();
          final name = props['name']?.toString() ?? query;
          final city = props['city']?.toString() ?? '';
          final state = props['state']?.toString() ?? '';
          final country = props['country']?.toString() ?? '';

          final buffer = StringBuffer(name);
          if (city.isNotEmpty && city != name) buffer.write(', $city');
          if (state.isNotEmpty) buffer.write(', $state');
          if (country.isNotEmpty) buffer.write(', $country');

          return LocationInfo(
            latitude: lat,
            longitude: lon,
            name: name,
            formattedAddress: buffer.toString(),
            isFromGps: false,
          );
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Rate-limited Nominatim fallback search (max 1 req/sec).
  Future<List<LocationInfo>> _searchLocationsWithNominatim(String query) async {
    return NominatimRateLimiter.instance.schedule<List<LocationInfo>>(() async {
      try {
        final response = await _dioClient.dio.get(
          '$nominatimBaseUrl${ApiConstants.nominatimSearch}',
          queryParameters: {
            'q': query,
            'format': 'jsonv2',
            'addressdetails': 1,
            'limit': 10,
          },
          options: Options(
            headers: {if (!kIsWeb) 'User-Agent': ApiConstants.appUserAgent},
            receiveTimeout: const Duration(seconds: 8),
          ),
        );

        final data = response.data;
        if (data is List) {
          return data.map<LocationInfo>((item) {
            final lat = double.tryParse(item['lat']?.toString() ?? '') ?? 0.0;
            final lon = double.tryParse(item['lon']?.toString() ?? '') ?? 0.0;
            final displayName = item['display_name']?.toString() ?? query;
            final address = item['address'] as Map<String, dynamic>? ?? {};

            final name = address['suburb'] ??
                address['neighbourhood'] ??
                address['city'] ??
                address['town'] ??
                address['village'] ??
                item['name'] ??
                query;

            return LocationInfo(
              latitude: lat,
              longitude: lon,
              name: name.toString(),
              formattedAddress: displayName,
              isFromGps: false,
            );
          }).where((loc) => loc.latitude != 0.0 && loc.longitude != 0.0).toList();
        }
      } catch (_) {}
      return [];
    });
  }
}
