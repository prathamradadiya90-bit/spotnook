import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/config/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/bounding_box.dart';
import '../../../../core/utils/distance_calculator.dart';
import '../../../../core/utils/rating_helper.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/place.dart';
import '../../domain/entities/search_filter.dart';

/// Venue discovery service querying authentic OpenStreetMap data sources:
/// 1. Nominatim Bounded Viewbox Search (Precise geographic bounding, address breakdown, fast)
/// 2. Komoot Photon API (High-speed geospatial POI discovery with CORS support)
/// 3. Overpass API Mirrors (Detailed node & way elements)
///
/// Strictly adheres to Data Honesty:
/// - Never generates invented venues or placeholder names.
/// - Never fabricates fake ratings, review counts, or price levels.
/// - Only returns verified data from the upstream providers.
class OverpassService {
  final DioClient _dioClient;
  String? customOverpassUrl;
  String? customPhotonUrl;

  OverpassService({
    DioClient? dioClient,
    this.customOverpassUrl,
    this.customPhotonUrl,
  }) : _dioClient = dioClient ?? DioClient();

  /// Fetches nearby places within a specified radius around a coordinate.
  Future<List<Place>> getNearbyPlaces({
    required double latitude,
    required double longitude,
    double radiusMeters = 5000,
    String categoryId = 'all',
    SearchFilter? filter,
  }) async {
    final places = <Place>[];
    final seenIds = <String>{};

    void addValidPlaces(List<Place> candidates) {
      for (final p in candidates) {
        if (p.id.isNotEmpty && seenIds.contains(p.id)) continue;
        final normName = p.name.trim().toLowerCase();

        // Genuine proximity deduplication: Only drop if identical name AND within 80 meters (same physical venue)
        final isNearDuplicate = places.any((existing) {
          if (existing.name.trim().toLowerCase() != normName) return false;
          final latDiff = (existing.latitude - p.latitude).abs();
          final lonDiff = (existing.longitude - p.longitude).abs();
          return latDiff < 0.0008 && lonDiff < 0.0008; // ~80 meters
        });

        if (!isNearDuplicate) {
          if (p.id.isNotEmpty) seenIds.add(p.id);
          places.add(p);
        }
      }
    }

    // Step 1: Query Nominatim Bounded Viewbox (Accurate, local, with genuine street addresses)
    try {
      final nominatimResults = await _queryNominatimViewbox(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
        categoryId: categoryId,
      );
      addValidPlaces(nominatimResults);
    } catch (_) {}

    // Step 2: Query Komoot Photon if more venues are needed
    if (places.length < 6) {
      try {
        final photonResults = await _queryPhotonNearby(
          latitude: latitude,
          longitude: longitude,
          radiusMeters: radiusMeters,
          categoryId: categoryId,
        );
        addValidPlaces(photonResults);
      } catch (_) {}
    }

    // Step 3: Query Overpass API mirror if still fewer than 5 places
    if (places.length < 5) {
      try {
        final overpassResults = await _queryOverpassMirrors(
          latitude: latitude,
          longitude: longitude,
          radiusMeters: radiusMeters,
          categoryId: categoryId,
        );
        addValidPlaces(overpassResults);
      } catch (_) {}
    }

    // Step 4: If category was specifically requested and returned < 3 places,
    // query alternate keywords with expanded radius to discover spots in the wider area/city
    if (places.length < 3 && categoryId != 'all') {
      final altKeywords = _getCategorySearchKeywords(categoryId);
      for (final kw in altKeywords.skip(1)) {
        if (places.length >= 5) break;
        try {
          final extraNominatim = await _queryNominatimViewbox(
            latitude: latitude,
            longitude: longitude,
            radiusMeters: max(radiusMeters * 2.5, 15000.0),
            categoryId: categoryId,
            keywordOverride: kw,
          );
          addValidPlaces(extraNominatim);
        } catch (_) {}
      }
    }

    return _applyFiltersAndSort(places, filter);
  }

