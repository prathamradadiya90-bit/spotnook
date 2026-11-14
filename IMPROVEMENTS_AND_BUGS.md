# Spotnook — Improvements, Feature Roadmap & Known Issues Audit

This document provides a prioritized catalog of potential bugs, edge cases, technical debt, performance optimizations, and user experience enhancements for **Spotnook** (`com.spotnook.app`).

---

## 1. High Priority (Play Store & Production Readiness)

### 1.1 Replace Test AdMob IDs with Production IDs
- **Status / Severity:** Important before public production rollout.
- **Current Behavior:** 
  - `android/app/build.gradle.kts` uses Google's test application ID (`ca-app-pub-3940256099942544~3347511713`).
  - `lib/core/config/app_config.dart` silences ads in release mode if `--dart-define=ADMOB_ANDROID_APP_ID=...` is not passed.
- **Action Needed:**
  1. Create an AdMob account and set up Android app units for Banner and Interstitial.
  2. Pass real keys when building production bundles:
     ```bash
     flutter build appbundle --release \
       --dart-define=ADMOB_ANDROID_APP_ID="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX" \
       --dart-define=ADMOB_BANNER_UNIT_ID="ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX" \
       --dart-define=ADMOB_INTERSTITIAL_UNIT_ID="ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"
     ```
  3. Ensure European Union (EEA) and UK UMP consent forms are configured in the Google AdMob dashboard.

### 1.2 OpenStreetMap (OSM) Tile CDN & Usage Policy
- **Status / Severity:** Medium-High (Scalability / Terms of Service).
- **Current Behavior:** The app fetches map tiles directly from `https://tile.openstreetmap.org/{z}/{x}/{y}.png`.
- **Policy Risk:** The OpenStreetMap Foundation tile servers operate on donated resources and have a strict Tile Usage Policy that discourages high-volume production mobile applications.
- **Recommended Solution:**
  - Transition tile requests to a free/low-cost commercial tile provider or self-hosted CDN (e.g., **MapTiler**, **Stadia Maps**, **Jawg Maps**, or **Protomaps**).
  - Use the built-in `--dart-define=MAP_TILE_URL="https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=YOUR_KEY"` configuration without modifying Dart code.

### 1.3 Localization Gaps (Gujarati & Hindi ARB)
- **Status / Severity:** Medium.
- **Current Behavior:** Older screens have translations in `lib/l10n/app_gu.arb` and `lib/l10n/app_hi.arb`, but newer features (Mood Chips, "Spot of the Day", "Surprise Me", Explorer XP Gamification, and Location Disclosure Dialogs) contain hardcoded English strings.
- **Action Needed:**
  - Add keys to `lib/l10n/app_en.arb`, `lib/l10n/app_gu.arb`, and `lib/l10n/app_hi.arb`.
  - Replace hardcoded string literals with `AppLocalizations.of(context)!.<key>`.

---

## 2. Technical Debt & Build System Warnings

### 2.1 AGP 9.0 Built-in Kotlin Migration
- **Status / Severity:** Low-Medium (Will become blocking in Gradle 10 / AGP 10).
- **Warning in Build Logs:**
  ```text
  The option setting 'android.builtInKotlin=false' is deprecated.
  The 'org.jetbrains.kotlin.android' plugin in project ':app' is no longer required for Kotlin support since AGP 9.0.
  ```
- **Action Needed:**
  - Update `android/gradle.properties`: remove `android.builtInKotlin=false` and `android.newDsl=false`.
  - When Flutter updates its Gradle plugins, migrate from `org.jetbrains.kotlin.android` to AGP's built-in Kotlin compilation.
  - Monitor `share_plus` updates on pub.dev to ensure compatibility when Flutter drops KGP.

### 2.2 ProGuard Rules for Future Plugins
- **Status / Severity:** Maintained & Verified.
- **Current State:** `android/app/proguard-rules.pro` was hardened with keep rules for Room Database (`androidx.work.impl.WorkDatabase_Impl`), WorkManager, Tink, Google Play UMP, and Geolocator.
- **Future Precaution:** When adding new native or reflection-heavy Flutter packages (e.g., Firebase, RevenueCat, SQLite extensions), always test the `--release` APK on a real device/emulator before shipping to prevent R8 stripping runtime constructors.

---

## 3. UI/UX & User Experience Enhancements

### 3.1 Network Connectivity Auto-Retry
- **Status / Severity:** User Experience.
- **Current Behavior:** If internet access drops, searches or map tile loading will fail and show an error state. The user must manually pull-to-refresh or tap "Retry".
- **Enhancement:**
  - Add `connectivity_plus` dependency.
  - Listen to network state transitions (`none` -> `wifi`/`mobile`) and automatically re-trigger failed place queries and reload visible map tiles.

### 3.2 Advanced Map Marker Clustering (`supercluster`)
- **Status / Severity:** Performance & Visual Polish.
- **Current State:** MapScreen includes a custom lightweight grid-clustering algorithm (`_clusterPlaces`).
- **Enhancement:**
  - Integrate `flutter_map_marker_cluster` or `supercluster` for smooth animated clustering, expand-on-tap bounds animations, and visual cluster badge indicators when zooming out.

