/// API Endpoints and Network Constants
class ApiConstants {
  ApiConstants._();

  // OpenStreetMap Nominatim for Geocoding & Reverse Geocoding
  // Complies with Nominatim Usage Policy (custom User-Agent & max 1 req/sec)
  static const String nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  static const String nominatimSearch = '/search';
  static const String nominatimReverse = '/reverse';

  // Overpass API for live venue discovery (Cafes, Restaurants, Hotels, etc.)
  static const String overpassBaseUrl = 'https://overpass-api.de/api/interpreter';

  // Open-Source Photon Geocoder (Fast autocomplete based on OSM)
  static const String photonBaseUrl = 'https://photon.komoot.io/api';

  // Google Places API (New) Endpoints
  static const String googlePlacesBaseUrl = 'https://places.googleapis.com/v1';
  static const String googlePlacesTextSearch = '/places:searchText';
  static const String googlePlacesNearbySearch = '/places:searchNearby';

  // User Agent header required for Nominatim policy
  static const String appUserAgent = 'SpotnookAndroid/1.0 (contact: support@spotnook.app)';

  // Network Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);
}

