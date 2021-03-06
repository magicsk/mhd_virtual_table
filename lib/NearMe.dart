import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity/connectivity.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import 'widgets/stopwebview.dart';
import 'widgets/stopList.dart';
import 'locale/locales.dart';

class NearMePage extends StatefulWidget {
  const NearMePage({Key key}) : super(key: key);
  @override
  _NearMeState createState() => _NearMeState();
}

class _NearMeState extends State<NearMePage> {
  List<Stop> nearStops = [];
  Geolocator geolocator = Geolocator();
  Position userLocation;
  File nearStopsFile;
  String nearStopsFileName = 'nearStops.json';
  bool nearStopsExists = false;
  bool _isLoadingNew = true;
  bool _isLoading = true;
  bool _gotPermission = false;
  bool _locationStatus = false;
  bool _networkStatus = false;
  bool _restricted = false;
  bool _error = false;
  String tableTheme;

  _getprefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      tableTheme = prefs.getString('tableTheme');
      _gotPermission = (prefs.getBool('_gotPermission') ?? false);
      print(_gotPermission);
    });
    return _gotPermission;
  }

  _checkNetworkStatus() async {
    await (Connectivity().checkConnectivity()).then((status) {
      if (status == ConnectivityResult.none) {
        _networkStatus = false;
      } else {
        _networkStatus = true;
      }
    });
    return _networkStatus;
  }

  _checkLocationStatus() async {
    return await Permission.location.isGranted;
  }

  Future<List<Stop>> fetchNearStops() async {
    var currentLocation;
    try {
      currentLocation = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    } catch (e) {
      currentLocation = null;
    }
    var url = 'https://api.magicsk.eu/nearme?lat=' + currentLocation.latitude.toString() + '&long=' + currentLocation.longitude.toString();
    var response = await http.get(url);

    List<Stop> _nearStops = [];
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
        getApplicationDocumentsDirectory().then((Directory directory) {
          nearStopsFile = new File(directory.path + '/' + nearStopsFileName);
          nearStopsExists = nearStopsFile.existsSync();
          if (nearStopsExists) {
            print('nearStops.json exists');
            List<Stop> _nearStopsFile = [];
            var nearStopsFileJson = json.decode((nearStopsFile.readAsStringSync()));
            for (var nearStopFileJson in nearStopsFileJson) {
              _nearStopsFile.add(Stop.fromJson(nearStopFileJson));
            }
            nearStops.clear();
            nearStops.addAll(_nearStopsFile);
            print('nearStops loaded');
            _getprefs().then((permission) {
              _checkLocationStatus().then((status) {
                setState(() {
                  _locationStatus = status;
                  _gotPermission = permission;
                  _isLoading = false;
                });
              });
            });
          }
        });
        _getprefs().then((permission) {
          setState(() {
            _gotPermission = permission;
          });
          if (permission) {
            _checkLocationStatus().then((status) {
              setState(() {
                _locationStatus = status;
              });
              if (status) {
                fetchNearStops().then((value) {
                  print(value.length);
                  if (value.length == 0) {
                    print('Unable to fetch!');
                    setState(() {
                      _error = true;
                      _isLoading = false;
                      _isLoadingNew = false;
                    });
                  } else {
                    setState(() {
                      nearStops.clear();
                      nearStops.addAll(value);
                      _error = false;
                      _isLoadingNew = false;
                      _isLoading = false;
                      getApplicationDocumentsDirectory().then((Directory directory) {
                        File file = new File(directory.path + "/" + nearStopsFileName);
                        file.createSync();
                        file.writeAsStringSync(json.encode(nearStops));
                        print('nearStops saved');
                      });
                    });
                  }
                });
              } else {
                setState(() {
                  _isLoadingNew = false;
                  _isLoading = false;
                });
              }
            });
          } else {
            setState(() {
              _isLoadingNew = false;
              _isLoading = false;
            });
          }
        });
      } else {
        setState(() {
          _networkStatus = status;
          _isLoading = false;
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(AppLocalizations.of(context).nearMeTitle),
        actions: _networkStatus
            ? <Widget>[
                _isLoadingNew
                    ? Padding(
                        padding: EdgeInsets.only(top: 21.0, bottom: 19.0, right: 15.0),
                        child: SizedBox(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                          width: 15.0,
                        ))
                    : IconButton(
                        icon: Icon(Icons.refresh),
                        color: Colors.white,
                        onPressed: _locationStatus
                            ? () async {
                                setState(() {
                                  _isLoadingNew = true;
                                });
                                var currentLocation;
                                try {
                                  currentLocation = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
                                } catch (e) {
                                  currentLocation = null;
                                }
                                var url = 'https://api.magicsk.eu/nearme?lat=' +
                                    currentLocation.latitude.toString() +
                                    '&long=' +
                                    currentLocation.longitude.toString();
                                var response = await http.get(url);

                                List<Stop> _nearStops = [];
                                print("Fetching: " + url);
                                if (response.statusCode == 200) {
                                  var nearStopsJson = json.decode(utf8.decode(response.bodyBytes));
                                  for (var nearStopJson in nearStopsJson) {
                                    _nearStops.add(Stop.fromJson(nearStopJson));
                                  }
                                }
                                setState(() {
                                  nearStops.clear();
                                  nearStops.addAll(_nearStops);
                                  _isLoadingNew = false;
                                  getApplicationDocumentsDirectory().then((Directory directory) {
                                    File file = new File(directory.path + "/" + nearStopsFileName);
                                    file.createSync();
                                    file.writeAsStringSync(json.encode(nearStops));
                                    print('nearStops saved');
                                  });
                                });
                              }
                            : null)
              ]
            : null,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _networkStatus
              ? Center(
                  child: _isLoading
                      ? Center()
                      : _locationStatus
                          ? _error
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: <Widget>[
                                      Icon(Icons.warning, size: 150.0, color: Colors.grey[300]),
                                      Text(AppLocalizations.of(context).unavailable, style: TextStyle(color: Colors.grey[500]))
                                    ],
                                  ),
                                )
                              : Scrollbar(
                                  child: ListView.builder(
                                    scrollDirection: Axis.vertical,
                                    itemCount: nearStops.length,
                                    itemBuilder: (context, index) {
                                      return new Column(
                                        children: [
                                          TextButton(
                                            child: NearStopRow(nearStops[index]),
                                            onPressed: () {
                                              Navigator.push(context, new MaterialPageRoute(builder: (context) => new StopWebView(nearStops[index])));
                                            },
                                          ),
                                          Divider(
                                            height: 2.0,
                                            color: Colors.grey,
                                          )
                                        ],
                                      );
                                    },
                                  ),
                                )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: _restricted
                                    ? <Widget>[
                                        Icon(
                                          Icons.not_interested,
                                          size: 150.0,
                                          color: Colors.grey[300],
                                        ),
                                        Text(AppLocalizations.of(context).restrictedNearMe, style: TextStyle(color: Colors.grey[500]))
                                      ]
                                    : <Widget>[
                                        Icon(
                                          Icons.location_off,
                                          size: 150.0,
                                          color: Colors.grey[300],
                                        ),
                                        _gotPermission
                                            ? _locationStatus
                                                ? Text(
                                                    AppLocalizations.of(context).wrongNearMe,
                                                    style: TextStyle(color: Colors.grey[500]),
                                                  )
                                                : Text(
                                                    AppLocalizations.of(context).offLocationNearMe,
                                                    style: TextStyle(color: Colors.grey[500]),
                                                  )
                                            : Text(
                                                AppLocalizations.of(context).locationDeniedNearMe,
                                                style: TextStyle(color: Colors.grey[500]),
                                              ),
                                      ],
                              ),
                            ),
                )
              : Center(
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.signal_cellular_off,
                      size: 150.0,
                      color: Colors.grey[300],
                    ),
                    Text(
                      AppLocalizations.of(context).noConnectionNearMe,
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                    ElevatedButton(
                      child: Text(AppLocalizations.of(context).retryBtn),
                      onPressed: () async {
                        await (Connectivity().checkConnectivity()).then((status) {
                          if (status == ConnectivityResult.none) {
                            setState(() {
                              _networkStatus = false;
                            });
                          } else {
                            setState(() {
                              _networkStatus = true;
                              _isLoadingNew = false;
                            });
                            getApplicationDocumentsDirectory().then((Directory directory) {
                              nearStopsFile = new File(directory.path + '/' + nearStopsFileName);
                              nearStopsExists = nearStopsFile.existsSync();
                              if (nearStopsExists) {
                                print('nearStops.json exists');
                                List<Stop> _nearStopsFile = [];
                                var nearStopsFileJson = json.decode((nearStopsFile.readAsStringSync()));
                                for (var nearStopFileJson in nearStopsFileJson) {
                                  _nearStopsFile.add(Stop.fromJson(nearStopFileJson));
                                }
                                nearStops.clear();
                                nearStops.addAll(_nearStopsFile);
                                print('nearStops loaded');
                                setState(() {
                                  _isLoading = false;
                                });
                              }
                            });
                          }
                        });
                      },
                    ),
                  ],
                )),
    );
  }
}

class NearStopRow extends StatelessWidget {
  final Stop stop;
  NearStopRow(this.stop);
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Flex(
          direction: Axis.horizontal,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 13.5, bottom: 13.5),
              child: Text(
                stop.name,
                style: TextStyle(fontSize: 17.5, fontWeight: FontWeight.normal, color: Theme.of(context).textTheme.bodyText1.color),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
