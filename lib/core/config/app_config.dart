/// Application configuration and environment constants.
/// Supports both compile-time defines (`--dart-define`) and default values.
class AppConfig {
  AppConfig._();

  static const String appName = 'Spotnook';
  static const String appVersion = '1.0.0';
  static const int buildNumber = 1;

  // Environment & Build Flavors
  static const bool isReleaseMode = bool.fromEnvironment('dart.vm.product');
  static const String flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  static bool get isProduction => flavor == 'prod' || isReleaseMode;

  // Active Places Provider: 'osm' or 'google'
  static const String defaultProvider = String.fromEnvironment(
    'PLACES_PROVIDER',
    defaultValue: 'osm',
  );

  // Google Places API Key (optional, can also be set dynamically in Settings)
  static const String googlePlacesApiKey = String.fromEnvironment(
    'GOOGLE_PLACES_API_KEY',
    defaultValue: '',
  );

  // Map Tile URL Template (Configurable via --dart-define for commercial/self-hosted tile CDNs)
  static const String mapTileUrl = String.fromEnvironment(
    'MAP_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  // AdMob Application & Unit IDs:
  // In dev flavor: official Google test IDs are used for safe local testing.
  // In prod flavor: real IDs must be injected via build flags (--dart-define).
  static const String _admobTestAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const String _admobTestBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _admobTestInterstitialId = 'ca-app-pub-3940256099942544/1033173712';

  static const String _configuredAppId = String.fromEnvironment('ADMOB_ANDROID_APP_ID', defaultValue: '');
  static const String _configuredBannerId = String.fromEnvironment('ADMOB_BANNER_UNIT_ID', defaultValue: '');
  static const String _configuredInterstitialId = String.fromEnvironment('ADMOB_INTERSTITIAL_UNIT_ID', defaultValue: '');

  static String get admobAppId =>
      _configuredAppId.isNotEmpty ? _configuredAppId : (isProduction ? '' : _admobTestAppId);

  static String get admobBannerUnitId =>
      _configuredBannerId.isNotEmpty ? _configuredBannerId : (isProduction ? '' : _admobTestBannerId);

  static String get admobInterstitialUnitId =>
      _configuredInterstitialId.isNotEmpty ? _configuredInterstitialId : (isProduction ? '' : _admobTestInterstitialId);

  // Support & Compliance
  static const String supportEmail = 'support@spotnook.app';
  static const String privacyPolicyUrl = 'https://spotnook-privacy.vercel.app';
  static const String termsOfServiceUrl = 'https://spotnook-privacy.vercel.app/terms';

  // OpenStreetMap Attribution (Legally required by ODbL)
  static const String osmAttribution = '© OpenStreetMap contributors';
}