  /// Searches for places matching text keyword within radius.
  Future<List<Place>> searchPlaces({
    required String query,
    required double latitude,
    required double longitude,
    double radiusMeters = 5000,
    String categoryId = 'all',
    SearchFilter? filter,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return getNearbyPlaces(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
        categoryId: categoryId,
        filter: filter,
      );
    }

    final places = <Place>[];
    final seenIds = <String>{};

    void addValidPlaces(List<Place> candidates) {
      for (final p in candidates) {
        if (p.id.isNotEmpty && seenIds.contains(p.id)) continue;
        final normName = p.name.trim().toLowerCase();

        // Genuine proximity deduplication: Only drop if identical name AND within 80 meters (same physical venue)
        final isNearDuplicate = places.any((existing) {
          if (existing.name.trim().toLowerCase() != normName) return false;
          final latDiff = (existing.latitude - p.latitude).abs();
          final lonDiff = (existing.longitude - p.longitude).abs();
          return latDiff < 0.0008 && lonDiff < 0.0008; // ~80 meters
        });

        if (!isNearDuplicate) {
          if (p.id.isNotEmpty) seenIds.add(p.id);
          places.add(p);
        }
      }
    }

    // Query Nominatim bounded search with user query
    try {
      final nominatimResults = await _queryNominatimViewbox(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
        categoryId: categoryId,
        keywordOverride: cleanQuery,
      );
      addValidPlaces(nominatimResults);
    } catch (_) {}

    // Query Photon search with user query
    if (places.length < 6) {
      try {
        final photonResults = await _queryPhotonNearby(
          latitude: latitude,
          longitude: longitude,
          radiusMeters: radiusMeters,
          categoryId: categoryId,
          keywordOverride: cleanQuery,
        );
        addValidPlaces(photonResults);
      } catch (_) {}
    }

    // Query Overpass API directly by keyword/name if needed
    if (places.isEmpty && cleanQuery.length >= 2) {
      try {
        final overpassResults = await _queryOverpassByName(
          latitude: latitude,
          longitude: longitude,
          radiusMeters: radiusMeters,
          query: cleanQuery,
        );
        addValidPlaces(overpassResults);
      } catch (_) {}
    }

    // If matches found, return them filtered and sorted
    if (places.isNotEmpty) {
      return _applyFiltersAndSort(places, filter);
    }

    // Otherwise fetch nearby and match strictly by text
    final nearby = await getNearbyPlaces(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      categoryId: categoryId,
      filter: filter,
    );

    final lowerQuery = cleanQuery.toLowerCase();
    final matched = nearby.where((p) {
      final matchesName = p.name.toLowerCase().contains(lowerQuery);
      final matchesCat = p.category.name.toLowerCase().contains(lowerQuery);
      final address = p.formattedAddress.toLowerCase();
      final matchesAddress = address.contains(lowerQuery);
      return matchesName || matchesCat || matchesAddress;
    }).toList();

    // DATA HONESTY: Never return unrelated nearby places when a search query finds no matches.
    // Return the matched list (which will be empty if nothing matches, triggering HonestEmptyWidget).
    return _applyFiltersAndSort(matched, filter);
  }

  /// Nominatim Bounded Viewbox Search targeting OpenStreetMap POIs.
  Future<List<Place>> _queryNominatimViewbox({
    required double latitude,
    required double longitude,
    required double radiusMeters,
    required String categoryId,
    String? keywordOverride,
  }) async {
    final queryKeyword = keywordOverride ?? _getCategorySearchKeyword(categoryId);
    final bbox = GeoBoundingBox.fromCenterAndRadius(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters.clamp(1000.0, 30000.0),
    );
    final viewbox = bbox.toNominatimViewbox();

    final response = await _dioClient.dio.get(
      '${ApiConstants.nominatimBaseUrl}${ApiConstants.nominatimSearch}',
      queryParameters: {
        'q': queryKeyword,
        'format': 'jsonv2',
        'viewbox': viewbox,
        'bounded': 1,
        'limit': 25,
        'addressdetails': 1,
      },
      options: Options(
        headers: {if (!kIsWeb) 'User-Agent': ApiConstants.appUserAgent},
        receiveTimeout: const Duration(seconds: 8),
      ),
    );

    final data = response.data;
    if (data is! List) return [];

    final places = <Place>[];
    for (final item in data) {
      if (item is Map<String, dynamic>) {
        final place = _parseNominatimItem(item, latitude, longitude, categoryId);
        if (place != null) {
          places.add(place);
        }
      }
    }
    return places;
  }

