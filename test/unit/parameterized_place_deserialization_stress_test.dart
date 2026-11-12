import 'package:flutter_test/flutter_test.dart';
import 'package:spot_finder/features/discovery/domain/entities/place.dart';

void main() {
  group('Parameterized Place Deserialization Stress Tests', () {
    test('Handles integer, double, String, and scientific notation IDs safely', () {
      final ids = [12345, 99999999999, 1.0, 'node/123456', 'way/78910', '1e6'];

      for (final id in ids) {
        final place = Place.fromJson({
          'id': id,
          'name': 'Test Venue',
          'categoryId': 'cafe',
          'latitude': 21.17,
          'longitude': 72.83,
        });

        expect(place.id, id.toString());
        expect(place.name, 'Test Venue');
      }
    });

    test('Handles missing name, null coordinates, and empty tags safely', () {
      final place = Place.fromJson({});

      expect(place.id, '');
      expect(place.name, 'Unnamed Place');
      expect(place.categoryId, 'all');
      expect(place.latitude, 0.0);
      expect(place.longitude, 0.0);
      expect(place.formattedAddress, '');
      expect(place.distanceInMeters, isNull);
      expect(place.rating, isNull);
      expect(place.reviewCount, isNull);
      expect(place.photoUrls, isEmpty);
      expect(place.amenities, isEmpty);
    });

    test('Preserves Unicode, multilingual, and emoji names accurately', () {
      final names = [
        'カフェ・ド・パリ ☕',
        'મસાલા ચાય સેન્ટર 🫖',
        'مقهى ومطعم المدينة 🌟',
        'Münchner Hofbräuhaus 🍺',
        'Champs-Élysées Bistro & Crêperie 🥖',
        'Seoul Gangnam K-BBQ 🥩',
      ];

      for (final name in names) {
        final place = Place.fromJson({
          'id': 'test_multilingual',
          'name': name,
          'categoryId': 'restaurant',
          'latitude': 21.0,
          'longitude': 72.0,
        });

        expect(place.name, name);
        // Roundtrip serialization check
        final json = place.toJson();
        final restored = Place.fromJson(json);
        expect(restored.name, name);
      }
    });

    test('Defensively processes heterogeneous rawTags maps', () {
      final rawTags = {
        'amenity': 'cafe',
        'cuisine': 'coffee_shop',
        'wheelchair': 'yes',
        'wifi': 'free',
        123: 456, // non-string key and value
        'opening_hours': 'Mo-Fr 08:00-22:00',
      };

      final place = Place.fromJson({
        'id': 'tags_test',
        'name': 'Tags Cafe',
        'rawTags': rawTags,
      });

      expect(place.rawTags['amenity'], 'cafe');
      expect(place.rawTags['123'], 456);
    });

    test('Handles num conversions for ratings, reviewCount, and distance', () {
      final place = Place.fromJson({
        'id': 'numeric_test',
        'name': 'Numeric Spot',
        'rating': 4, // int passed where double expected
        'reviewCount': 152.0, // double passed where int expected
        'distanceInMeters': 350, // int passed where double expected
        'priceLevel': 2.0, // double passed where int expected
      });

      expect(place.rating, 4.0);
      expect(place.reviewCount, 152);
      expect(place.distanceInMeters, 350.0);
      expect(place.priceLevel, 2);
    });
  });
}

