import 'package:flutter_test/flutter_test.dart';
import 'package:spot_finder/core/network/network_exceptions.dart';
import 'package:spot_finder/features/discovery/data/datasources/google_places_service.dart';

void main() {
  group('GooglePlacesService Unit Tests', () {
    test('Throws UnauthorizedException if API key is empty', () async {
      final service = GooglePlacesService(apiKey: '');
      expect(service.hasValidApiKey, isFalse);

      expect(
        () => service.searchPlaces(
          query: 'Coffee',
          latitude: 21.1702,
          longitude: 72.8311,
        ),
        throwsA(isA<UnauthorizedException>()),
      );

      expect(
        () => service.getNearbyPlaces(
          latitude: 21.1702,
          longitude: 72.8311,
        ),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('updateApiKey correctly updates key and valid status', () {
      final service = GooglePlacesService(apiKey: '');
      expect(service.hasValidApiKey, isFalse);

      service.updateApiKey('AIzaSyTestKey123');
      expect(service.hasValidApiKey, isTrue);
      expect(service.apiKey, equals('AIzaSyTestKey123'));
    });
  });
}

