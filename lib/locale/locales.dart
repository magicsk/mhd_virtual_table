import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import 'package:mhd_virtual_table/l10n/messages_all.dart';

class AppLocalizations {
  static Future<AppLocalizations> load(Locale locale) {
    final String name =
        locale.countryCode.isEmpty ? locale.languageCode : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);

    return initializeMessages(localeName).then((bool _) {
      Intl.defaultLocale = localeName;
      return AppLocalizations();
    });
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  String get cancel {
    return Intl.message(
      'Cancel',
      name: 'cancel',
      desc: 'Cancel alert button',
    );
  }

  String get offlineDesc {
    return Intl.message(
      'No internet connection found, this app will not work properly.',
      name: 'offlineDesc',
      desc: 'Offline alert description',
    );
  }

  String get attention {
    return Intl.message(
      'Attention!',
      name: 'attention',
      desc: 'Attention alert',
    );
  }

  String get attentionDesc {
    return Intl.message(
      'Access to your location is restricted by your OS, some functions might not work properly.',
      name: 'attentionDesc',
      desc: 'Attention alert description',
    );
  }
  
  String get unknown {
    return Intl.message(
      'Access unknown!',
      name: 'unknown',
      desc: 'Unknown alert',
    );
  }
  
  String get unknownDesc {
    return Intl.message(
      'Permission status of your position is unknown. Do you want to use your location(must be enabled in settings)? Otherwise your location will not be used!',
      name: 'unknownDesc',
      desc: 'Unknown alert description',
    );
  }
  
  String get denied {
    return Intl.message(
      'Access denied!',
      name: 'denied',
      desc: 'Denied alert',
    );
  }
  
  String get deniedDesc {
    return Intl.message(
      'Access to your position was denied. Do you want to change it in settings? Otherwise some functions will be restricted!',
      name: 'deniedDesc',
      desc: 'Denied alert description',
    );
  }
  
  String get nearMeNav {
    return Intl.message(
      'Near me',
      name: 'nearMeNav',
      desc: 'Bottom Navigation Bar Near me',
    );
  }

  String get actualNav {
    return Intl.message(
      'Actual',
      name: 'actualNav',
      desc: 'Bottom Navigation Bar Actual',
    );
  }

  String get allstopsNav {
    return Intl.message(
      'All stops',
      name: 'allstopsNav',
      desc: 'Bottom Navigation Bar All stops',
    );
  }

  String get tripPlannerNav {
    return Intl.message(
      'Trip planner',
      name: 'tripPlannerNav',
      desc: 'Bottom Navigation Bar Trip planner',
    );
  }
  
  String get nearMeTitle {
    return Intl.message(
      'Nearest stops',
      name: 'nearMeTitle',
      desc: 'Title Near me',
    );
  }

  String get allstopsTitle {
    return Intl.message(
      'Stops',
      name: 'allstopsTitle',
      desc: 'Title All stops',
    );
  }

  String get tripPlannerTitle {
    return Intl.message(
      'Trip planner',
      name: 'tripPlannerTitle',
      desc: 'Title Trip planner',
    );
  }
    
  String get settingsTitle {
    return Intl.message(
      'Settings',
      name: 'settingsTitle',
      desc: 'Settings Title',
    );
  }  

  String get restrictedNearMe {
    return Intl.message(
      'Access to your location is restricted by OS!',
      name: 'restrictedNearMe',
      desc: 'Restricted Background Near Me',
    );
  }

  String get offLocationNearMe {
    return Intl.message(
      'Location is turned off!',
      name: 'offLocationNearMe',
      desc: 'Location off Background Near Me',
    );
  }

  String get wrongNearMe {
    return Intl.message(
      'Something went wrong!',
      name: 'wrongNearMe',
      desc: 'Wrong Background Near Me',
    );
  }

  String get locationDeniedNearMe {
    return Intl.message(
      'Access to location is denied!',
      name: 'locationDeniedNearMe',
      desc: 'Location Denied Background Near Me',
    );
  }

  String get noConnectionNearMe {
    return Intl.message(
      'No internet connection!',
      name: 'noConnectionNearMe',
      desc: 'No Connection Background Near Me',
    );
  }  
  
  String get retryBtn {
    return Intl.message(
      'RETRY',
      name: 'retryBtn',
      desc: 'Retry button',
    );
  }  

  String get searchHint {
    return Intl.message(
      'Search...',
      name: 'searchHint',
      desc: 'Search Hint',
    );
  }
  
  String get autoTheme {
    return Intl.message(
      'Automatic',
      name: 'autoTheme',
      desc: 'Automatic option',
    );
  }  
  
  String get darkTheme {
    return Intl.message(
      'Dark theme',
      name: 'darkTheme',
      desc: 'Dark theme option',
    );
  }  
  
  String get blackTheme {
    return Intl.message(
      'Black theme',
      name: 'blackTheme',
      desc: 'Dark theme option',
    );
  }
  
  String get tableTheme {
    return Intl.message(
      'Table theme',
      name: 'tableTheme',
      desc: 'Table theme option',
    );
  }
  
  String get anonymousCloudSave {
    return Intl.message(
      'Anonymous cloud save(WIP)',
      name: 'anonymousCloudSave',
      desc: 'Anonymous cloud save title',
    );
  }
  