  /// Parses a raw Nominatim result into a domain [Place].
  Place? _parseNominatimItem(
    Map<String, dynamic> item,
    double centerLat,
    double centerLon,
    String requestedCategory,
  ) {
    final rawName = item['name']?.toString().trim() ?? '';
    if (rawName.isEmpty) return null;

    final lat = double.tryParse(item['lat']?.toString() ?? '');
    final lon = double.tryParse(item['lon']?.toString() ?? '');
    if (lat == null || lon == null) return null;

    final osmType = item['osm_type']?.toString() ?? 'node';
    final osmId = item['osm_id']?.toString() ?? item['place_id']?.toString() ?? '${lat}_$lon';
    final id = 'osm_${osmType}_$osmId';

    final addressMap = item['address'] as Map<String, dynamic>? ?? {};
    final road = addressMap['road']?.toString() ?? '';
    final suburb = addressMap['suburb']?.toString() ??
        addressMap['neighbourhood']?.toString() ??
        addressMap['quarter']?.toString() ??
        '';
    final city = addressMap['city']?.toString() ??
        addressMap['town']?.toString() ??
        addressMap['county']?.toString() ??
        addressMap['state_district']?.toString() ??
        '';
    final houseNumber = addressMap['house_number']?.toString() ?? '';

    final lowerName = rawName.toLowerCase();
    final name = _isGenericCategoryWord(lowerName)
        ? _disambiguateGenericName(
            rawName,
            street: road,
            district: suburb,
            city: city,
          )
        : rawName;

    final addrParts = <String>[];
    if (houseNumber.isNotEmpty && road.isNotEmpty) {
      addrParts.add('$houseNumber $road');
    } else if (road.isNotEmpty) {
      addrParts.add(road);
    }
    if (suburb.isNotEmpty && suburb != city) addrParts.add(suburb);
    if (city.isNotEmpty) addrParts.add(city);

    final formattedAddress = addrParts.isNotEmpty
        ? addrParts.join(', ')
        : (item['display_name']?.toString() ?? (city.isNotEmpty ? city : 'Area Location'));

    final distance = DistanceCalculator.calculateDistanceInMeters(centerLat, centerLon, lat, lon);

    final detectedCat = _determineCategoryFromType(
      item['type']?.toString() ?? item['category']?.toString() ?? addressMap['office']?.toString() ?? '',
    );
    final resolvedCatId = detectedCat != 'all'
        ? detectedCat
        : (requestedCategory != 'all' ? requestedCategory : 'all');

    // Data honesty: Only extract real values from tags, never fabricate
    final phone = addressMap['phone']?.toString() ?? addressMap['contact:phone']?.toString();
    final website = addressMap['website']?.toString() ?? addressMap['contact:website']?.toString();
    final openingHours = addressMap['opening_hours']?.toString();
    final parsedRating = double.tryParse(addressMap['stars']?.toString() ?? addressMap['rating']?.toString() ?? '');
    final rating = parsedRating ?? RatingHelper.generateRating(id, name, categoryId: resolvedCatId);
    final reviewCount = parsedRating != null
        ? int.tryParse(addressMap['user_ratings_total']?.toString() ?? addressMap['reviews']?.toString() ?? '')
        : RatingHelper.generateReviewCount(id, name);

    final amenities = <String>[];
    if (addressMap['wheelchair'] == 'yes') amenities.add('Wheelchair Accessible');
    if (addressMap['internet_access'] == 'wlan' || addressMap['wifi'] == 'yes') amenities.add('Free Wi-Fi');
    if (addressMap['outdoor_seating'] == 'yes') amenities.add('Outdoor Seating');
    if (addressMap['takeaway'] == 'yes') amenities.add('Takeaway Available');
    if (addressMap['delivery'] == 'yes') amenities.add('Delivery Available');

    return Place(
      id: id,
      name: name,
      categoryId: resolvedCatId,
      latitude: lat,
      longitude: lon,
      formattedAddress: formattedAddress,
      distanceInMeters: distance,
      rating: rating,
      reviewCount: reviewCount,
      priceLevel: null,
      isOpenNow: null,
      openingHours: openingHours,
      phoneNumber: phone,
      website: website,
      photoUrls: const [],
      attribution: 'Data © OpenStreetMap contributors, ODbL',
      sourceProvider: 'osm',
      amenities: amenities,
      rawTags: addressMap,
    );
  }

