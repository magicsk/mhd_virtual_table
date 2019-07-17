import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:persist_theme/persist_theme.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity/connectivity.dart';
import 'package:easy_alert/easy_alert.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import 'Actual.dart';
import 'AllStops.dart';
import 'NearMe.dart';
import 'widgets/stopList.dart';
import 'locale/locales.dart';

void main() => runApp(AlertProvider(
      child: MyApp(),
      config: AlertConfig(
        ok: "OK",
        cancel: "Cancel",
      ),
    ));

var primaryColor = Color(0xFFe90007);

final _model = ThemeModel(
  customLightTheme: ThemeData(
    primaryColor: primaryColor,
    accentColor: Colors.red,
  ),
  customDarkTheme: ThemeData(
    primaryColor: primaryColor,
    accentColor: Colors.red,
    brightness: Brightness.dark,
    primaryColorDark: primaryColor,
    toggleableActiveColor: Colors.red,
  ),
  customBlackTheme: ThemeData(
    primaryColor: primaryColor,
    accentColor: Colors.red,
    brightness: Brightness.dark,
    backgroundColor: Colors.black,
    dialogBackgroundColor: Colors.black,
    scaffoldBackgroundColor: Colors.black,
    bottomAppBarColor: Colors.black,
    primaryColorDark: primaryColor,
    toggleableActiveColor: Colors.red,
  ),
);

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListenableProvider<ThemeModel>(
      builder: (_) => _model..init(),
      child: Consumer<ThemeModel>(builder: (context, model, child) {
        return MaterialApp(
          theme: model.theme,
          localizationsDelegates: [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            const Locale('en', ""), // English
            const Locale('sk', ""), // Slovak
          ],
          home: MyAppPage(),
        );
      }),
    );
  }
}

class MyAppPage extends StatefulWidget {
  MyAppPage({Key key}) : super(key: key);
  @override
  State<StatefulWidget> createState() {
    return MyAppState();
  }
}

class MyAppState extends State<MyAppPage> {
  List<Stop> stops = List<Stop>();
  List<Stop> nearStops = List<Stop>();
  Geolocator geolocator = Geolocator();
  Position userLocation;
  String stopsFileName = 'stops.json';
  String nearStopsFileName = 'nearStops.json';
  File stopsFile;
  File nearStopsFile;
  bool _isLoading = false;
  bool _gotPermission = false;
  bool _networkStatus = false;

  _checkNetworkStatus() async {
    await (Connectivity().checkConnectivity()).then((status) {
      if (status == ConnectivityResult.none) {
        _networkStatus = false;
        Alert.alert(context,
            title: "Offline",
            content: AppLocalizations.of(context).offlineDesc);
      } else {
        _networkStatus = true;
      }
    });
    return _networkStatus;
  }

