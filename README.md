# SpotFinder — Premium Location Discovery & Place Finder Android App

SpotFinder is a production-grade, privacy-first Location Discovery and Place Finder Android application engineered with **Flutter & Dart**, **Riverpod**, **GoRouter**, and **Clean Architecture**.

It allows users to discover cafes, restaurants, hotels, gyms, shopping centers, hospitals, attractions, and more around their current location or any manually selected city, area, or interactive map pin.

---

## 🌟 Key Capabilities

1. **Multi-Category Place Discovery:**
   - 18+ rich categories: Cafes, Coffee Shops, Restaurants, Fast Food, Hotels, Resorts, Gyms, Shopping Malls, Clothing Stores, Hospitals, Pharmacies, Tourist Attractions, Parks, Cinemas, Petrol Pumps, ATMs/Banks, Salons & Spas.
2. **Flexible Location Selection:**
   - Foreground device GPS with pre-permission transparency.
   - Global city/neighborhood search with autocomplete (Surat, Ahmedabad, Mumbai, New York, London, etc.).
   - Interactive map pin repositioning and "Search this area" functionality.
   - 100% functional even when location permissions are denied.
3. **Interactive Mapping:**
   - Smooth full-screen map powered by `flutter_map` with OpenStreetMap CartoDB / TileLayer.
   - Dynamic custom category markers with animated selection highlighting.
   - Floating area re-search button and re-center GPS FAB.
   - Docked bottom preview card for immediate inspection.
   - Seamless Map <-> List view toggling.
4. **Rich Place Details:**
   - Authentic venue details (name, category, address, phone, website, distance, opening hours schedule, amenities).
   - Interactive mini-map showing exact pin location.
   - One-tap turn-by-turn navigation launcher (Google Maps, Waze, OsmAnd, system navigators).
   - Direct phone dialer intent (`tel:`) without sensitive telephony permissions.
   - One-tap address copy to clipboard.
5. **User-Owned Bookmarks & Local Data:**
   - Privacy-first local persistence via SharedPreferences.
   - Save favorites with category filtering and swipe-to-delete with undo.
   - Search query history and recently viewed venues.
   - In-app "Clear All Local Data" button (Google Play User Data safety compliant).
   - Zero forced account creation; full guest mode by default.
6. **Responsible AdMob Monetization:**
   - Official Google Mobile Ads SDK integration (`google_mobile_ads: ^9.2.0`).
   - Adaptive banners clearly marked with a "SPONSORED" badge.
   - Interstitial ads capped strictly at natural screen transitions (minimum 3 minutes interval and 4 place detail views).
   - Never interrupts map navigation or marker selection.
   - Official Google test ad unit IDs pre-configured.
7. **Google Play Store Policy & Compliance:**
   - Strictly NO unauthorized web scraping.
   - Legitimate REST endpoints: OpenStreetMap Overpass API, Nominatim Geocoder, and Google Places API (New).
   - Mandatory attribution permanently visible (`© OpenStreetMap contributors` / Google Places).
   - Target SDK 36 (compliant with 2026 Play Store requirements).
   - Complete in-app Privacy Policy.

---

## 🏗️ Architecture Overview