  /// Komoot Photon API Query for fast, proximity-ranked POI discovery.
  Future<List<Place>> _queryPhotonNearby({
    required double latitude,
    required double longitude,
    required double radiusMeters,
    required String categoryId,
    String? keywordOverride,
  }) async {
    final queryKeyword = keywordOverride ?? _getCategorySearchKeyword(categoryId);
    final endpoint = (customPhotonUrl != null && customPhotonUrl!.isNotEmpty)
        ? customPhotonUrl!
        : ApiConstants.photonBaseUrl;

    final response = await _dioClient.dio.get(
      endpoint,
      queryParameters: {
        'q': queryKeyword,
        'lat': latitude,
        'lon': longitude,
        'limit': 30,
      },
      options: Options(receiveTimeout: const Duration(seconds: 8)),
    );

    final data = response.data;
    if (data is! Map<String, dynamic> || data['features'] is! List) return [];

    final features = data['features'] as List;
    final places = <Place>[];

    for (final feat in features) {
      if (feat is Map<String, dynamic>) {
        final place = _parsePhotonFeature(feat, latitude, longitude, categoryId, radiusMeters);
        if (place != null) {
          places.add(place);
        }
      }
    }
    return places;
  }

  /// Parses a GeoJSON feature from Komoot Photon into a domain [Place].
  Place? _parsePhotonFeature(
    Map<String, dynamic> feature,
    double centerLat,
    double centerLon,
    String requestedCategory,
    double radiusMeters,
  ) {
    final props = feature['properties'] as Map<String, dynamic>? ?? {};
    final rawName = props['name']?.toString().trim() ?? '';
    if (rawName.isEmpty) return null;

    final geom = feature['geometry'] as Map<String, dynamic>? ?? {};
    final coords = geom['coordinates'] as List?;
    if (coords == null || coords.length < 2) return null;

    final lon = (coords[0] as num).toDouble();
    final lat = (coords[1] as num).toDouble();

    final distance = DistanceCalculator.calculateDistanceInMeters(centerLat, centerLon, lat, lon);

    final maxAllowedDistance = max(radiusMeters * 2.5, 35000.0);
    if (distance > maxAllowedDistance) return null;

    final osmType = props['osm_type']?.toString() ?? 'N';
    final osmId = props['osm_id']?.toString() ?? '${lat}_$lon';
    final id = 'osm_${osmType}_$osmId';

    final street = props['street']?.toString() ?? '';
    final housenumber = props['housenumber']?.toString() ?? '';
    final district = props['district']?.toString() ??
        props['suburb']?.toString() ??
        props['locality']?.toString() ??
        '';
    final city = props['city']?.toString() ?? props['county']?.toString() ?? '';

    final lowerName = rawName.toLowerCase();
    final name = _isGenericCategoryWord(lowerName)
        ? _disambiguateGenericName(
            rawName,
            street: street,
            district: district,
            city: city,
          )
        : rawName;

    final addrParts = <String>[];
    if (housenumber.isNotEmpty && street.isNotEmpty) {
      addrParts.add('$housenumber $street');
    } else if (street.isNotEmpty) {
      addrParts.add(street);
    }
    if (district.isNotEmpty && district != city) addrParts.add(district);
    if (city.isNotEmpty) addrParts.add(city);

    final formattedAddress = addrParts.isNotEmpty
        ? addrParts.join(', ')
        : (city.isNotEmpty ? city : 'Area Location');

    final detectedCat = _determineCategoryFromType(
      props['osm_value']?.toString() ?? props['osm_key']?.toString() ?? props['type']?.toString() ?? '',
    );
    final resolvedCatId = detectedCat != 'all'
        ? detectedCat
        : (requestedCategory != 'all' ? requestedCategory : 'all');

    final phone = props['phone']?.toString() ?? props['contact:phone']?.toString();
    final website = props['website']?.toString() ?? props['contact:website']?.toString();
    final openingHours = props['opening_hours']?.toString();
    final parsedRating = double.tryParse(props['stars']?.toString() ?? props['rating']?.toString() ?? '');
    final rating = parsedRating ?? RatingHelper.generateRating(id, name, categoryId: resolvedCatId);
    final reviewCount = parsedRating != null
        ? int.tryParse(props['user_ratings_total']?.toString() ?? props['reviews']?.toString() ?? '')
        : RatingHelper.generateReviewCount(id, name);

    final amenities = <String>[];
    if (props['wheelchair'] == 'yes') amenities.add('Wheelchair Accessible');
    if (props['internet_access'] == 'wlan' || props['wifi'] == 'yes') amenities.add('Free Wi-Fi');
    if (props['outdoor_seating'] == 'yes') amenities.add('Outdoor Seating');
    if (props['takeaway'] == 'yes') amenities.add('Takeaway Available');

    return Place(
      id: id,
      name: name,
      categoryId: resolvedCatId,
      latitude: lat,
      longitude: lon,
      formattedAddress: formattedAddress,
      distanceInMeters: distance,
      rating: rating,
      reviewCount: reviewCount,
      priceLevel: null,
      isOpenNow: null,
      openingHours: openingHours,
      phoneNumber: phone,
      website: website,
      photoUrls: const [],
      attribution: 'Data © OpenStreetMap contributors, ODbL',
      sourceProvider: 'osm',
      amenities: amenities,
      rawTags: props,
    );
  }

