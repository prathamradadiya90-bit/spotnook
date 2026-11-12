# GOOGLE PLAY STORE POLICY & PRIVACY COMPLIANCE AUDIT

**Application Name:** Spotnook — Location Discovery & Place Finder  
**Target Platform:** Android (Google Play Store Production)  
**Package Name:** `com.spotnook.app`  
**Compliance Standard:** 2026 Google Play Developer Content Policy  
**Live Privacy Policy URL:** [https://spotnook-privacy.vercel.app](https://spotnook-privacy.vercel.app) (also accessible at `/privacy`)

---

## 1. Google Play Console Privacy Policy Verification Checklist

| Requirement | Google Play Standard | Spotnook Status | Verified URL / Location |
|---|---|---|---|
| **Active & Public HTTPS URL** | Must start with `https://` with valid SSL certificate | **PASSED (HTTP 200)** | `https://spotnook-privacy.vercel.app` |
| **Global Accessibility** | Worldwide access without geofencing, IP blocking, or login | **PASSED** | Hosted on Vercel Edge CDN |
| **Non-Editable Web Page** | Standard web page (HTML) — NOT a PDF or download | **PASSED** | HTML5 document |
| **App-Specific Disclosures** | Expressly names app (`Spotnook`), package (`com.spotnook.app`) | **PASSED** | Comprehensive disclosures |
| **Location Data Scope** | Discloses foreground-only GPS (`FINE`/`COARSE`), ephemeral queries | **PASSED** | Section 2 |
| **AdMob & Third-Party SDKs** | Discloses Advertising ID (AAID), diagnostic data, UMP consent | **PASSED** | Section 3 |
| **User Data Deletion** | Clear instructions & in-app "Clear All Local Data" button | **PASSED** | Section 4 & Settings screen |
| **Children's Privacy** | Explicit COPPA disclosure (not directed to children under 13) | **PASSED** | Section 6 |
| **In-App Accessibility** | Accessible directly inside the app without external browser dependency | **PASSED** | Settings > Privacy Policy |

---

## 2. Policy Audit Matrix

| Policy Area | Official Policy Reference | In-App Implementation | Verification Method | Status |
|---|---|---|---|---|
| **Foreground Location** | [Google Play Location Policy](https://support.google.com/googleplay/android-developer/answer/9799150) | `ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION` requested only in foreground with prior user explanation dialog. | AndroidManifest audit & runtime permission test | **COMPLIANT** |
| **Background Location** | [Background Location Restrictions](https://support.google.com/googleplay/android-developer/answer/9799150) | NO `ACCESS_BACKGROUND_LOCATION` permission requested anywhere in the manifest or code. | Manifest inspection | **COMPLIANT** |
| **Location Permission Denial** | Google Play User Data Policy | If user denies location, app falls back cleanly to manual search or city pin drop without blocking functionality. | Integration testing with permission rejected | **COMPLIANT** |
| **Ads & Monetization** | [Google Play Ads Policy](https://support.google.com/googleplay/android-developer/answer/9857753) | Interstitials strictly restricted to natural transitions with frequency capping; no ads on app launch; no ad interference with map markers or navigation. | AdService lifecycle review | **COMPLIANT** |
| **Deceptive Behavior & Scraping** | [Google Play Deceptive Behavior](https://play.google.com/about/developer-content-policy/) | NO web scraping of Google Maps, web search, or social media. Real APIs (OSM Overpass / Nominatim / Google Places API) with required attributions. | Codebase inspection & API contract review | **COMPLIANT** |
| **Data Safety & Privacy** | [Google Play Data Safety Form](https://support.google.com/googleplay/android-developer/answer/10787469) | Data collection limited to ephemeral device coordinates for nearby search (not linked to user ID, not sold, not persisted on remote servers). Full Privacy Policy included in-app. | Privacy Policy & Data flow review | **COMPLIANT** |
| **Account Deletion** | [Account Deletion Policy](https://support.google.com/googleplay/android-developer/answer/13327920) | Guest mode default. No mandatory registration. In-app "Clear All Local Data" button removes all saved bookmarks, history, and preferences. | Settings screen verification | **COMPLIANT** |
| **Target SDK Version** | Android Target API Requirements | Target SDK 34/35+ compliance with Gradle 9.3.1 and Android 14/15 standards. | `build.gradle.kts` configuration | **COMPLIANT** |

---

## 2. Permissions Breakdown

```xml
<!-- Network for API queries -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<!-- Foreground Location only (Used exclusively when user taps "Use current location") -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Dialing phone numbers directly when user taps Call button -->
<!-- Uses standard Intent.ACTION_DIAL, NO CALL_PHONE permission required! -->
```

> [!IMPORTANT]
> Notice that `android.permission.CALL_PHONE` is NOT requested. Instead, the application uses `Intent.ACTION_DIAL` (via `tel:`) which passes the number safely to the user's phone dialer without requiring sensitive runtime telephony permissions.

---

## 3. Data Safety Questionnaire Declarations (for Google Play Console)

When submitting SpotFinder to the Google Play Console, use the following questionnaire declarations:

1. **Does your app collect or share any user data?**
   - **Yes** (Approximate & Precise Location for core place discovery functionality).
2. **Data Types:**
   - **Location:**
     - *Approximate location:* Collected ephemerally for finding nearby places. Not shared with third parties. Not stored on remote servers.
     - *Precise location:* Collected ephemerally when user grants permission to find places within immediate walking distance. Not stored on remote servers.
   - **App info and performance:**
     - *Crash logs & Diagnostics:* Handled by standard OS mechanisms.
   - **Device or other identifiers:**
     - *Advertising ID:* Collected by Google Mobile Ads SDK for ad serving (with UMP consent).
3. **Data Security Practices:**
   - Data is encrypted in transit using HTTPS (TLS 1.3).
   - Users can delete all saved bookmarks and search history locally at any time.

---

## 4. Google Maps & Third-Party Attribution Compliance

- **OpenStreetMap Data:** In accordance with the Open Database License (ODbL), all map views and OSM-derived place information clearly display: `© OpenStreetMap contributors`.
- **Google Places API:** When Google Places API key is configured, all Google place reviews, star ratings, and photos display the required Google attribution and author attribution chips.
- **Photos:** Unsplash/OSM/Google photo attributions are preserved and linked to their respective sources.

