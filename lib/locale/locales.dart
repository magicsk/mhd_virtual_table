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
      'Access to your locaton is restricted by your OS, some functions might not work properly.',
      name: 'attentionDesc',
      desc: 'Attention alert description',
    );
  }
  
  String get unknown {
    return Intl.message(
      'Access unknow!',
      name: 'unknown',
      desc: 'Unknown alert',
    );
  }
  
  String get unknownDesc {
    return Intl.message(
      'Permission status of your position is unknown. Do you want to use your location(must be enabled in settings)? Otherways your location will not be used!',
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
      'Access to your position was denied. Do you want to change it in settings? Otherways some functions will be restricted!',
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