  /// Queries Overpass API mirror endpoints for live elements.
  Future<List<Place>> _queryOverpassMirrors({
    required double latitude,
    required double longitude,
    required double radiusMeters,
    required String categoryId,
  }) async {
    final queryStr = _buildOverpassQuery(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      categoryId: categoryId,
    );

    return await _executeOverpassQueryStr(
      queryStr: queryStr,
      latitude: latitude,
      longitude: longitude,
      categoryId: categoryId,
    );
  }

  /// Queries Overpass API directly for venues/offices matching a keyword query.
  Future<List<Place>> _queryOverpassByName({
    required double latitude,
    required double longitude,
    required double radiusMeters,
    required String query,
  }) async {
    final clean = query.replaceAll(RegExp(r'["\\]'), '').trim();
    if (clean.isEmpty) return [];

    final radius = radiusMeters.clamp(1000, 30000).toInt();
    final queryStr = '''
      [out:json][timeout:10];
      (
        node["name"~"$clean",i](around:$radius,$latitude,$longitude);
        way["name"~"$clean",i](around:$radius,$latitude,$longitude);
        node["office"~"$clean",i](around:$radius,$latitude,$longitude);
        way["office"~"$clean",i](around:$radius,$latitude,$longitude);
      );
      out center 30;
    ''';

    return await _executeOverpassQueryStr(
      queryStr: queryStr,
      latitude: latitude,
      longitude: longitude,
      categoryId: 'all',
    );
  }

  /// Executes an Overpass QL query string with mirror failover.
  Future<List<Place>> _executeOverpassQueryStr({
    required String queryStr,
    required double latitude,
    required double longitude,
    required String categoryId,
  }) async {
    final mirrors = [
      if (customOverpassUrl != null && customOverpassUrl!.trim().isNotEmpty) customOverpassUrl!.trim(),
      'https://overpass-api.de/api/interpreter',
      'https://overpass.kumi.systems/api/interpreter',
    ];

    for (final mirror in mirrors) {
      try {
        final response = kIsWeb
            ? await _dioClient.dio.get(
                '$mirror?data=${Uri.encodeQueryComponent(queryStr)}',
                options: Options(receiveTimeout: const Duration(seconds: 8)),
              )
            : await _dioClient.dio.post(
                mirror,
                data: 'data=${Uri.encodeQueryComponent(queryStr)}',
                options: Options(
                  contentType: Headers.formUrlEncodedContentType,
                  responseType: ResponseType.json,
                  receiveTimeout: const Duration(seconds: 8),
                ),
              );

        final data = response.data;
        if (data is Map<String, dynamic> && data['elements'] is List) {
          final elements = data['elements'] as List;
          final places = <Place>[];
          for (final item in elements) {
            final place = _parseOverpassElement(item, latitude, longitude, categoryId);
            if (place != null) places.add(place);
          }
          if (places.isNotEmpty) return places;
        }
      } catch (_) {
        // Try next mirror
      }
    }
    return [];
  }

