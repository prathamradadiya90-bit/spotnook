import 'package:flutter/material.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';

/// In-app Privacy Policy document adhering to Google Play User Data & Permissions Policies.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppDecorations.cardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.security_rounded, color: AppColors.primary, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Privacy & Data Safety',
                      style: AppTypography.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Effective Date: November 8, 2026 • Version 1.0',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildSection(
            title: '1. Overview',
            content:
                'Spotnook ("we", "our", or "us") provides a location discovery application enabling users to find cafes, restaurants, hotels, gyms, stores, and attractions. Your privacy is paramount: we do not sell your data, track you across the internet, or require mandatory account creation.',
            isDark: isDark,
          ),

          _buildSection(
            title: '2. Location Information Policy',
            content:
                '• Foreground Location: When you tap "My Location", Spotnook requests foreground access (ACCESS_FINE_LOCATION and ACCESS_COARSE_LOCATION) solely to calculate distances and discover nearby places in your immediate vicinity.\n'
                '• Ephemeral Processing: Your location coordinates are transmitted ephemerally to map/place providers to perform searches. We do NOT store your GPS coordinates on our servers.\n'
                '• No Background Tracking: Spotnook never requests or uses background location (ACCESS_BACKGROUND_LOCATION).\n'
                '• Manual Selection: You may deny location permission at any time. The application remains 100% functional through manual city/area search and map pin selection.',
            isDark: isDark,
          ),

          _buildSection(
            title: '3. Data Sources & Third-Party APIs',
            content:
                '• OpenStreetMap & Overpass API: Place search and mapping data are retrieved in compliance with the Open Database License (ODbL). All map layers credit © OpenStreetMap contributors.\n'
                '• Google Places API (Optional): If configured, Google Places API is used in accordance with Google Maps Platform policies. Place IDs and data are handled without prohibited caching.',
            isDark: isDark,
          ),

          _buildSection(
            title: '4. Advertising & Monetization (AdMob)',
            content:
                '• Google Mobile Ads (AdMob) SDK: Spotnook uses the official Google Mobile Ads SDK to display banner and interstitial ads.\n'
                '• Data Processed by AdMob: In accordance with Google AdMob policy, Google may collect and process device identifiers (including Google Advertising ID), IP addresses, diagnostic/performance telemetry, and ad interaction logs for ad delivery, fraud detection, and analytics.\n'
                '• Consent & Privacy Control: We implement the official Google User Messaging Platform (UMP). Users in the EEA, UK, and worldwide may adjust their ad privacy consent at any time via Settings > Ad & Privacy Consent Settings.\n'
                '• Frequency Capping: Interstitial ads are frequency-capped and never trigger during map navigation or urgent user tasks.',
            isDark: isDark,
          ),

          _buildSection(
            title: '5. User Data Storage & Deletion Rights',
            content:
                'All user favorites, recent searches, and view history are stored exclusively in local device storage (SharedPreferences). In accordance with Google Play Data Deletion requirements, you may delete all stored data immediately at any time by selecting "Clear All Local Data" under App Settings.',
            isDark: isDark,
          ),

          _buildSection(
            title: '6. Children\'s Privacy',
            content:
                'Spotnook is designed for a general audience and is not directed toward children under the age of 13. We do not knowingly collect, process, or solicit personal data from children under 13.',
            isDark: isDark,
          ),

          _buildSection(
            title: '7. Data Security & Encryption',
            content:
                'All network communications with external map and place APIs are encrypted in transit using industry-standard HTTPS (TLS 1.2 / TLS 1.3). Cleartext HTTP traffic is blocked across the app.',
            isDark: isDark,
          ),

          _buildSection(
            title: '8. Contact & Inquiries',
            content:
                'If you have questions regarding this Privacy Policy or your data, please contact our Data Protection Team at:\n'
                'Email: ${AppConfig.supportEmail}\n'
                'Website: ${AppConfig.privacyPolicyUrl}',
            isDark: isDark,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: AppTypography.bodyMedium.copyWith(
              height: 1.5,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
