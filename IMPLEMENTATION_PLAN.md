# IMPLEMENTATION PLAN: SPOTFINDER

## 1. Overview & Objectives

Deliver a complete, production-grade Android Location Discovery application meeting all requirements from the Master Prompt:
- Real-time place discovery for 18+ categories (Cafes, Restaurants, Hotels, Gyms, Shopping, Hospitals, Attractions, etc.)
- Multi-mode location selection (GPS foreground, manual city/neighborhood search, interactive map pin drop)
- Interactive map with dynamic markers, clustering, area re-search, and bottom preview cards
- Seamless Map <-> List view toggle
- Rich place details (real phone, website, opening hours, ratings, distance, accessibility, required attributions)
- Directions launcher for external navigation apps (Google Maps, Waze, OsmAnd, Apple Maps/System)
- User-owned favorites, custom lists, search history, and privacy-first local persistence
- Responsible Google AdMob integration (Adaptive Banner, Interstitial on natural transitions, test IDs configured)
- Complete Google Play Store compliance, Data Safety declarations, and in-app Privacy Policy
- Comprehensive automated test suite (Unit, Widget, and Repository integration tests)

---

## 2. Phase-by-Phase Roadmap

### Phase 1: Core Setup & Dependency Configuration
- Update `pubspec.yaml` with stable dependencies (`flutter_riverpod`, `go_router`, `dio`, `flutter_map`, `latlong2`, `geolocator`, `shared_preferences`, `flutter_secure_storage`, `url_launcher`, `share_plus`, `google_mobile_ads`, `cached_network_image`, `intl`).
- Configure Android `AndroidManifest.xml` with proper foreground location permissions, hardware acceleration, network security config, and AdMob application ID.
- Create `.env.example` documenting all configuration keys.

### Phase 2: Domain Layer & Core Abstractions
- Define core entities: `Place`, `PlaceLocation`, `PlaceCategory`, `OpeningHours`, `PlaceBookmark`, `SearchFilter`.
- Define `PlacesRepository` interface supporting:
  - `searchPlaces(query, location, radius, category, filter)`
  - `getNearbyPlaces(location, radius, category)`
  - `getPlaceDetails(placeId)`
  - `reverseGeocode(location)`
  - `searchLocations(query)`
  - `getRouteDirections(origin, destination, mode)`

### Phase 3: Data Layer & API Integrations
- Implement `OverpassPlacesService` (live OpenStreetMap Overpass API for real venues with names, cuisines, opening hours, phones, websites, addresses).
- Implement `NominatimGeocodingService` (live geocoding & reverse geocoding with user-agent attribution and debounce).
- Implement `GooglePlacesService` (Google Places API New integration with API Key fallback).
- Implement `UnifiedPlacesRepository` delegating to active provider with caching and error handling.
- Implement `LocalBookmarkRepository` and `SearchHistoryRepository` with persistent storage.

### Phase 4: State Management & Business Logic (Riverpod)
- Location Provider: manages active coordinate, selected city/neighborhood name, permission status.
- Places Discovery Provider: reactive search query, category selection, distance radius, filters.
- Bookmarks & History Providers: reactive favorites list with categorization and toggle.
- Settings Provider: dark/light theme, active provider, measurement units (km/mi), distance filter.

### Phase 5: Design System & Reusable Components
- Typography, color system (Aegean Teal `#008080`, Slate `#0F172A`, Amber `#F59E0B`, Emerald `#10B981`).
- Custom components: `SpotSearchBar`, `CategoryChipGroup`, `PlaceCard`, `PlaceCompactCard`, `RatingBadge`, `DistanceBadge`, `EmptyStateWidget`, `ErrorRetryWidget`, `ShimmerLoader`.
- Map components: `InteractiveMapView`, `CustomMapMarker`, `MapPreviewSheet`, `SearchThisAreaButton`.

### Phase 6: Screen Implementations
- **HomeScreen (Explore):** Greeting, active location pill, search trigger, category slider, nearby spots carousel, popular collections, recent discoveries.
- **MapScreen:** Full-screen interactive map, filter bar, map/list switch, markers, bottom preview card, re-center GPS.
- **SearchScreen:** Instant autocomplete, recent searches, filter modal, paginated result list.
- **PlaceDetailScreen:** Hero image sliver, action buttons (call, navigate, web, share, save), address with copy, opening schedule, amenities, attribution info.
- **SavedScreen:** Bookmarked places, filter tabs, note editor, swipe-to-delete with undo.
- **SettingsScreen:** Theme switch, unit preference, provider switch, API key input, privacy policy reader, clear cache/data.
- **PrivacyPolicyScreen:** Complete legal text with Google Play compliance disclosures.

### Phase 7: AdMob Monetization Layer
- Implement `AdService`: initialize SDK, load adaptive banners, load interstitials with frequency cap (minimum 3 minutes between interstitials, max 3 per session).
- Implement `BannerAdWidget`: compliant container with "Sponsored" disclosure and error handling.
- Verify test ad IDs in development.

### Phase 8: Testing, Verification & Bug Fixing
- Unit tests: Repositories, models, distance calculations, filter logic, URL builder.
- Widget tests: HomeScreen, PlaceCard, SearchScreen, MapPreviewSheet, Bookmark interactions.
- Static analysis: `flutter analyze` zero warnings/errors.
- Build release APK / App Bundle verification.

### Phase 9: Deliverables & Release Compliance
- Complete documentation: `PROJECT_AUDIT.md`, `ARCHITECTURE.md`, `COMPONENTS.md`, `QA_REPORT.md`, `PLAY_STORE_COMPLIANCE.md`, `.env.example`, `README.md`.

