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

    test('3. Prioritizes brand matching over tags', () {
      final domUrl = PlaceImageHelper.getPrimaryImageUrl(
        id: 'place_brand',
        name: "Domino's Pizza",
        categoryId: 'fast_food',
        rawTags: {'brand:wikipedia': "en:Domino's Pizza"},
      );
      expect(domUrl, contains('photo-1590947132387-155cc02f3212'));
    });

    test('4. Resolves authentic original imagery for known brands and chains', () {
      // Domino's Pizza must resolve to authentic pizza, NOT generic fast food
      final dominosUrl = PlaceImageHelper.getPrimaryImageUrl(
        id: 'dom_1',
        name: "Domino's Pizza",
        categoryId: 'fast_food',
      );
      expect(dominosUrl, contains('photo-1590947132387-155cc02f3212'));

      // Cafe Coffee Day must resolve to authentic CCD photography
      final ccdUrl = PlaceImageHelper.getPrimaryImageUrl(
        id: 'ccd_1',
        name: 'Cafe Coffee Day',
        categoryId: 'cafe',
      );
      expect(ccdUrl, contains('upload.wikimedia.org/wikipedia/commons/c/c2/Cafe_coffee_day_cyber_hub_phase_3.jpg'));

      // The Shake Maker must resolve to thickshake
      final shakeUrl = PlaceImageHelper.getPrimaryImageUrl(
        id: 'sm_1',
        name: 'The Shake Maker',
        categoryId: 'cafe',
      );
      expect(shakeUrl, contains('photo-1572490122747-3968b75cc699'));

      // Simply South must resolve to authentic Masala Dosa
      final southUrl = PlaceImageHelper.getPrimaryImageUrl(
        id: 'ss_1',
        name: 'Simply South',
        categoryId: 'restaurant',
      );
      expect(southUrl, contains('photo-1668236543090-82eba5ee5976'));

      // Gokulam Dairy must resolve to dairy & milk
      final dairyUrl = PlaceImageHelper.getPrimaryImageUrl(
        id: 'gd_1',
        name: 'Gokulam Dairy',
        categoryId: 'shopping',
      );
      expect(dairyUrl, contains('photo-1528750997573-59b89d56f4f7'));
    });

    test('5. Resolves semantic specialty and cuisine keywords accurately', () {
      final pizzaSpot = PlaceImageHelper.getPrimaryImageUrl(
        id: 'p_1',
        name: 'Artisan Woodfired Pizza',
        categoryId: 'restaurant',
      );
      expect(pizzaSpot, contains('photo-1513104890138-7c749659a591'));

      final biryaniSpot = PlaceImageHelper.getPrimaryImageUrl(
        id: 'b_1',
        name: 'Royal Dum Biryani House',
        categoryId: 'restaurant',
      );
      expect(biryaniSpot, contains('photo-1563379091339-03b21ab4a4f8'));
    });

    test('6. Generates high-resolution real photography for all categories deterministically', () {
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

    test('7. Place domain entity exposes primaryImageUrl seamlessly', () {
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
