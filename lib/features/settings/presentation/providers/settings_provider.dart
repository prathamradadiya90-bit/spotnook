import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/api_constants.dart';
import '../../../../core/config/app_config.dart';

/// User settings state class.
class SettingsState {
  final ThemeMode themeMode;
  final String provider; // 'osm' or 'google'
  final String googleApiKey;
  final bool useMiles;
  final double defaultRadiusMeters;
  final String overpassBaseUrl;
  final String photonBaseUrl;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.provider = 'osm',
    this.googleApiKey = '',
    this.useMiles = false,
    this.defaultRadiusMeters = 5000.0,
    this.overpassBaseUrl = ApiConstants.overpassBaseUrl,
    this.photonBaseUrl = ApiConstants.photonBaseUrl,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? provider,
    String? googleApiKey,
    bool? useMiles,
    double? defaultRadiusMeters,
    String? overpassBaseUrl,
    String? photonBaseUrl,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      provider: provider ?? this.provider,
      googleApiKey: googleApiKey ?? this.googleApiKey,
      useMiles: useMiles ?? this.useMiles,
      defaultRadiusMeters: defaultRadiusMeters ?? this.defaultRadiusMeters,
      overpassBaseUrl: overpassBaseUrl ?? this.overpassBaseUrl,
      photonBaseUrl: photonBaseUrl ?? this.photonBaseUrl,
    );
  }
}

/// SharedPreferences provider.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize sharedPreferencesProvider in main()');
});

/// FlutterSecureStorage provider for sensitive secrets.
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});

/// Settings notifier managing persistent user preferences, self-hosting endpoints,
/// and secure storage of sensitive credentials.
class SettingsNotifier extends StateNotifier<SettingsState> {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  static const String _themeKey = 'spotfinder_pref_theme';
  static const String _providerKey = 'spotfinder_pref_provider';
  static const String _googleKeyFallback = 'spotfinder_pref_google_key';
  static const String _secureGoogleKey = 'spotfinder_secure_google_places_api_key';
  static const String _unitKey = 'spotfinder_pref_use_miles';
  static const String _radiusKey = 'spotfinder_pref_default_radius';
  static const String _overpassUrlKey = 'spotfinder_pref_overpass_url';
  static const String _photonUrlKey = 'spotfinder_pref_photon_url';

  SettingsNotifier(this._prefs, this._secureStorage) : super(const SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final themeStr = _prefs.getString(_themeKey) ?? 'system';
    final themeMode = _parseThemeMode(themeStr);

    final provider = _prefs.getString(_providerKey) ?? AppConfig.defaultProvider;
    final useMiles = _prefs.getBool(_unitKey) ?? false;
    final radius = _prefs.getDouble(_radiusKey) ?? 5000.0;
    final overpassUrl = _prefs.getString(_overpassUrlKey) ?? ApiConstants.overpassBaseUrl;
    final photonUrl = _prefs.getString(_photonUrlKey) ?? ApiConstants.photonBaseUrl;

    // Load Google API Key securely from flutter_secure_storage on mobile; fallback to prefs on web
    String googleKey = '';
    if (!kIsWeb) {
      try {
        googleKey = await _secureStorage.read(key: _secureGoogleKey) ?? '';
      } catch (_) {
        googleKey = _prefs.getString(_googleKeyFallback) ?? AppConfig.googlePlacesApiKey;
      }
    } else {
      googleKey = _prefs.getString(_googleKeyFallback) ?? AppConfig.googlePlacesApiKey;
    }

    state = SettingsState(
      themeMode: themeMode,
      provider: provider,
      googleApiKey: googleKey,
      useMiles: useMiles,
      defaultRadiusMeters: radius,
      overpassBaseUrl: overpassUrl,
      photonBaseUrl: photonUrl,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setString(_themeKey, mode.name);
  }

  Future<void> setProvider(String provider) async {
    state = state.copyWith(provider: provider);
    await _prefs.setString(_providerKey, provider);
  }

  Future<void> setGoogleApiKey(String key) async {
    final cleanKey = key.trim();
    state = state.copyWith(googleApiKey: cleanKey);

    if (!kIsWeb) {
      if (cleanKey.isEmpty) {
        await _secureStorage.delete(key: _secureGoogleKey);
      } else {
        await _secureStorage.write(key: _secureGoogleKey, value: cleanKey);
      }
    } else {
      await _prefs.setString(_googleKeyFallback, cleanKey);
    }
  }

  Future<void> setUseMiles(bool useMiles) async {
    state = state.copyWith(useMiles: useMiles);
    await _prefs.setBool(_unitKey, useMiles);
  }

  Future<void> setDefaultRadius(double radius) async {
    state = state.copyWith(defaultRadiusMeters: radius);
    await _prefs.setDouble(_radiusKey, radius);
  }

  Future<void> setOverpassBaseUrl(String url) async {
    final cleanUrl = url.trim().isEmpty ? ApiConstants.overpassBaseUrl : url.trim();
    state = state.copyWith(overpassBaseUrl: cleanUrl);
    await _prefs.setString(_overpassUrlKey, cleanUrl);
  }

  Future<void> setPhotonBaseUrl(String url) async {
    final cleanUrl = url.trim().isEmpty ? ApiConstants.photonBaseUrl : url.trim();
    state = state.copyWith(photonBaseUrl: cleanUrl);
    await _prefs.setString(_photonUrlKey, cleanUrl);
  }

  Future<void> resetEndpointsToDefault() async {
    state = state.copyWith(
      overpassBaseUrl: ApiConstants.overpassBaseUrl,
      photonBaseUrl: ApiConstants.photonBaseUrl,
    );
    await _prefs.remove(_overpassUrlKey);
    await _prefs.remove(_photonUrlKey);
  }

  /// Completely wipes secure storage and SharedPreferences on user request.
  Future<void> clearAllStoredCredentials() async {
    if (!kIsWeb) {
      try {
        await _secureStorage.deleteAll();
      } catch (_) {}
    }
    await _prefs.remove(_googleKeyFallback);
    state = state.copyWith(googleApiKey: '');
  }

  ThemeMode _parseThemeMode(String name) {
    switch (name) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final secure = ref.watch(secureStorageProvider);
  return SettingsNotifier(prefs, secure);
});
