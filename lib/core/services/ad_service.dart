import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/app_config.dart';

/// AdMob Monetization Manager.
/// Adheres strictly to Google Play Ads Policy and EEA/UK UMP Consent requirements:
/// - Mandatory Google UMP Consent check before initializing ads.
/// - Privacy settings entry to re-trigger consent options.
/// - No ads on app launch.
/// - No ad interruption of map interactions or place navigation.
/// - Frequency capped interstitials at natural screen transitions.
/// - Non-blocking asynchronous loading with graceful error recovery.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _isInitialized = false;
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;

  // Frequency capping state
  DateTime? _lastInterstitialShownAt;
  int _placesViewedCount = 0;
  static const int _minPlaceViewsBeforeInterstitial = 4;
  static const Duration _minInterstitialInterval = Duration(minutes: 3);

  /// Initializes the Google Mobile Ads SDK with Google UMP consent flow.
  Future<void> initialize({bool requestConsent = true}) async {
    if (_isInitialized) return;

    if (kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }

    if (requestConsent) {
      final completer = Completer<void>();
      final params = ConsentRequestParameters();

      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          ConsentForm.loadAndShowConsentFormIfRequired((formError) async {
            if (formError != null) {
              debugPrint('[AdService] Consent form error: ${formError.message}');
            }
            if (await ConsentInformation.instance.canRequestAds()) {
              await _initMobileAds();
            }
            if (!completer.isCompleted) completer.complete();
          });
        },
        (error) async {
          debugPrint('[AdService] Consent info update failed: ${error.message}');
          if (await ConsentInformation.instance.canRequestAds()) {
            await _initMobileAds();
          }
          if (!completer.isCompleted) completer.complete();
        },
      );

      // Safe fallback timeout (max 4s) so app launch is never indefinitely stalled
      await completer.future.timeout(
        const Duration(seconds: 4),
        onTimeout: () async {
          if (await ConsentInformation.instance.canRequestAds()) {
            await _initMobileAds();
          }
        },
      );
    } else {
      await _initMobileAds();
    }
  }

  Future<void> _initMobileAds() async {
    if (_isInitialized) return;
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      _preloadInterstitial();
    } catch (e) {
      debugPrint('[AdService] MobileAds init failed: $e');
    }
  }

  /// Opens the Google UMP Privacy Options form so users can review or revoke consent.
  Future<void> showPrivacyOptionsForm(BuildContext context) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Privacy consent form is managed on mobile platforms.')),
      );
      return;
    }

    ConsentForm.showPrivacyOptionsForm((formError) {
      if (formError != null) {
        debugPrint('[AdService] Privacy options error: ${formError.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Consent form: ${formError.message}')),
        );
      }
    });
  }

  /// Banner Unit ID loaded via AppConfig flavors.
  String get bannerAdUnitId {
    if (kIsWeb) return '';
    return AppConfig.admobBannerUnitId;
  }

  /// Interstitial Unit ID loaded via AppConfig flavors.
  String get interstitialAdUnitId {
    if (kIsWeb) return '';
    return AppConfig.admobInterstitialUnitId;
  }

  /// Preloads an interstitial ad in the background.
  void _preloadInterstitial() {
    if (interstitialAdUnitId.isEmpty) return;
    if (_interstitialAd != null || _isInterstitialLoading) return;
    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _preloadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              _preloadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isInterstitialLoading = false;
          debugPrint('[AdService] Interstitial failed to load: ${error.message}');
        },
      ),
    );
  }

  /// Records a place view and displays an interstitial ONLY if frequency cap criteria are satisfied.
  /// Never blocks or freezes the user journey.
  void recordPlaceViewAndMaybeShowInterstitial() {
    _placesViewedCount++;

    final now = DateTime.now();
    final intervalPassed = _lastInterstitialShownAt == null ||
        now.difference(_lastInterstitialShownAt!) >= _minInterstitialInterval;

    if (_placesViewedCount >= _minPlaceViewsBeforeInterstitial && intervalPassed) {
      if (_interstitialAd != null) {
        _lastInterstitialShownAt = now;
        _placesViewedCount = 0;
        _interstitialAd!.show();
      } else {
        _preloadInterstitial();
      }
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}