```
lib/
├── app.dart                                # MaterialApp.router & global theme
├── main.dart                               # Entry point with ProviderScope
├── core/
│   ├── config/
│   │   ├── app_config.dart                 # Environment & build constants
│   │   └── api_constants.dart              # API endpoints & headers
│   ├── network/
│   │   ├── dio_client.dart                 # Configured Dio HTTP client
│   │   └── network_exceptions.dart         # Mapped error classifications
│   ├── services/
│   │   ├── ad_service.dart                 # AdMob lifecycle & frequency cap manager
│   │   ├── location_service.dart           # Geolocator & foreground GPS service
│   │   └── navigation_service.dart         # Maps, dialer, browser, and share intents
│   ├── theme/
│   │   ├── app_colors.dart                 # Aegean Teal & Slate color system
│   │   ├── app_typography.dart             # Material 3 type scale
│   │   ├── app_theme.dart                  # Light and Dark ThemeData
│   │   └── app_decorations.dart            # Ambient shadows & card borders
│   └── utils/
│       ├── distance_calculator.dart        # Haversine distance & formatting
│       ├── debouncer.dart                  # Search debouncing
│       └── formatters.dart                 # String and hours formatters
├── features/
│   ├── discovery/                          # Core venue discovery & search
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── nominatim_service.dart  # Geocoding & area search
│   │   │   │   ├── overpass_service.dart   # OSM Overpass venue queries
│   │   │   │   └── google_places_service.dart # Google Places API (New)
│   │   │   ├── models/
│   │   │   │   └── category_images.dart    # Category imagery helper
│   │   │   └── repositories/
│   │   │       └── places_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/                   # Place, Category, LocationInfo, SearchFilter
│   │   │   └── repositories/places_repository.dart
│   │   └── presentation/
│   │       ├── providers/                  # discovery_providers.dart, location_provider.dart
│   │       ├── screens/                    # HomeScreen, SearchScreen, LocationPickerSheet, FilterBottomSheet
│   │       └── widgets/                    # PlaceCard, PlaceCompactCard, SearchBarWidget, CategoryChipGroup
│   ├── map/                                # Interactive map visualization
│   │   └── presentation/
│   │       ├── screens/map_screen.dart     # Full-screen interactive map
│   │       └── widgets/                    # CustomMapMarker, MapPreviewSheet, SearchThisAreaButton
│   ├── place_detail/                       # Venue details inspection
│   │   └── presentation/
│   │       ├── screens/place_detail_screen.dart
│   │       └── widgets/                    # ActionButtonsRow, OpeningHoursTable, PlaceAttributionCard
│   ├── saved/                              # Favorites & history
│   │   ├── data/bookmark_repository.dart
│   │   └── presentation/
│   │       ├── providers/saved_provider.dart
│   │       └── screens/saved_screen.dart
│   └── settings/                           # Preferences & legal compliance
│       └── presentation/
│           ├── providers/settings_provider.dart
│           └── screens/settings_screen.dart, privacy_policy_screen.dart
└── routing/
    ├── app_router.dart                     # GoRouter with StatefulShellRoute
    └── main_scaffold.dart                  # Bottom NavigationBar scaffold
```

---

## 🚀 Setup & Build Instructions

### Prerequisites
- Flutter SDK 3.47.5+
- Dart SDK 3.13.4+
- Android SDK 36 (build-tools 34+)
- JDK 17 or 21 (Android Studio JBR)

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Run Tests
```bash
flutter test
```

### 3. Run Static Analysis
```bash
flutter analyze
```

### 4. Run on Connected Device / Emulator
```bash
flutter run
```

### 5. Build Release App Bundle (for Google Play Store)
```bash
flutter build appbundle --release
```

---

## ⚙️ Environment Configuration

SpotFinder works out of the box with OpenStreetMap without any external API keys.

To configure optional Google Places API or production AdMob IDs, create a `.env` file or pass `--dart-define` parameters during compilation:

```bash
flutter run \
  --dart-define=PLACES_PROVIDER=osm \
  --dart-define=ADMOB_BANNER_UNIT_ID=ca-app-pub-3940256099942544/6300978111 \
  --dart-define=ADMOB_INTERSTITIAL_UNIT_ID=ca-app-pub-3940256099942544/1033173712
```

See `.env.example` for the complete list of configuration options.

---

## 📜 Documentation Deliverables

- `PROJECT_AUDIT.md`: Workspace and environment analysis.
- `IMPLEMENTATION_PLAN.md`: Detailed engineering roadmap.
- `ARCHITECTURE.md`: Architecture diagrams and data flows.
- `COMPONENTS.md`: Design system tokens and widget catalog.
- `QA_REPORT.md`: Comprehensive test report and bug fixes.
- `PLAY_STORE_COMPLIANCE.md`: Play Store policies and Data Safety disclosures.
