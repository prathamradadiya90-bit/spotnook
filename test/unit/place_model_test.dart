import 'package:flutter_test/flutter_test.dart';
import 'package:spot_finder/features/discovery/domain/entities/place.dart';

void main() {
  group('Place Model Serialization Tests', () {
    test('Serializes to and from JSON correctly', () {
      const place = Place(
        id: 'osm_node_12345',
        name: 'Artisan Cafe',
        categoryId: 'cafe',
        latitude: 21.1702,
        longitude: 72.8311,
        formattedAddress: 'Ring Road, Surat, Gujarat',
        distanceInMeters: 450.0,
        rating: 4.8,
        reviewCount: 120,
        priceLevel: 2,
        isOpenNow: true,
        openingHours: 'Mon-Sun: 08:00 - 22:00',
        phoneNumber: '+919876543210',
        website: 'https://artisancafe.com',
        photoUrls: ['https://example.com/photo1.jpg'],
        attribution: '© OpenStreetMap contributors',
        sourceProvider: 'osm',
        amenities: ['Free Wi-Fi', 'Outdoor Seating'],
        rawTags: {'amenity': 'cafe'},
      );

      final json = place.toJson();
      final restored = Place.fromJson(json);

      expect(restored.id, equals('osm_node_12345'));
      expect(restored.name, equals('Artisan Cafe'));
      expect(restored.categoryId, equals('cafe'));
      expect(restored.category.name, equals('Cafes'));
      expect(restored.latitude, equals(21.1702));
      expect(restored.longitude, equals(72.8311));
      expect(restored.rating, equals(4.8));
      expect(restored.reviewCount, equals(120));
      expect(restored.priceLevel, equals(2));
      expect(restored.isOpenNow, isTrue);
      expect(restored.phoneNumber, equals('+919876543210'));
      expect(restored.amenities, contains('Free Wi-Fi'));
    });

    test('Handles missing nullable fields in fromJson gracefully', () {
      final minimalJson = {
        'id': 'test_min_1',
        'latitude': 21.0,
        'longitude': 72.0,
      };

      final place = Place.fromJson(minimalJson);

      expect(place.id, equals('test_min_1'));
      expect(place.name, equals('Unnamed Place'));
      expect(place.categoryId, equals('all'));
      expect(place.rating, isNull);
      expect(place.reviewCount, isNull);
      expect(place.isOpenNow, isNull);
      expect(place.photoUrls, isEmpty);
      expect(place.amenities, isEmpty);
    });

    test('Defensively handles integer ID, null coordinates, and dynamic rawTags', () {
      final dynamicJson = <dynamic, dynamic>{
        'id': 987654321,
        'name': 'Node Place',
        'latitude': null,
        'longitude': null,
        'rawTags': <dynamic, dynamic>{'cuisine': 'indian', 'delivery': true},
      };

      final place = Place.fromJson(Map<String, dynamic>.from(dynamicJson));

      expect(place.id, equals('987654321'));
      expect(place.name, equals('Node Place'));
      expect(place.latitude, equals(0.0));
      expect(place.longitude, equals(0.0));
      expect(place.rawTags['cuisine'], equals('indian'));
    });
  });
}

