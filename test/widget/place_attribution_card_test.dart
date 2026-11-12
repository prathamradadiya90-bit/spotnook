import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spot_finder/features/discovery/domain/entities/place.dart';
import 'package:spot_finder/features/place_detail/presentation/widgets/place_attribution_card.dart';

void main() {
  group('PlaceAttributionCard Widget Tests', () {
    testWidgets('Displays OpenStreetMap compliance attribution for OSM places', (tester) async {
      const place = Place(
        id: 'osm_1',
        name: 'Historic Library',
        categoryId: 'attraction',
        latitude: 21.17,
        longitude: 72.83,
        formattedAddress: 'Main St, Surat',
        sourceProvider: 'osm',
        attribution: '© OpenStreetMap contributors',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PlaceAttributionCard(place: place),
          ),
        ),
      );

      expect(find.text('Verified Place Information'), findsOneWidget);
      expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
    });

    testWidgets('Displays Google Places attribution when provider is google', (tester) async {
      const place = Place(
        id: 'google_1',
        name: 'Grand Hyatt',
        categoryId: 'hotel',
        latitude: 21.17,
        longitude: 72.83,
        formattedAddress: 'Highway, Surat',
        sourceProvider: 'google',
        attribution: 'Powered by Google Places',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PlaceAttributionCard(place: place),
          ),
        ),
      );

      expect(find.text('Powered by Google Places'), findsOneWidget);
    });
  });
}