  _checkPermisson() async {
    await PermissionHandler()
        .requestPermissions([PermissionGroup.locationWhenInUse]);
    await PermissionHandler()
        .checkPermissionStatus(PermissionGroup.locationWhenInUse)
        .then((status) async {
      if (status == PermissionStatus.granted) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('_gotPermission', true);
        _gotPermission = true;
      } else if (status == PermissionStatus.restricted) {
        setState(() async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('_gotPermission', false);
          _gotPermission = false;
          Alert.alert(context,
              title: AppLocalizations.of(context).attention,
              content: AppLocalizations.of(context).attentionDesc);
        });
        print('restricted');
      } else if (status == PermissionStatus.unknown) {
        Alert.confirm(context,
                title: AppLocalizations.of(context).unknown,
                content: AppLocalizations.of(context).unknownDesc)
            .then((int ret) async {
          if (ret == Alert.OK) {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setBool('_gotPermission', true);
            _gotPermission = true;
          } else {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setBool('_gotPermission', false);
            _gotPermission = false;
          }
        });
      } else if (status == PermissionStatus.disabled) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('_gotPermission', true);
        _gotPermission = true;
      } else {
        Alert.confirm(context,
                title: AppLocalizations.of(context).denied,
                content: AppLocalizations.of(context).deniedDesc)
            .then((int ret) async {
          if (ret == Alert.OK) {
            PermissionHandler().openAppSettings();
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setBool('_gotPermission', false);
            _gotPermission = false;
          } else {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setBool('_gotPermission', false);
            _gotPermission = false;
          }
        });
      }
    });
    return _gotPermission;
  }

  Future<List<Stop>> fetchStops() async {
    var url = 'https://api.magicsk.eu/stops';
    var response = await http.get(url);

    var _stops = List<Stop>();
    print("Fetching: " + url);
    if (response.statusCode == 200) {
      var stopsJson = json.decode(utf8.decode(response.bodyBytes));
      for (var stopJson in stopsJson) {
        _stops.add(Stop.fromJson(stopJson));
      }
    }
    return _stops;
  }

  Future<List<Stop>> fetchNearStops() async {
    var currentLocation;
    try {
      currentLocation = await geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low);
    } catch (e) {
      currentLocation = null;
    }
    var url = 'https://api.magicsk.eu/nearme?lat=' +
        currentLocation.latitude.toString() +
        '&long=' +
        currentLocation.longitude.toString();
    var response = await http.get(url);

    var _nearStops = List<Stop>();
    print("Fetching: " + url);
    if (response.statusCode == 200) {
      var nearStopsJson = json.decode(utf8.decode(response.bodyBytes));
      for (var nearStopJson in nearStopsJson) {
        _nearStops.add(Stop.fromJson(nearStopJson));
      }
    }
    return _nearStops;
  }

  @override
  void initState() {
    _checkNetworkStatus().then((status) {
      if (status) {
        _checkPermisson().then((permission) {
          fetchStops().then((value) {
            setState(() {
              stops.addAll(value);
              getApplicationDocumentsDirectory().then((Directory directory) {
                File file = new File(directory.path + "/" + stopsFileName);
                file.createSync();
                file.writeAsStringSync(json.encode(stops));
                print('stops saved');
                _isLoading = false;
              });
            });
          });
          if (permission) {
            fetchNearStops().then((value) {
              setState(() {
                nearStops.addAll(value);
                getApplicationDocumentsDirectory().then((Directory directory) {
                  File file =
                      new File(directory.path + "/" + nearStopsFileName);
                  file.createSync();
                  file.writeAsStringSync(json.encode(nearStops));
                  print('nearStops saved');
                });
              });
            });
          }
        });
      } else {
        setState(() {
          _networkStatus = status;
        });
      }
    });
    super.initState();
  }

  int _selectedPage = 2;
  final _pageOptions = [
    NearMePage(),
    ActualPage(),
    AllStopsPage(),
  ];
  @override
  Widget build(BuildContext context) {
    final _theme = Provider.of<ThemeModel>(context);
    Locale myLocale = Localizations.localeOf(context);
    return ListenableProvider<ThemeModel>(
      builder: (_) => _model..init(),
      child: Consumer<ThemeModel>(builder: (context, model, child) {
        return _isLoading
            ? MaterialApp(
                home: Scaffold(
                  body: Center(
                    child: Icon(
                      Icons.directions_transit,
                      color: Colors.red,
                      size: 250.0,
                    ),
                  ),
                ),
              )
            : MaterialApp(
                theme: model.theme,
                title: 'MHD Virtual Table',
                localizationsDelegates: [
                  AppLocalizationsDelegate(),
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: [
                  const Locale('en', ""), // English
                  const Locale('sk', ""), // Slovak
                ],
                home: Scaffold(
                  body: _pageOptions[_selectedPage],
                  primary: true,
                  bottomNavigationBar: BottomNavigationBar(
                      backgroundColor: model.backgroundColor,
                      // type: BottomNavigationBarType.shifting,
                      selectedItemColor: primaryColor,
                      // unselectedItemColor: Color(0xFF737373),
                      currentIndex: _selectedPage,
                      onTap: (int index) {
                        setState(() {
                          _selectedPage = index;
                        });
                      },
                      items: [
                        BottomNavigationBarItem(
                            icon: Icon(Icons.near_me),
                            title:
                                Text(AppLocalizations.of(context).nearMeNav)),
                        BottomNavigationBarItem(
                            icon: Icon(Icons.my_location),
                            title:
                                Text(AppLocalizations.of(context).actualNav)),
                        BottomNavigationBarItem(
                            icon: Icon(Icons.dashboard),
                            title:
                                Text(AppLocalizations.of(context).allstopsNav)),
                      ]),
                ),
              );
      }),
    );
  }
}
