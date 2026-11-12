// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'SpotFinder';

  @override
  String get exploreSpots => 'Explore Spots';

  @override
  String get searchHint => 'Search cafes, restaurants, hotels...';

  @override
  String get trendingNearby => 'Trending Nearby';

  @override
  String get viewOnMap => 'View on Map';

  @override
  String get topDiscoveries => 'Top Rated Discoveries';

  @override
  String get recentlyViewed => 'Recently Viewed';

  @override
  String get directions => 'Directions';

  @override
  String get call => 'Call';

  @override
  String get website => 'Website';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get share => 'Share';

  @override
  String get openNow => 'Open Now';

  @override
  String get closed => 'Closed';

  @override
  String get searchThisArea => 'Search this area';

  @override
  String get retry => 'Retry';

  @override
  String offlineSavedAgo(int minutes) {
    return 'Saved $minutes min ago';
  }

  @override
  String get couldNotLoadPlaces =>
      'Couldn\'t load places. Check your connection and retry';

  @override
  String get settings => 'Settings';

  @override
  String get themeMode => 'Theme Mode';

  @override
  String get deleteAllData => 'Delete All My Data';

  @override
  String get privacyPolicy => 'Privacy Policy';
}
