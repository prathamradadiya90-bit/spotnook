# SPOTFINDER: DESIGN SYSTEM & COMPONENT CATALOG

## 1. Design Tokens & Palette

### Primary & Accent Colors
- **Brand Primary (`AppColors.primary`):** `#008080` (Aegean Teal) — Modern, trustworthy, sophisticated.
- **Primary Container (`AppColors.primaryContainer`):** `#E6F4F4` (Light Teal Tint).
- **Secondary (`AppColors.secondary`):** `#1E293B` (Slate Navy) — High-contrast structural element.
- **Accent Coral (`AppColors.accent`):** `#F97316` (Warm Tangerine) — Highlighting call-to-action buttons.
- **Status Open (`AppColors.statusOpen`):** `#10B981` (Emerald Green) — Indicating "Open Now".
- **Status Closed (`AppColors.statusClosed`):** `#EF4444` (Ruby Red) — Indicating "Closed".
- **Rating Amber (`AppColors.starAmber`):** `#F59E0B` (Amber) — Star rating icons.

### Neutral Surfaces
- **Background Light:** `#F8FAFC` (Off-white / Slate 50).
- **Surface Light:** `#FFFFFF` (Pure white cards).
- **Background Dark:** `#0F172A` (Deep Slate 900).
- **Surface Dark:** `#1E293B` (Slate 800 cards).
- **Border Subtle:** `#E2E8F0` (Slate 200).

---

## 2. Reusable UI Components

### 1. `SpotSearchBar`
- **Purpose:** Primary search trigger on Home and Search screens.
- **Props:** `controller`, `hintText`, `onChanged`, `onSubmitted`, `onClear`, `onFilterTap`, `trailingWidget`.
- **States:** Idle, Focused, Typing (with clear button), Loading spinner.

### 2. `CategoryChipGroup`
- **Purpose:** Horizontal carousel of quick category filters (Cafes, Restaurants, Hotels, Gyms, Shopping, Hospitals, etc.).
- **Props:** `categories`, `selectedCategoryId`, `onSelected`.
- **Styling:** Pill design with category icon and label, subtle active outline/fill.

### 3. `PlaceCard` (List View Card)
- **Purpose:** Standard place representation in discovery lists.
- **Features:**
  - Hero image with cached network loading & graceful fallback.
  - Category pill badge.
  - Open/Closed status indicator.
  - Place Name with truncation.
  - Rating badge with star icon and review count.
  - Calculated distance badge (e.g., `450 m`, `2.4 km`).
  - Address snippet.
  - One-tap Bookmark toggle icon.

### 4. `PlaceCompactCard` (Horizontal Carousel & Map Preview)
- **Purpose:** Compact card for horizontal scrolling in "Trending Nearby" and Map bottom sheets.
- **Features:** 260dp width, image top, quick action buttons ("Directions", "Details").

### 5. `CustomMapMarker`
- **Purpose:** High-resolution map pins on the interactive map.
- **States:**
  - Standard pin (Teal circle with category icon).
  - Selected pin (Animated scale-up, glowing border, distinct amber/coral fill).

### 6. `RatingBadge`
- **Purpose:** Display star rating and review count consistently across cards and detail screens.
- **Formats:** Compact (`★ 4.8`) and Detailed (`★ 4.8 (124 reviews)`).

### 7. `OpeningHoursTable`
- **Purpose:** Structured daily opening hours breakdown on place details screen.
- **Features:** Highlights today's schedule, expands to show Monday-Sunday timetable.

### 8. `ActionButtonsRow`
- **Purpose:** One-tap interaction buttons on place detail:
  - 📞 **Call** (launches system dialer)
  - 🧭 **Directions** (launches Google Maps / external navigator)
  - 🌐 **Website** (launches browser)
  - 🔗 **Share** (launches native share dialog)
  - 🔖 **Bookmark** (saves locally with toast confirmation)

### 9. `AdBannerContainer`
- **Purpose:** Google Mobile Ads banner wrapper.
- **Features:** Fixed aspect ratio, "SPONSORED" label, no layout jumps while ad loads, graceful collapse on load failure.

### 10. `EmptyStateWidget` & `ErrorRetryWidget`
- **Purpose:** Informative empty search states and actionable network retry interfaces with retry buttons.

