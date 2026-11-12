// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'स्पॉटफाइंडर';

  @override
  String get exploreSpots => 'स्थान खोजें';

  @override
  String get searchHint => 'कैफे, रेस्तरां, होटल खोजें...';

  @override
  String get trendingNearby => 'आस-पास के लोकप्रिय स्थान';

  @override
  String get viewOnMap => 'नक्शे पर देखें';

  @override
  String get topDiscoveries => 'शीर्ष रेटेड स्थान';

  @override
  String get recentlyViewed => 'हाल ही में देखे गए स्थान';

  @override
  String get directions => 'दिशा-निर्देश';

  @override
  String get call => 'कॉल करें';

  @override
  String get website => 'वेबसाइट';

  @override
  String get save => 'सहेजें';

  @override
  String get saved => 'सहेजा गया';

  @override
  String get share => 'साझा करें';

  @override
  String get openNow => 'अभी खुला है';

  @override
  String get closed => 'बंद है';

  @override
  String get searchThisArea => 'इस क्षेत्र में खोजें';

  @override
  String get retry => 'पुनः प्रयास करें';

  @override
  String offlineSavedAgo(int minutes) {
    return '$minutes मिनट पहले सहेजा गया';
  }

  @override
  String get couldNotLoadPlaces =>
      'स्थान लोड नहीं किए जा सके। अपना इंटरनेट कनेक्शन जांचें और पुनः प्रयास करें';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get themeMode => 'थीम मोड';

  @override
  String get deleteAllData => 'मेरा सारा डेटा हटाएं';

  @override
  String get privacyPolicy => 'गोपनीयता नीति';
}