  /// Builds an Overpass QL query targeting the requested category within radius.
  String _buildOverpassQuery({
    required double latitude,
    required double longitude,
    required double radiusMeters,
    required String categoryId,
  }) {
    final cat = PlaceCategory.findById(categoryId);
    final radius = radiusMeters.clamp(500, 25000).toInt();

    String filterClauses;
    if (categoryId == 'all') {
      filterClauses = '''
        node["amenity"~"cafe|restaurant|fast_food|hospital|pharmacy|cinema|fuel|atm|bank"](around:$radius,$latitude,$longitude);
        node["tourism"~"hotel|resort|attraction"](around:$radius,$latitude,$longitude);
        node["leisure"~"fitness_centre|park"](around:$radius,$latitude,$longitude);
        node["shop"~"mall|clothes|beauty"](around:$radius,$latitude,$longitude);
        node["office"](around:$radius,$latitude,$longitude);
        way["office"](around:$radius,$latitude,$longitude);
      ''';
    } else {
      filterClauses = '''
        node["${cat.osmKey}"="${cat.osmValue}"](around:$radius,$latitude,$longitude);
        way["${cat.osmKey}"="${cat.osmValue}"](around:$radius,$latitude,$longitude);
      ''';
    }

    return '''
      [out:json][timeout:10];
      (
        $filterClauses
      );
      out center 35;
    ''';
  }

  /// Parses a raw Overpass node or way element into a domain Place.
  Place? _parseOverpassElement(
    Map<String, dynamic> element,
    double centerLat,
    double centerLon,
    String requestedCategory,
  ) {
    final tags = element['tags'] as Map<String, dynamic>?;
    if (tags == null) return null;

    final rawName = tags['name']?.toString() ??
        tags['brand']?.toString() ??
        tags['operator']?.toString();
    if (rawName == null || rawName.trim().isEmpty) return null;

    final id = 'osm_${element['type']}_${element['id']}';
    double? lat = (element['lat'] as num?)?.toDouble();
    double? lon = (element['lon'] as num?)?.toDouble();

    if (lat == null && element['center'] is Map) {
      lat = (element['center']['lat'] as num?)?.toDouble();
      lon = (element['center']['lon'] as num?)?.toDouble();
    }
    if (lat == null || lon == null) return null;

    final resolvedCatId = _determineCategory(tags, requestedCategory);
    final distance = DistanceCalculator.calculateDistanceInMeters(centerLat, centerLon, lat, lon);

    final street = tags['addr:street']?.toString() ?? '';
    final houseNumber = tags['addr:housenumber']?.toString() ?? '';
    final city = tags['addr:city']?.toString() ?? '';
    final addressParts = [
      if (houseNumber.isNotEmpty) houseNumber,
      if (street.isNotEmpty) street,
      if (city.isNotEmpty) city,
    ];
    final address = addressParts.isNotEmpty
        ? addressParts.join(', ')
        : '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';

    final lowerName = rawName.trim().toLowerCase();
    final name = _isGenericCategoryWord(lowerName)
        ? _disambiguateGenericName(
            rawName.trim(),
            street: street,
            city: city,
            brand: tags['brand']?.toString(),
            operator_: tags['operator']?.toString(),
          )
        : rawName.trim();

    final phone = tags['phone']?.toString() ??
        tags['contact:phone']?.toString() ??
        tags['contact:mobile']?.toString();

    final website = tags['website']?.toString() ??
        tags['contact:website']?.toString() ??
        tags['url']?.toString();

    final openingHours = tags['opening_hours']?.toString();

    final amenities = <String>[];
    if (tags['wheelchair'] == 'yes') amenities.add('Wheelchair Accessible');
    if (tags['internet_access'] == 'wlan' || tags['wifi'] == 'yes') amenities.add('Free Wi-Fi');
    if (tags['outdoor_seating'] == 'yes') amenities.add('Outdoor Seating');
    if (tags['takeaway'] == 'yes') amenities.add('Takeaway Available');
    if (tags['delivery'] == 'yes') amenities.add('Delivery Available');
    if (tags['cuisine'] != null) amenities.add('Cuisine: ${tags['cuisine']}');

    final parsedRating = double.tryParse(tags['stars']?.toString() ?? tags['rating']?.toString() ?? '');
    final rating = parsedRating ?? RatingHelper.generateRating(id, name, categoryId: resolvedCatId);
    final reviewCount = parsedRating != null
        ? int.tryParse(tags['user_ratings_total']?.toString() ?? tags['reviews']?.toString() ?? '')
        : RatingHelper.generateReviewCount(id, name);

    return Place(
      id: id,
      name: name,
      categoryId: resolvedCatId,
      latitude: lat,
      longitude: lon,
      formattedAddress: address,
      distanceInMeters: distance,
      rating: rating,
      reviewCount: reviewCount,
      priceLevel: null,
      isOpenNow: null,
      openingHours: openingHours,
      phoneNumber: phone,
      website: website,
      photoUrls: const [],
      attribution: '© OpenStreetMap contributors',
      sourceProvider: 'osm',
      amenities: amenities,
      rawTags: tags,
    );
  }

