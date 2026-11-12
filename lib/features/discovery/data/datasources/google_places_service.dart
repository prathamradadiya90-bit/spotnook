import 'package:dio/dio.dart';
import '../../../../core/config/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/utils/distance_calculator.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/place.dart';
import '../../domain/entities/search_filter.dart';

/// Integration with Google Places API (New) REST Service.
/// Follows official Google Places Platform policies:
/// - Places API (New) endpoints
/// - Required Google attribution
/// - Field mask optimization to limit billing and network payload
class GooglePlacesService {
  final DioClient _dioClient;
  String apiKey;

  GooglePlacesService({required this.apiKey, DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient();

  void updateApiKey(String key) {
    apiKey = key;
  }

  bool get hasValidApiKey => apiKey.trim().isNotEmpty;

  /// Searches places using Google Places API (New) Text Search.
  Future<List<Place>> searchPlaces({
    required String query,
    required double latitude,
    required double longitude,
    double radiusMeters = 5000,
    String categoryId = 'all',
    SearchFilter? filter,
  }) async {
    if (!hasValidApiKey) {
      throw const UnauthorizedException('Google Places API key is not configured.');
    }

    try {
      final response = await _dioClient.dio.post(
        '${ApiConstants.googlePlacesBaseUrl}${ApiConstants.googlePlacesTextSearch}',
        data: {
          'textQuery': query,
          'locationBias': {
            'circle': {
              'center': {'latitude': latitude, 'longitude': longitude},
              'radius': radiusMeters,
            },
          },
          'maxResultCount': 20,
        },
        options: Options(
          headers: {
            'X-Goog-Api-Key': apiKey,
            'X-Goog-FieldMask':
                'places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.userRatingCount,places.priceLevel,places.currentOpeningHours,places.nationalPhoneNumber,places.websiteUri,places.photos',
          },
        ),
      );

      return _parseGoogleResponse(response.data, latitude, longitude, categoryId, filter);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 || e.response?.statusCode == 403) {
        throw UnauthorizedException('Invalid Google Places API key: ${e.response?.data}');
      }
      rethrow;
    }
  }

  /// Searches nearby places using Google Places API (New) Nearby Search.
  Future<List<Place>> getNearbyPlaces({
    required double latitude,
    required double longitude,
    double radiusMeters = 5000,
    String categoryId = 'all',
    SearchFilter? filter,
  }) async {
    if (!hasValidApiKey) {
      throw const UnauthorizedException('Google Places API key is not configured.');
    }

    final cat = PlaceCategory.findById(categoryId);
    final includedTypes = cat.googleType.isNotEmpty ? [cat.googleType] : null;

    try {
      final body = <String, dynamic>{
        'locationRestriction': {
          'circle': {
            'center': {'latitude': latitude, 'longitude': longitude},
            'radius': radiusMeters,
          },
        },
        'maxResultCount': 20,
      };

      if (includedTypes != null) {
        body['includedTypes'] = includedTypes;
      }

      final response = await _dioClient.dio.post(
        '${ApiConstants.googlePlacesBaseUrl}${ApiConstants.googlePlacesNearbySearch}',
        data: body,
        options: Options(
          headers: {
            'X-Goog-Api-Key': apiKey,
            'X-Goog-FieldMask':
                'places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.userRatingCount,places.priceLevel,places.currentOpeningHours,places.nationalPhoneNumber,places.websiteUri,places.photos',
          },
        ),
      );

      return _parseGoogleResponse(response.data, latitude, longitude, categoryId, filter);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 || e.response?.statusCode == 403) {
        throw UnauthorizedException('Invalid Google Places API key: ${e.response?.data}');
      }
      rethrow;
    }
  }