### 3.3 In-App Review Prompt
- **Status / Severity:** Growth / Play Store Rating.
- **Enhancement:**
  - Integrate `in_app_review` package.
  - Trigger `InAppReview.instance.requestReview()` at moments of high user satisfaction:
    - After a user bookmarks their 5th place.
    - After reaching Level 3 ("Avid Explorer") in the Explorer stats module.
  - Strictly adhere to Google Play guidelines (never prompt on errors or interrupt primary navigation flows).

### 3.4 In-App Update Checker
- **Status / Severity:** Maintenance & User Retention.
- **Enhancement:**
  - Integrate `in_app_update` package.
  - Check for flexible or immediate updates on app startup so users on older versions are notified when a new update is released on the Play Store.

### 3.5 Dynamic Search Radius Expansion
- **Status / Severity:** User Experience / Discovery.
- **Current Behavior:** If a user searches in a rural or low-density neighborhood where Overpass returns 0 results within the default bounding box, an empty state is shown.
- **Enhancement:**
  - Implement progressive radius expansion: if 0 spots found within 5 km, automatically suggest: *"No spots found within 5 km. Expand search to 15 km?"* with a 1-tap button.

---

## 4. API Resilience & Backend Failover

### 4.1 Overpass API Dynamic Failover & Rate Limiting
- **Status / Severity:** Reliability.
- **Current State:** Primary requests hit Overpass (`overpass-api.de` with fallback to `overpass.kumi.systems`) and Photon/Nominatim for search.
- **Enhancement:**
  - Implement an endpoint health-check circuit breaker in `overpass_service.dart`.
  - Rotate dynamically between available public Overpass endpoints (`de`, `kumi.systems`, `openstreetmap.fr`) when an HTTP 429 (Too Many Requests) or 504 (Gateway Timeout) occurs.

### 4.2 SQLite Offline Caching Layer
- **Status / Severity:** Offline Resilience.
- **Current State:** Memory cache (`places_cache_service.dart`) caches places per session with LRU eviction. Bookmarks are persisted in `shared_preferences`.
- **Enhancement:**
  - For frequent cities or favorited spots, persist full place JSON metadata and thumbnail images into local SQLite (`sqflite`), enabling browsing saved and recently viewed venues even in airplane mode.

---

## 5. Summary Matrix & Implementation Priority

| Feature / Issue | Area | Priority | Effort | Impact |
|---|---|:---:|:---:|:---:|
| **AdMob Production IDs injection** | Monetization / Play Store | High | 30 mins | High |
| **OpenStreetMap Tile CDN setup** | Infrastructure / Policy | High | 1 hr | High |
| **Localization strings completion** | Internationalization | Medium | 2 hrs | Medium |
| **In-App Review (`in_app_review`)** | Growth / ASO | Medium | 1 hr | High |
| **Dynamic search radius expansion** | UX / Discovery | Medium | 2 hrs | Medium |
| **Network connectivity listener** | Reliability | Medium | 1.5 hrs | Medium |
| **Map marker animated clustering** | UI / Performance | Low-Medium | 3 hrs | Medium |
| **In-App Update prompt (`in_app_update`)** | User Retention | Low-Medium | 1 hr | Medium |
| **AGP 9 / Gradle 10 Built-in Kotlin cleanup** | Build System | Low | 1 hr | Low |
| **Offline SQLite venue cache** | Offline Support | Low | 4 hrs | Medium |

---

## 6. Real Venue Photography & Multi-Tier Resolution (Completed & Verified)

- **Status:** **Completed & Verified in Production Builds**
- **Architecture:** Implemented `PlaceImageHelper` ([lib/core/utils/place_image_helper.dart](file:///d:/Downloads/scapper/lib/core/utils/place_image_helper.dart)):
  1. **Tier 1:** Upstream verified photos from provider (Google Places / user-submitted).
  2. **Tier 2:** OpenStreetMap direct tags (`image`, `image:0`, `photo`, and Wikimedia Commons `File:` / `Special:FilePath`).
  3. **Tier 3:** High-resolution authentic real photography catalog (15+ categories: Cafe, Restaurant, Fast Food, Hotel, Resort, Gym, Park, Shopping, Bar, Cinema, Attraction, etc.) deterministically resolved per venue ID & name.
- **Surface Coverage:**
  - `PlaceCard` (Home list, Search results, Category views)
  - `PlaceCompactCard` (Horizontal trending carousels & recently viewed)
  - `SpotOfTheDayCard` (Featured daily discovery hero banner)
  - `MapPreviewSheet` (Bottom sheet venue preview on interactive map)
  - `PlaceDetailScreen` (Hero photo and multi-image photo gallery carousel)
- **Verification:**
  - 223/223 Unit Tests passed (`flutter test test/unit/`)
  - 17/17 Widget Tests passed (`flutter test test/widget/`)
  - User Journey Integration Test passed (`flutter test test/integration/user_journey_test.dart`)
  - Live Browser Verified on Web (`http://127.0.0.1:8092/`)
  - Release AAB (`Spotnook-v1.0.0.aab`) & Release APK (`Spotnook-v1.0.0.apk`) built and verified.