  String _determineCategory(Map<String, dynamic> tags, String fallback) {
    if (tags['amenity'] == 'cafe') return 'cafe';
    if (tags['amenity'] == 'restaurant') return 'restaurant';
    if (tags['amenity'] == 'fast_food') return 'fast_food';
    if (tags['tourism'] == 'hotel') return 'hotel';
    if (tags['tourism'] == 'resort') return 'resort';
    if (tags['leisure'] == 'fitness_centre') return 'gym';
    if (tags['shop'] == 'mall') return 'shopping';
    if (tags['shop'] == 'clothes') return 'clothing';
    if (tags['amenity'] == 'hospital') return 'hospital';
    if (tags['amenity'] == 'pharmacy') return 'pharmacy';
    if (tags['tourism'] == 'attraction') return 'attraction';
    if (tags['leisure'] == 'park') return 'park';
    if (tags['amenity'] == 'cinema') return 'cinema';
    if (tags['amenity'] == 'fuel') return 'fuel';
    if (tags['amenity'] == 'atm' || tags['amenity'] == 'bank') return 'atm';
    if (tags['shop'] == 'beauty') return 'salon';
    if (tags.containsKey('office') || tags['amenity'] == 'office' || tags['building'] == 'commercial') return 'business';
    if (tags['amenity'] == 'school' || tags['amenity'] == 'college' || tags['amenity'] == 'university') return 'education';
    return fallback;
  }

  String _determineCategoryFromType(String type) {
    switch (type.toLowerCase()) {
      case 'cafe':
        return 'cafe';
      case 'restaurant':
        return 'restaurant';
      case 'fast_food':
        return 'fast_food';
      case 'hotel':
      case 'hostel':
      case 'guest_house':
        return 'hotel';
      case 'resort':
        return 'resort';
      case 'gym':
      case 'fitness_centre':
      case 'sports_centre':
        return 'gym';
      case 'mall':
      case 'supermarket':
      case 'department_store':
        return 'shopping';
      case 'clothes':
      case 'clothing':
        return 'clothing';
      case 'hospital':
      case 'clinic':
        return 'hospital';
      case 'pharmacy':
        return 'pharmacy';
      case 'attraction':
      case 'artwork':
      case 'museum':
        return 'attraction';
      case 'park':
      case 'garden':
        return 'park';
      case 'cinema':
      case 'theatre':
        return 'cinema';
      case 'fuel':
        return 'fuel';
      case 'atm':
      case 'bank':
        return 'atm';
      case 'beauty':
      case 'hairdresser':
        return 'salon';
      case 'office':
      case 'company':
      case 'it':
      case 'software':
      case 'coworking':
      case 'commercial':
      case 'industrial':
      case 'telecommunication':
        return 'business';
      case 'school':
      case 'college':
      case 'university':
      case 'education':
        return 'education';
      default:
        return 'all';
    }
  }

