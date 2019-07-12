import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
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

void main() => runApp(new AlertProvider(
      child: new MyApp(),
      config: new AlertConfig(
        ok: "OK",
        cancel: "Cancel",
      ),
    ));

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new MyAppPage(),
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
            content:
                'No internet connection found, this app will not work properly.');
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
        .then((status) {
      if (status == PermissionStatus.granted) {
        _gotPermission = true;
      } else if (status == PermissionStatus.restricted) {
        setState(() {
          _gotPermission = false;
          Alert.alert(context,
              title: "Attention!",
              content:
                  'Acces to your locaton is restricted by your OS, some functions might not work properly.');
        });
        print('restricted');
      } else if (status == PermissionStatus.unknown) {
        Alert.confirm(context,
                title: "Access unknow!",
                content:
                    "Permission status of your position is unknown. Do you want to use your location(must be enabled in settings)? Otherways your location will not be used!")
            .then((int ret) => ret == Alert.OK
                ? _gotPermission = true
                : _gotPermission = false);
      } else if (status == PermissionStatus.disabled) {
        _gotPermission = true;
      } else {
        Alert.confirm(context,
                title: "Access denied!",
                content:
                    "Access to your position was denied. Do you want to change it in settings? Otherways some functions will be restricted!")
            .then((int ret) => ret == Alert.OK
                ? PermissionHandler().openAppSettings()
                : _gotPermission = false);
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
          } else {
            //TODO
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
    return _isLoading
        ? MaterialApp(
            home: Scaffold(
                body: Center(
                    child: Icon(
            Icons.directions_transit,
            color: Colors.red,
            size: 250.0,
          ))))
        : MaterialApp(
            title: 'MHD Virtual Table',
            theme: ThemeData(
              primaryColor: Colors.black,
            ),
            home: Scaffold(
              body: _pageOptions[_selectedPage],
              primary: true,
              bottomNavigationBar: BottomNavigationBar(
                  // type: BottomNavigationBarType.shifting,
                  selectedItemColor: Color(0xFFe90007),
                  unselectedItemColor: Color(0xFF737373),
                  currentIndex: _selectedPage,
                  onTap: (int index) {
                    setState(() {
                      _selectedPage = index;
                    });
                  },
                  items: [
                    BottomNavigationBarItem(
                        icon: Icon(Icons.near_me), title: Text("Near me")),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.my_location), title: Text("Actual")),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.dashboard), title: Text("All stops")),
                  ]),
            ));
  }
}
