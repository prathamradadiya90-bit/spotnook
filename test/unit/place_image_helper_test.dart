import 'package:flutter_test/flutter_test.dart';
import 'package:spot_finder/core/utils/place_image_helper.dart';
import 'package:spot_finder/features/discovery/domain/entities/place.dart';

void main() {
  group('PlaceImageHelper Unit Tests', () {
    test('1. Prioritizes verified upstream photoUrls when available', () {
      const customUrl = 'https://example.com/verified_place_photo.jpg';
      final url = PlaceImageHelper.getPrimaryImageUrl(
        id: 'place_123',
        name: 'My Special Cafe',
        categoryId: 'cafe',
        photoUrls: [customUrl],
      );

      expect(url, equals(customUrl));
    });

    test('2. Extracts direct image from OSM tags when present', () {
      const osmImageUrl = 'https://upload.wikimedia.org/wikipedia/commons/test.jpg';
      final url = PlaceImageHelper.getPrimaryImageUrl(
        id: 'place_osm',
        name: 'Historic Fort',
        categoryId: 'attraction',
        rawTags: {'image': osmImageUrl},
      );

      expect(url, equals(osmImageUrl));
    });

    test('3. Formats wikimedia_commons tag into valid FilePath URL', () {
      final url = PlaceImageHelper.getPrimaryImageUrl(
        id: 'place_wiki',
        name: 'City Museum',
        categoryId: 'attraction',
        rawTags: {'wikimedia_commons': 'File:City_Museum_Main.jpg'},
      );

      expect(url, contains('commons.wikimedia.org/wiki/Special:FilePath/City_Museum_Main.jpg'));
    });

    test('4. Generates high-resolution real photography for all categories deterministically', () {
      const categories = [
        'cafe',
        'restaurant',
        'fast_food',
        'hotel',
        'resort',
        'gym',
        'shopping',
        'clothing',
        'hospital',
        'pharmacy',
        'attraction',
        'park',
        'cinema',
        'fuel',
        'atm',
        'salon',
        'business',
        'education',
        'all',
      ];

      for (final cat in categories) {
        final url1 = PlaceImageHelper.getPrimaryImageUrl(
          id: 'venue_1',
          name: 'Spot Alpha',
          categoryId: cat,
        );

        final url2 = PlaceImageHelper.getPrimaryImageUrl(
          id: 'venue_1',
          name: 'Spot Alpha',
          categoryId: cat,
        );

        expect(url1, startsWith('https://images.unsplash.com/photo-'));
        expect(url1, equals(url2), reason: 'Image selection must be stable and deterministic');
      }
    });

    test('5. Place domain entity exposes primaryImageUrl seamlessly', () {
      const place = Place(
        id: 'p99',
        name: 'The Espresso House',
        categoryId: 'cafe',
        latitude: 21.17,
        longitude: 72.83,
        formattedAddress: 'Surat, Gujarat',
      );

      expect(place.primaryImageUrl, startsWith('https://images.unsplash.com/photo-'));
      expect(place.galleryImageUrls.length, greaterThanOrEqualTo(2));
    });
  });
}

