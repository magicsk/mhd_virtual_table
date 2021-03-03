import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mhd_virtual_table/widgets/webview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:persist_theme/persist_theme.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity/connectivity.dart';
import 'package:easy_alert/easy_alert.dart';
import 'package:geolocator/geolocator.dart';
import 'package:preferences/preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import 'TripPlanner.dart';
import 'Actual.dart';
import 'AllStops.dart';
import 'NearMe.dart';
import 'widgets/stopList.dart';
import 'locale/locales.dart';

void main() async {
  await DotEnv().load('.env');
  WidgetsFlutterBinding.ensureInitialized();
  await PrefService.init(prefix: 'pref_');
  runApp(AlertProvider(
    child: MyApp(),
    config: AlertConfig(
      ok: "OK",
      cancel: "Cancel",
    ),
  ));
}

var primaryColor = Color(0xFFe90007);

final _model = ThemeModel(
  customLightTheme: ThemeData(
    primaryColor: primaryColor,
    accentColor: Colors.red,
    toggleableActiveColor: Colors.red,
    buttonColor: Colors.red,
    appBarTheme: AppBarTheme(brightness: Brightness.dark)
  ),
  customDarkTheme: ThemeData(
    primaryColor: primaryColor,
    accentColor: Colors.red,
    brightness: Brightness.dark,
    primaryColorDark: primaryColor,
    toggleableActiveColor: Colors.red,
    buttonColor: Colors.red,
  ),
  customBlackTheme: ThemeData(
    primaryColor: Colors.black, //can be Colors.grey[90]
    accentColor: Colors.red,
    brightness: Brightness.dark,
    backgroundColor: Colors.black,
    dialogBackgroundColor: Colors.black,
    scaffoldBackgroundColor: Colors.black,
    bottomAppBarColor: Colors.black,
    primaryColorDark: primaryColor,
    toggleableActiveColor: Colors.red,
    buttonColor: Colors.red,
    canvasColor: Colors.black,
  ),
);

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListenableProvider<ThemeModel>(
      create: (_) => _model..init(),
      child: Consumer<ThemeModel>(builder: (context, model, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
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
  String tableTheme = 'auto';
  bool legalAgreed = false;
  bool _isLoading = false;
  bool _gotPermission = false;
  bool _networkStatus = false;

  _getPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    tableTheme = prefs.getString('tableTheme');
    legalAgreed = prefs.getBool('legalAgreed');
    if (tableTheme == null) {
      prefs.setString('tableTheme', 'auto');
      await _getPrefs();
    }
  }

  _checkNetworkStatus() async {
    await (Connectivity().checkConnectivity()).then((status) {
      if (status == ConnectivityResult.none) {
        _networkStatus = false;
        Alert.alert(context, title: "Offline", content: AppLocalizations.of(context).offlineDesc);
      } else {
        _networkStatus = true;
      }
    });
    return _networkStatus;
  }

  _checkPermission() async {
    await Permission.locationWhenInUse.request();
    _gotPermission = await Permission.location.isGranted;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('_gotPermission', _gotPermission);
      if (_gotPermission) {
        _gotPermission = true;
      } else if (await Permission.locationWhenInUse.isDenied) {
        Alert.confirm(context, title: AppLocalizations.of(context).denied, content: AppLocalizations.of(context).deniedDesc).then((int ret) async {
          if (ret == Alert.OK) {
            Permission.locationWhenInUse.request();
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
    return _gotPermission;
  }

  // Future<List<Stop>> fetchStops() async {
  //   var url = 'https://api.magicsk.eu/stops';
  //   var response = await http.get(url);

  //   var _stops = List<Stop>();
  //   print("Fetching: " + url);
  //   if (response.statusCode == 200) {
  //     var stopsJson = json.decode(utf8.decode(response.bodyBytes));
  //     for (var stopJson in stopsJson) {
  //       _stops.add(Stop.fromJson(stopJson));
  //     }
  //   }
  //   return _stops;
  // }

  Future<List<Stop>> fetchNearStops() async {
    var currentLocation;
    try {
      currentLocation = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
    } catch (e) {
      currentLocation = null;
    }
    var url = 'https://api.magicsk.eu/nearme?lat=' + currentLocation.latitude.toString() + '&long=' + currentLocation.longitude.toString();
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

  _legalAlert() {
    if (legalAgreed == null || !legalAgreed) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async {
              exit(0);
            },
            child: AlertDialog(
              backgroundColor: Theme.of(context).brightness == Brightness.light ? Colors.white : Colors.grey[800],
              title: Text(AppLocalizations.of(context).tospp),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  RichText(
                      textAlign: TextAlign.justify,
                      text: TextSpan(children: <TextSpan>[
                        TextSpan(text: AppLocalizations.of(context).provided, style: TextStyle(color: Theme.of(context).textTheme.subtitle2.color)),
                        TextSpan(
                            text: AppLocalizations.of(context).license,
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                    context,
                                    new MaterialPageRoute(
                                        builder: (context) => new BasicWebView('https://github.com/magicsk/mhd_virtual_table/blob/master/LICENSE')));
                              }),
                        TextSpan(
                            text: AppLocalizations.of(context).tos1,
                            style: TextStyle(color: Theme.of(context).textTheme.subtitle2.color)),
                        TextSpan(
                            text: AppLocalizations.of(context).license,
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                    context,
                                    new MaterialPageRoute(
                                        builder: (context) => new BasicWebView('https://github.com/magicsk/mhd_virtual_table/blob/master/LICENSE')));
                              }),
                        TextSpan(
                            text: AppLocalizations.of(context).tos2,
                            style: TextStyle(color: Theme.of(context).textTheme.subtitle2.color)),
                        TextSpan(
                            text: AppLocalizations.of(context).license2,
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                    context,
                                    new MaterialPageRoute(
                                        builder: (context) => new BasicWebView('https://github.com/magicsk/mhd_virtual_table/blob/master/LICENSE')));
                              }),
                        TextSpan(text: AppLocalizations.of(context).tos3, style: TextStyle(color: Theme.of(context).textTheme.subtitle2.color)),
                      ])),
                  RichText(text: TextSpan(text: '')),
                  RichText(
                    textAlign: TextAlign.justify,
                    text: TextSpan(children: <TextSpan>[
                      TextSpan(
                          text: AppLocalizations.of(context).tos4,
                          style: TextStyle(color: Theme.of(context).textTheme.subtitle2.color)),
                      TextSpan(
                          text: AppLocalizations.of(context).gToS,
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(context, new MaterialPageRoute(builder: (context) => new BasicWebView('https://policies.google.com/terms')));
                            }),
                      TextSpan(text: AppLocalizations.of(context).and, style: TextStyle(color: Theme.of(context).textTheme.subtitle2.color)),
                      TextSpan(
                          text: AppLocalizations.of(context).gPP,
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(context, new MaterialPageRoute(builder: (context) => new BasicWebView('https://policies.google.com/privacy')));
                            }),
                      TextSpan(text: '.'),
                    ]),
                  )
                ],
              ),
              actions: <Widget>[
                FlatButton(
                  onPressed: () {
                    legalAgreed = true;
                    SharedPreferences.getInstance().then((prefs) => prefs.setBool("legalAgreed", true));
                    Navigator.pop(context);
                  },
                  child: Text(AppLocalizations.of(context).accept),
                ),
                FlatButton(
                  onPressed: () {
                    exit(0);
                  },
                  child: Text(AppLocalizations.of(context).decline),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  @override
  void initState() {
    _getPrefs().then((prefs) => _legalAlert());
    _checkNetworkStatus().then((status) {
      if (status) {
        _checkPermission().then((permission) {
          // fetchStops().then((value) {
          //   setState(() {
          //     stops.removeRange(0, stops.length);
          //     stops.addAll(value);
          //     getApplicationDocumentsDirectory().then((Directory directory) {
          //       File file = new File(directory.path + "/" + stopsFileName);
          //       file.createSync();
          //       file.writeAsStringSync(json.encode(stops));
          //       print('stops saved');
          //       _isLoading = false;
          //     });
          //   });
          // });
          if (permission) {
            fetchNearStops().then((value) {
              setState(() {
                nearStops.addAll(value);
                getApplicationDocumentsDirectory().then((Directory directory) {
                  File file = new File(directory.path + "/" + nearStopsFileName);
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

  final PageStorageBucket bucket = PageStorageBucket();
  int _selectedIndex = 3;

  final List<Widget> pages = [
    TripPlannerPage(
      key: PageStorageKey('TripPlanner'),
    ),
    NearMePage(
      key: PageStorageKey('NearMe'),
    ),
    ActualPage(
      key: PageStorageKey('Actual'),
    ),
    AllStopsPage(
      key: PageStorageKey('AllStops'),
    ),
  ];

  Widget _bottomNavigationBar(int selectedIndex, ThemeModel model) => BottomNavigationBar(
          backgroundColor: model.accentColor,
          type: BottomNavigationBarType.shifting,
          selectedItemColor: primaryColor,
          unselectedItemColor: Color(0xFF737373),
          currentIndex: selectedIndex,
          onTap: _onTap,
          items: [
            // add localization
            BottomNavigationBarItem(icon: Icon(Icons.transfer_within_a_station), label: AppLocalizations.of(context).tripPlannerNav),
            BottomNavigationBarItem(icon: Icon(Icons.near_me), label: AppLocalizations.of(context).nearMeNav),
            BottomNavigationBarItem(icon: Icon(Icons.my_location), label: AppLocalizations.of(context).actualNav),
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: AppLocalizations.of(context).allstopsNav),
          ]);

  void _onTap(int i){
    setState(() => _selectedIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    final _theme = Provider.of<ThemeModel>(context);
    _theme.checkPlatformBrightness(context);
    Locale myLocale = Localizations.localeOf(context);
    return ListenableProvider<ThemeModel>.value(
      value: _model..init(),
      child: Consumer<ThemeModel>(builder: (context, model, child) {
        return _isLoading
            ? MaterialApp(
                debugShowCheckedModeBanner: false,
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
                debugShowCheckedModeBanner: false,
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
                  body: pages[_selectedIndex],
                  primary: true,
                  bottomNavigationBar: _bottomNavigationBar(_selectedIndex, model),
                ),
              );
      }),
    );
  }
}
