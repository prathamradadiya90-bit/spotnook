# PROJECT AUDIT: SPOTFINDER (PREMIUM LOCATION DISCOVERY APP)

**Date of Audit:** November 8, 2026  
**Auditor:** Principal Android Engineer & Security Specialist  
**Application Target:** Android (Google Play Store Production)  
**Package Name:** `com.spotfinder.app`  

---

## 1. Executive Summary

This audit assesses the state of the workspace `d:\Downloads\scapper`, evaluates development tooling, establishes architecture requirements, and identifies security, compliance, and UI/UX benchmarks for building a world-class, production-ready Location Discovery & Place Finder Android application.

The project environment was initialized cleanly using Flutter 3.47.5 (Dart 3.13.4, stable channel). Gradle 9.3.1 with Android SDK 36.0.0 and OpenJDK 21 is confirmed and configured.

---

## 2. Environment & Tooling Audit

| Component | Detected Version / Status | Evaluation |
|---|---|---|
| **Flutter SDK** | 3.47.5 (Channel stable) | Excellent; latest stable release |
| **Dart SDK** | 3.13.4 | Null safety enabled, full modern features |
| **Android SDK** | Version 36.0.0 (`D:\Android\Sdk`) | Fully installed with build-tools 34, 35, 36 |
| **JDK** | OpenJDK 21.0.4 (Android Studio JBR) | Configured & verified with Gradle 9.3.1 |
| **Gradle** | 9.3.1 | High-performance build toolchain |
| **Host OS** | Windows 11 (25H2 x64) | Development & build environment verified |

---

## 3. Architecture & Dependency Strategy

### Recommended Dependencies
- **State Management:** `flutter_riverpod` (^2.6.1) for reactive, testable, decoupled state management without BuildContext coupling.
- **Routing:** `go_router` (^14.8.1) for declarative, deep-link ready navigation with nested shell routes (Explore, Map, Saved, Settings).
- **Networking:** `dio` (^5.8.0) with custom interceptors for timeouts, retry policies with exponential backoff, rate limiting, and structured logging.
- **Mapping & Geo Visualization:** `flutter_map` (^7.0.2) and `latlong2` (^0.9.1) for high-performance, interactive, zero-rate-limit OpenStreetMap rendering, alongside support for Google Maps SDK and custom tile servers.
- **Location Services:** `geolocator` (^13.0.2) with strict foreground permission checks and graceful fallback when location permissions are denied.
- **Local Persistence:** `shared_preferences` (^2.3.5) and `flutter_secure_storage` (^9.2.4) for user-owned bookmarks, search history, custom notes, and securely stored API keys.
- **AdMob Monetization:** `google_mobile_ads` (^5.3.0) with official Google test ad unit IDs, frequency capping, UMP consent integration, and strict separation of UI from ad loading.
- **Utility & UI:** `cached_network_image`, `url_launcher`, `share_plus`, `intl`.

---

## 4. Security & Compliance Findings

1. **No Scraping Policy:** The application strictly adheres to Google Play terms and third-party terms of service. Absolutely NO web scraping of Google Maps, search engines, or social media.
2. **Authorized Data Sources:**
   - **OpenStreetMap / Overpass API / Nominatim:** Open Database License (ODbL) compliant with mandatory attribution (`© OpenStreetMap contributors`), user-agent identification, and request throttling.
   - **Google Places API (New):** Clean client integration with proper attribution, photo attributions, Place ID storage compliance (storing Place IDs is permitted; bulk caching of place details is prohibited).
3. **Permissions Safety:**
   - `ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION` requested ONLY in foreground after clear in-app rationale dialog.
   - **NO** `ACCESS_BACKGROUND_LOCATION` to guarantee Play Store safety.
   - App remains 100% functional without location permission through manual city selection and map panning.
4. **AdMob Placement Integrity:**
   - No launch interstitials.
   - No map obstruction.
   - All banners clearly marked with "Ad" or "Sponsored".

---

## 5. Next Steps

Proceed directly to implementing the Clean Architecture structure, foundational models, repositories, UI design system, and automated tests.

