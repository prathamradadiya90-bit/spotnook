// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Gujarati (`gu`).
class AppLocalizationsGu extends AppLocalizations {
  AppLocalizationsGu([String locale = 'gu']) : super(locale);

  @override
  String get appName => 'સ્પોટફાઈન્ડર';

  @override
  String get exploreSpots => 'સ્થળો શોધો';

  @override
  String get searchHint => 'કાફે, રેસ્ટોરન્ટ્સ, હોટેલો શોધો...';

  @override
  String get trendingNearby => 'નજીકના લોકપ્રિય સ્થળો';

  @override
  String get viewOnMap => 'નકશા પર જુઓ';

  @override
  String get topDiscoveries => 'શ્રેષ્ઠ સ્થળો';

  @override
  String get recentlyViewed => 'હાલમાં જોયેલા સ્થળો';

  @override
  String get directions => 'દિશાઓ';

  @override
  String get call => 'કોલ કરો';

  @override
  String get website => 'વેબસાઇટ';

  @override
  String get save => 'સાચવો';

  @override
  String get saved => 'સાચવેલ';

  @override
  String get share => 'શેર કરો';

  @override
  String get openNow => 'હમણાં ખુલ્લું છે';

  @override
  String get closed => 'બંધ છે';

  @override
  String get searchThisArea => 'આ વિસ્તારમાં શોધો';

  @override
  String get retry => 'ફરી પ્રયાસ કરો';

  @override
  String offlineSavedAgo(int minutes) {
    return '$minutes મિનિટ પહેલાં સાચવેલ';
  }

  @override
  String get couldNotLoadPlaces =>
      'સ્થળો લોડ કરી શકાયા નથી. તમારું ઇન્ટરનેટ કનેક્શન તપાસો અને ફરી પ્રયાસ કરો';

  @override
  String get settings => 'સેટિંગ્સ';

  @override
  String get themeMode => 'થીમ મોડ';

  @override
  String get deleteAllData => 'મારો બધો ડેટા ડિલીટ કરો';

  @override
  String get privacyPolicy => 'પ્રાઇવસી પોલિસી';
}
