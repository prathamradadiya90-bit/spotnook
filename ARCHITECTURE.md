# SPOTFINDER: SYSTEM ARCHITECTURE & DESIGN SPECIFICATION

## 1. Architectural Philosophy

SpotFinder adheres to **Clean Architecture** combined with a **Feature-First** structure and the **Repository Pattern**. This guarantees:
- **Separation of Concerns:** Business logic is decoupled from UI presentation and external SDKs.
- **Testability:** All repositories, providers, and utilities are unit testable with mock data sources.
- **Provider Interchangeability:** The places data provider (OpenStreetMap Overpass / Nominatim vs. Google Places) is abstracted behind `PlacesRepository`, allowing runtime toggling or zero-configuration open access.
- **Zero Scraping Guarantee:** Strictly documented, legitimate REST endpoints and SDKs are used.

```
                      ┌────────────────────────────────────────┐
                      │            Presentation Layer          │
                      │  (Widgets, Screens, Theme, Nav)        │
                      └──────────────────┬─────────────────────┘
                                         │ Watches / Reads
                                         ▼
                      ┌────────────────────────────────────────┐
                      │            Application Layer           │
                      │  (Riverpod Notifiers, State, Controllers│
                      └──────────────────┬─────────────────────┘
                                         │ Calls
                                         ▼
                      ┌────────────────────────────────────────┐
                      │              Domain Layer              │
                      │  (Entities, Repository Interfaces,     │
                      │   Use Cases, Value Objects)            │
                      └──────────────────▲─────────────────────┘
                                         │ Implements
                                         │
                      ┌──────────────────┴─────────────────────┐
                      │               Data Layer               │
                      │  (Repositories, API Clients, Local DB, │
                      │   Data Transfer Objects / Mappers)     │
                      └──────────────────┬─────────────────────┘
                                         │
                 ┌───────────────────────┴───────────────────────┐
                 ▼                                               ▼
     ┌────────────────────────┐                     ┌────────────────────────┐
     │  Remote Data Sources   │                     │   Local Data Sources   │
     │ - Overpass API (OSM)   │                     │ - SharedPreferences    │
     │ - Nominatim API        │                     │ - FlutterSecureStorage │
     │ - Google Places API    │                     │ - In-memory LRU Cache  │
     └────────────────────────┘                     └────────────────────────┘
```

---

## 2. Directory Structure

```
lib/
├── app.dart                                # Root MaterialApp with theme & router
├── main.dart                               # Entrypoint with Riverpod ProviderScope
├── core/
│   ├── config/
│   │   ├── app_config.dart                 # Environment & build constants
│   │   └── api_constants.dart              # Endpoint URLs & timeout configs
│   ├── network/
│   │   ├── dio_client.dart                 # Configured Dio singleton with interceptors
│   │   └── network_exceptions.dart         # Mapped error classifications
│   ├── services/
│   │   ├── ad_service.dart                 # Google Mobile Ads (AdMob) manager
│   │   ├── location_service.dart           # Geolocator & GPS permission wrapper
│   │   └── navigation_service.dart         # External maps intent launcher
│   ├── theme/
│   │   ├── app_colors.dart                 # Semantic color palette
│   │   ├── app_typography.dart             # Text styles and scales
│   │   ├── app_theme.dart                  # Material 3 light & dark ThemeData
│   │   └── app_decorations.dart            # Custom shadows, borders, radii
│   └── utils/
│       ├── distance_calculator.dart        # Haversine distance & formatting
│       ├── debouncer.dart                  # Search debouncing utility
│       └── formatters.dart                 # Phone, currency, opening hours formatters
├── features/
│   ├── discovery/                          # Places search & nearby exploration
│   │   ├── data/
│   │   │   ├── models/place_model.dart     # Place DTO with JSON parsing
│   │   │   ├── models/category_model.dart  # Category definitions & icons
│   │   │   ├── datasources/                # Overpass, Nominatim, Google Places
│   │   │   └── repositories/               # PlacesRepositoryImpl
│   │   ├── domain/
│   │   │   ├── entities/place.dart         # Core domain Place entity
│   │   │   ├── entities/location.dart      # Coordinate & address entity
│   │   │   └── repositories/places_repo.dart
│   │   └── presentation/
│   │       ├── providers/                  # discovery_providers.dart
│   │       ├── screens/                    # home_screen.dart, search_screen.dart
│   │       └── widgets/                    # PlaceCard, CategoryList, SearchBar
│   ├── map/                                # Interactive map & navigation
│   │   ├── presentation/
│   │   │   ├── screens/map_screen.dart     # Full map with preview sheet
│   │   │   └── widgets/                    # CustomMarker, PreviewSheet, AreaSearch
│   ├── place_detail/                       # Detailed venue inspection
│   │   ├── presentation/
│   │   │   ├── screens/place_detail_screen.dart
│   │   │   └── widgets/                    # ActionButtons, HoursTable, AmenitiesGrid
│   ├── saved/                              # Favorites & bookmarks
│   │   ├── data/
│   │   │   └── bookmark_repository.dart    # Local persistence for bookmarks
│   │   └── presentation/
│   │       ├── screens/saved_screen.dart
│   │       └── providers/saved_provider.dart
│   └── settings/                           # Preferences & Play Store Compliance
│       ├── presentation/
│       │   ├── screens/settings_screen.dart
│       │   ├── screens/privacy_policy_screen.dart
│       │   └── providers/settings_provider.dart
└── routing/
    └── app_router.dart                     # GoRouter configuration with ShellRoute
```

---

## 3. Data Flow & State Management

1. **User Action:** The user taps a category ("Cafes") or moves the map.
2. **Notifier Update:** `placesDiscoveryProvider` receives the new query/coordinate and emits an asynchronous `AsyncLoading` state.
3. **Repository Execution:** `PlacesRepository` handles debouncing, checks memory cache, and queries the active provider (e.g., `OverpassPlacesService`).
4. **Data Normalization:** Raw JSON is parsed into domain `Place` models, enriching them with calculated distance from the selected location, open status, and formatted addresses.
5. **UI Rendering:** The provider emits `AsyncData(places)`. The UI updates reactively, displaying markers on the interactive map and cards in the list view.
6. **Error Handling:** Network timeouts or empty results emit clear, graceful UI states (`NoPlacesFoundWidget` or `ErrorRetryWidget`).

---

## 4. Security & Privacy Architecture

- **No Hardcoded Secrets:** All API keys are loaded via compile-time environment variables (`String.fromEnvironment`) or dynamically configured in user settings.
- **Local-Only Storage:** User bookmarks and search history remain 100% on the device unless an explicit cloud sync backend is connected in the future.
- **Zero Third-Party Tracking:** No invasive user tracking SDKs. AdMob is integrated with UMP consent to respect GDPR/CCPA regulations.
- **Safe Network Layer:** Enforced HTTPS with 15-second timeouts and rate limiting to avoid server flooding.