  String get loadSettings {
    return Intl.message(
      'Load settings',
      name: 'loadSettings',
      desc: 'Load settings',
    );
  }
  
  String get saveSettings {
    return Intl.message(
      'Save settings',
      name: 'saveSettings',
      desc: 'Save settings',
    );
  }
  
  String get tospp {
    return Intl.message(
      'Terms of Use and Privacy Policy',
      name: 'tospp',
      desc: 'Terms of Use and Privacy Policy',
    );
  }
  
  String get provided {
    return Intl.message(
      'MHD Virtual Table is provided under this ',
      name: 'provided',
      desc: 'MHD Virtual Table is provided under this ',
    );
  }
  
  String get license {
    return Intl.message(
      'License',
      name: 'license',
      desc: 'License',
    );
  }
  
  String get license2 {
    return Intl.message(
      'License',
      name: 'license2',
      desc: 'License',
    );
  }
  
  String get tos1 {
    return Intl.message(
      ' on an "as is" basis, without warranty of any kind, either expressed, implied, or statutory, including, without limitation, warranties that the Covered Software is free of defects, merchantable, fit for a particular purpose or non-infringing. The entire risk as to the quality and performance of the Covered Software is with You. Should any Covered Software prove defective in any respect, You (not any Contributor) assume the cost of any necessary servicing, repair, or correction. This disclaimer of warranty constitutes an essential part of this ',
      name: 'tos1',
      desc: ' on an "as is" basis, without warranty of any kind, either expressed, implied, or statutory, including, without limitation, warranties that the Covered Software is free of defects, merchantable, fit for a particular purpose or non-infringing. The entire risk as to the quality and performance of the Covered Software is with You. Should any Covered Software prove defective in any respect, You (not any Contributor) assume the cost of any necessary servicing, repair, or correction. This disclaimer of warranty constitutes an essential part of this ',
    );
  }
  
  String get tos2 {
    return Intl.message(
      '. No use of any Covered Software is authorized under this ',
      name: 'tos2',
      desc: '. No use of any Covered Software is authorized under this ',
    );
  }
  
  String get tos3 {
    return Intl.message(
      ' except under this disclaimer.',
      name: 'tos3',
      desc: ' except under this disclaimer.',
    );
  }
  
  String get tos4 {
    return Intl.message(
      'MHD Virtual Table is also using Google services. By using it you agree with ',
      name: 'tos4',
      desc: 'MHD Virtual Table is also using Google services. By using it you agree with ',
    );
  }
  
  String get gToS {
    return Intl.message(
      'Google’s Terms of Service',
      name: 'gToS',
      desc: 'Google’s Terms of Service',
    );
  }
  
  String get gPP {
    return Intl.message(
      'Google Privacy Policy',
      name: 'gPP',
      desc: 'Google Privacy Policy',
    );
  }
  
  String get and {
    return Intl.message(
      ' and ',
      name: 'and',
      desc: ' and ',
    );
  }
  
  String get accept {
    return Intl.message(
      'Accept',
      name: 'accept',
      desc: 'Accept',
    );
  }
  
  String get decline {
    return Intl.message(
      'Decline',
      name: 'decline',
      desc: 'Decline',
    );
  }
  
  String get unavailable {
    return Intl.message(
      'Currently unavailable, try again later!',
      name: 'unavailable',
      desc: 'Currently unavailable, try again later!',
    );
  }
  
  String get actualPosition {
    return Intl.message(
      'Actual position',
      name: 'actualPosition',
      desc: 'Actual position',
    );
  }
  
  String get altApi {
    return Intl.message(
      'Alternative api',
      name: 'altApi',
      desc: 'Alternative api',
    );
  }
  
  String get noResults {
    return Intl.message(
      'No results found!',
      name: 'noResults',
      desc: 'No results found!',
    );
  }
  
  String get errorUnknown {
    return Intl.message(
      'Something went wrong!',
      name: 'errorUnknown',
      desc: 'Something went wrong!',
    );
  }
  
  String get planDesc {
    return Intl.message(
      'Plan your journey via public transport!',
      name: 'planDesc',
      desc: 'Plan your journey via public transport!',
    );
  }
  
  String get addFav {
    return Intl.message(
      'Add to Favorites',
      name: 'addFav',
      desc: 'Add to Favorites',
    );
  }
  
  String get train {
    return Intl.message(
      'Train',
      name: 'train',
      desc: 'Train',
    );
  }
  
  String get goToStop {
    return Intl.message(
      'Go to stop ',
      name: 'goToStop',
      desc: 'Go to stop ',
    );
  }
  
  String get stop {
    return Intl.message(
      'stop',
      name: 'stop',
      desc: 'stop',
    );
  }
  
  String get departure {
    return Intl.message(
      'Departure',
      name: 'departure',
      desc: 'Departure',
    );
  }
  
  String get arrival {
    return Intl.message(
      'Arrival',
      name: 'arrival',
      desc: 'Arrival',
    );
  }
  
  String get favorites {
    return Intl.message(
      'Favorites',
      name: 'favorites',
      desc: 'Favorites',
    );
  }
  
  String get delete {
    return Intl.message(
      'Delete',
      name: 'delete',
      desc: 'Delete',
    );
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'sk'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return AppLocalizations.load(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) {
    return false;
  }
}