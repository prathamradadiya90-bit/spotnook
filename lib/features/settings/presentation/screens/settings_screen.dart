import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/api_constants.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/ad_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../discovery/presentation/providers/discovery_providers.dart';
import '../../../place_detail/presentation/providers/user_ratings_provider.dart';
import '../../../saved/presentation/providers/saved_provider.dart';
import '../providers/settings_provider.dart';

/// App preferences, provider settings, self-hosting endpoints, and privacy compliance screen.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
          // Section: Appearance
          _buildSectionHeader('Appearance', isDark),
          Container(
            decoration: AppDecorations.cardDecoration(context),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined, color: AppColors.primary),
                  title: const Text('Theme Mode'),
                  subtitle: Text(_themeLabel(settings.themeMode)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showThemeDialog(context, ref, settings.themeMode),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: Preferences
          _buildSectionHeader('Preferences', isDark),
          Container(
            decoration: AppDecorations.cardDecoration(context),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.straighten_outlined, color: AppColors.primary),
                  title: const Text('Use Imperial Units (Miles)'),
                  subtitle: Text(settings.useMiles ? 'Displaying in miles' : 'Displaying in kilometers'),
                  value: settings.useMiles,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    ref.read(settingsProvider.notifier).setUseMiles(val);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.radar_outlined, color: AppColors.primary),
                  title: const Text('Default Search Radius'),
                  subtitle: Text('${(settings.defaultRadiusMeters / 1000).toStringAsFixed(0)} km'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showRadiusDialog(context, ref, settings.defaultRadiusMeters),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: Places Data Provider & Endpoints
          _buildSectionHeader('Data Source & APIs', isDark),
          Container(
            decoration: AppDecorations.cardDecoration(context),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_sync_outlined, color: AppColors.primary),
                  title: const Text('Places Data Provider'),
                  subtitle: Text(
                    settings.provider == 'google' ? 'Google Places API (New)' : 'OpenStreetMap (Overpass & Nominatim)',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showProviderDialog(context, ref, settings.provider),
                ),
                if (settings.provider == 'google') ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.key_outlined, color: AppColors.accent),
                    title: const Text('Google Places API Key'),
                    subtitle: Text(
                      settings.googleApiKey.isNotEmpty ? '•••••••••••••••• (Securely Stored)' : 'Not configured (Tap to enter)',
                    ),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => _showApiKeyDialog(context, ref, settings.googleApiKey),
                  ),
                ],
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.dns_outlined, color: AppColors.primary),
                  title: const Text('Self-Hosted Base URLs'),
                  subtitle: const Text('Configure custom Overpass & Photon endpoints'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showEndpointsDialog(context, ref, settings),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: Privacy & Data Safety
          _buildSectionHeader('Privacy & Data Control', isDark),
          Container(
            decoration: AppDecorations.cardDecoration(context),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.history_outlined, color: AppColors.primary),
                  title: const Text('Clear Search History'),
                  onTap: () async {
                    await ref.read(recentSearchesProvider.notifier).clear();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Search history cleared.')),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.visibility_off_outlined, color: AppColors.primary),
                  title: const Text('Clear Recently Viewed'),
                  onTap: () async {
                    await ref.read(recentlyViewedProvider.notifier).clear();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Recently viewed venues cleared.')),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.tune_rounded, color: AppColors.primary),
                  title: const Text('Ad & Privacy Consent Settings'),
                  subtitle: const Text('Manage Google UMP data consent preferences'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => AdService.instance.showPrivacyOptionsForm(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever_outlined, color: AppColors.statusClosed),
                  title: Text(
                    'Delete All My Data',
                    style: AppTypography.titleSmall.copyWith(color: AppColors.statusClosed, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Permanently wipes bookmarks, history, keys, and cache'),
                  onTap: () => _confirmDeleteAllData(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: Legal & About
          _buildSectionHeader('About & Compliance', isDark),
          Container(
            decoration: AppDecorations.cardDecoration(context),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.primary),
                  title: const Text('Privacy Policy'),
                  subtitle: const Text('Accurate Play Store data safety disclosures'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/privacy-policy'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.attribution_outlined, color: AppColors.primary),
                  title: const Text('OpenStreetMap Legal Notice'),
                  subtitle: const Text('Open Database License (ODbL) Attribution'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showOsmAttributionDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined, color: AppColors.primary),
                  title: const Text('Open Source Licenses'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: AppConfig.appName,
                    applicationVersion: '${AppConfig.appVersion} (${AppConfig.buildNumber})',
                  ),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.info_outline, color: AppColors.primary),
                  title: Text('Version'),
                  subtitle: Text('${AppConfig.appName} v${AppConfig.appVersion} (Build ${AppConfig.buildNumber})'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    ),
  ),
);
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: AppTypography.labelLarge.copyWith(
          color: isDark ? AppColors.primaryLight : AppColors.primary,
        ),
      ),
    );
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System Default';
    }
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, ThemeMode current) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Theme Mode'),
        children: [
          RadioListTile<ThemeMode>(
            title: const Text('System Default'),
            value: ThemeMode.system,
            groupValue: current,
            onChanged: (val) {
              if (val != null) ref.read(settingsProvider.notifier).setThemeMode(val);
              Navigator.of(ctx).pop();
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Light Theme'),
            value: ThemeMode.light,
            groupValue: current,
            onChanged: (val) {
              if (val != null) ref.read(settingsProvider.notifier).setThemeMode(val);
              Navigator.of(ctx).pop();
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark Theme'),
            value: ThemeMode.dark,
            groupValue: current,
            onChanged: (val) {
              if (val != null) ref.read(settingsProvider.notifier).setThemeMode(val);
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showRadiusDialog(BuildContext context, WidgetRef ref, double current) {
    final radii = [1000.0, 3000.0, 5000.0, 10000.0, 20000.0];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Default Search Radius'),
        children: radii.map((r) {
          final label = '${(r / 1000).toStringAsFixed(0)} km';
          return RadioListTile<double>(
            title: Text(label),
            value: r,
            groupValue: current,
            onChanged: (val) {
              if (val != null) ref.read(settingsProvider.notifier).setDefaultRadius(val);
              Navigator.of(ctx).pop();
            },
          );
        }).toList(),
      ),
    );
  }

  void _showProviderDialog(BuildContext context, WidgetRef ref, String current) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Places Data Provider'),
        children: [
          RadioListTile<String>(
            title: const Text('OpenStreetMap (Overpass & Nominatim)'),
            subtitle: const Text('Free, live, zero API key required (Default)'),
            value: 'osm',
            groupValue: current,
            onChanged: (val) {
              if (val != null) ref.read(settingsProvider.notifier).setProvider(val);
              Navigator.of(ctx).pop();
            },
          ),
          RadioListTile<String>(
            title: const Text('Google Places API (New)'),
            subtitle: const Text('Requires your own Google Cloud API Key'),
            value: 'google',
            groupValue: current,
            onChanged: (val) {
              if (val != null) ref.read(settingsProvider.notifier).setProvider(val);
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showApiKeyDialog(BuildContext context, WidgetRef ref, String current) {
    final controller = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Google Places API Key'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (kIsWeb)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade700, width: 0.8),
                  ),
                  child: const Text(
                    '⚠️ Web Notice: Keys used in a browser environment are visible in network requests. We strongly recommend configuring an HTTP-referrer restriction in Google Cloud Console.',
                    style: TextStyle(fontSize: 12, height: 1.3),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary, width: 0.8),
                  ),
                  child: const Text(
                    '🔒 Android Storage: Keys are encrypted in hardware-backed EncryptedSharedPreferences (Android Keystore). Never logged or transmitted to our servers.',
                    style: TextStyle(fontSize: 12, height: 1.3),
                  ),
                ),
              TextField(
                controller: controller,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'AIzaSy...',
                  labelText: 'API Key',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Security Best Practice:\nIn Google Cloud Console, restrict this key to:\n• Package Name: com.spotnook.app\n• API: Places API (New)',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).setGoogleApiKey(controller.text.trim());
              Navigator.of(ctx).pop();
            },
            child: const Text('Save Securely'),
          ),
        ],
      ),
    );
  }

  void _showEndpointsDialog(BuildContext context, WidgetRef ref, SettingsState settings) {
    final overpassController = TextEditingController(text: settings.overpassBaseUrl);
    final photonController = TextEditingController(text: settings.photonBaseUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Self-Hosted Base URLs'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Optionally point SpotFinder to your private or regional mirrors of Overpass and Photon.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: overpassController,
                decoration: const InputDecoration(
                  labelText: 'Overpass Interpreter URL',
                  hintText: ApiConstants.overpassBaseUrl,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: photonController,
                decoration: const InputDecoration(
                  labelText: 'Photon API Base URL',
                  hintText: ApiConstants.photonBaseUrl,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).resetEndpointsToDefault();
              Navigator.of(ctx).pop();
            },
            child: const Text('Reset Defaults'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).setOverpassBaseUrl(overpassController.text.trim());
              ref.read(settingsProvider.notifier).setPhotonBaseUrl(photonController.text.trim());
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showOsmAttributionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('OpenStreetMap Legal Notice'),
        content: const Text(
          'Map data and place details are provided by OpenStreetMap and its contributors under the Open Database License (ODbL).\n\nCarto basemap tiles are provided under CC BY 3.0.\n\nSpotFinder honors all caching, attribution, and rate-limiting policies.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAllData(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All My Data?'),
        content: const Text(
          'This will permanently delete:\n• All saved favorite bookmarks\n• Search query history\n• Recently viewed places\n• Cached place results on disk\n• Stored API credentials\n\nThis cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusClosed),
            onPressed: () async {
              // 1. Clear bookmarks, visited passport, & histories
              await ref.read(bookmarkRepositoryProvider).clearAllUserData();
              await ref.read(bookmarksProvider.notifier).clearAll();
              await ref.read(visitedPlacesProvider.notifier).clearAll();
              await ref.read(recentSearchesProvider.notifier).clear();
              await ref.read(recentlyViewedProvider.notifier).clear();

              // 2. Clear user ratings
              await ref.read(userRatingsProvider.notifier).clearAll();

              // 3. Clear credentials from secure storage & prefs
              await ref.read(settingsProvider.notifier).clearAllStoredCredentials();

              // 4. Clear in-memory & disk cache
              await ref.read(placesCacheServiceProvider).clearAll();

              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All local data, cache, and keys deleted.')),
                );
              }
            },
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
  }
}