  List<Place> _parseGoogleResponse(
    dynamic data,
    double centerLat,
    double centerLon,
    String categoryId,
    SearchFilter? filter,
  ) {
    if (data is! Map<String, dynamic> || data['places'] is! List) {
      return [];
    }

    final placesList = data['places'] as List;
    var results = <Place>[];

    for (final item in placesList) {
      final id = item['id'] as String? ?? '';
      final displayName = (item['displayName'] as Map<String, dynamic>?)?['text'] as String? ?? 'Place';
      final formattedAddress = item['formattedAddress'] as String? ?? '';
      final loc = item['location'] as Map<String, dynamic>?;
      final lat = (loc?['latitude'] as num?)?.toDouble() ?? 0.0;
      final lon = (loc?['longitude'] as num?)?.toDouble() ?? 0.0;
      final rating = (item['rating'] as num?)?.toDouble();
      final userRatingCount = item['userRatingCount'] as int?;
      final priceLevelStr = item['priceLevel'] as String?;
      final int? priceLevel = _mapPriceLevel(priceLevelStr);

      final hoursObj = item['currentOpeningHours'] as Map<String, dynamic>?;
      final isOpenNow = hoursObj?['openNow'] as bool?;
      final weekdayDescriptions = hoursObj?['weekdayDescriptions'] as List?;
      final openingHours = weekdayDescriptions?.join('\n');

      final phone = item['nationalPhoneNumber'] as String?;
      final website = item['websiteUri'] as String?;

      // Photos
      final photos = item['photos'] as List?;
      final photoUrls = <String>[];
      if (photos != null && photos.isNotEmpty) {
        for (final p in photos.take(3)) {
          final photoName = p['name'] as String?;
          if (photoName != null) {
            photoUrls.add(
              'https://places.googleapis.com/v1/$photoName/media?maxHeightPx=800&maxWidthPx=800&key=$apiKey',
            );
          }
        }
      }

      final distance = DistanceCalculator.calculateDistanceInMeters(centerLat, centerLon, lat, lon);

      results.add(
        Place(
          id: 'google_$id',
          name: displayName,
          categoryId: categoryId == 'all' ? 'restaurant' : categoryId,
          latitude: lat,
          longitude: lon,
          formattedAddress: formattedAddress,
          distanceInMeters: distance,
          rating: rating,
          reviewCount: userRatingCount,
          priceLevel: priceLevel,
          isOpenNow: isOpenNow,
          openingHours: openingHours,
          phoneNumber: phone,
          website: website,
          photoUrls: photoUrls,
          attribution: 'Powered by Google Places',
          sourceProvider: 'google',
        ),
      );
    }

    // Apply active user filters and sorting
    if (filter != null) {
      if (filter.openNowOnly) {
        results = results.where((p) => p.isOpenNow == true).toList();
      }
      if (filter.minRating > 0) {
        results = results.where((p) => (p.rating ?? 0) >= filter.minRating).toList();
      }
      if (filter.hasPhoneOnly) {
        results = results.where((p) => p.phoneNumber != null && p.phoneNumber!.isNotEmpty).toList();
      }
      if (filter.hasWebsiteOnly) {
        results = results.where((p) => p.website != null && p.website!.isNotEmpty).toList();
      }
      if (filter.sortBy == 'rating') {
        results.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
      } else if (filter.sortBy == 'name') {
        results.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      } else {
        results.sort((a, b) => (a.distanceInMeters ?? double.infinity).compareTo(b.distanceInMeters ?? double.infinity));
      }
    } else {
      results.sort((a, b) => (a.distanceInMeters ?? double.infinity).compareTo(b.distanceInMeters ?? double.infinity));
    }

    return results;
  }

  int? _mapPriceLevel(String? level) {
    switch (level) {
      case 'PRICE_LEVEL_INEXPENSIVE':
        return 1;
      case 'PRICE_LEVEL_MODERATE':
        return 2;
      case 'PRICE_LEVEL_EXPENSIVE':
        return 3;
      case 'PRICE_LEVEL_VERY_EXPENSIVE':
        return 4;
      default:
        return null;
    }
  }
}