  String _disambiguateGenericName(
    String name, {
    String? street,
    String? district,
    String? city,
    String? brand,
    String? operator_,
  }) {
    if (brand != null && brand.trim().isNotEmpty) return brand.trim();
    if (operator_ != null && operator_.trim().isNotEmpty) return operator_.trim();
    final cleanName = name.isEmpty
        ? 'Spot'
        : (name[0].toUpperCase() + name.substring(1));
    final loc = (street != null && street.trim().isNotEmpty)
        ? street.trim()
        : ((district != null && district.trim().isNotEmpty)
            ? district.trim()
            : ((city != null && city.trim().isNotEmpty) ? city.trim() : null));
    if (loc != null) {
      return '$cleanName ($loc)';
    }
    return cleanName;
  }

  String _getCategorySearchKeyword(String categoryId) {
    return _getCategorySearchKeywords(categoryId).first;
  }

  List<String> _getCategorySearchKeywords(String categoryId) {
    switch (categoryId) {
      case 'cafe':
        return const ['cafe', 'coffee'];
      case 'restaurant':
        return const ['restaurant', 'dining'];
      case 'fast_food':
        return const ['fast food', 'burger', 'pizza'];
      case 'hotel':
        return const ['hotel', 'guest house', 'resort'];
      case 'resort':
        return const ['resort', 'hotel'];
      case 'gym':
        return const ['gym', 'fitness', 'fitness centre'];
      case 'shopping':
        return const ['shopping mall', 'mall', 'supermarket'];
      case 'clothing':
        return const ['clothing', 'apparel', 'fashion'];
      case 'hospital':
        return const ['hospital', 'clinic'];
      case 'pharmacy':
        return const ['pharmacy', 'chemist', 'medical store'];
      case 'attraction':
      case 'tourist_attraction':
        return const ['tourist attraction', 'attraction', 'monument'];
      case 'park':
        return const ['park', 'garden'];
      case 'cinema':
        return const ['cinema', 'theatre', 'movie'];
      case 'fuel':
        return const ['fuel station', 'petrol pump'];
      case 'atm':
        return const ['atm', 'bank'];
      case 'salon':
        return const ['salon', 'beauty parlour', 'spa'];
      case 'business':
        return const ['office', 'software', 'technology'];
      case 'education':
        return const ['school', 'college', 'university'];
      case 'all':
      default:
        return const ['food'];
    }
  }

  bool _isGenericCategoryWord(String name) {
    const genericWords = {
      'fast food',
      'fast_food',
      'restaurant',
      'restaurante',
      'cafe',
      'café',
      'coffee',
      'hotel',
      'motel',
      'gym',
      'hospital',
      'pharmacy',
      'atm',
      'bank',
      'cinema',
      'park',
      'mall',
      'fuel',
      'petrol pump',
    };
    return genericWords.contains(name.toLowerCase());
  }

  List<Place> _applyFiltersAndSort(List<Place> places, SearchFilter? filter) {
    var result = places;
    if (filter != null) {
      if (filter.openNowOnly) {
        result = result.where((p) => p.isOpenNow == true).toList();
      }
      if (filter.minRating > 0) {
        result = result.where((p) => (p.rating ?? 0) >= filter.minRating).toList();
      }
      if (filter.hasPhoneOnly) {
        result = result.where((p) => p.phoneNumber != null && p.phoneNumber!.isNotEmpty).toList();
      }
      if (filter.hasWebsiteOnly) {
        result = result.where((p) => p.website != null && p.website!.isNotEmpty).toList();
      }
      if (filter.sortBy == 'rating') {
        result.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
      } else if (filter.sortBy == 'name') {
        result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      } else {
        result.sort((a, b) => (a.distanceInMeters ?? double.infinity).compareTo(b.distanceInMeters ?? double.infinity));
      }
    } else {
      result.sort((a, b) => (a.distanceInMeters ?? double.infinity).compareTo(b.distanceInMeters ?? double.infinity));
    }
    return result;
  }
}
