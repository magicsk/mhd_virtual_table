import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity/connectivity.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import 'widgets/webview.dart';
import 'widgets/stopList.dart';

class NearMePage extends StatefulWidget {
  @override
  _NearMeState createState() => _NearMeState();
}

class _NearMeState extends State<NearMePage> {
  List<Stop> nearStops = List<Stop>();
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
    await PermissionHandler()
        .checkServiceStatus(PermissionGroup.location)
        .then((status) {
      if (status == ServiceStatus.enabled) {
        _locationStatus = true;
      } else {
        _locationStatus = false;
      }
    });
    return _locationStatus;
  }

  _checkPermisson() async {
    await PermissionHandler()
        .checkPermissionStatus(PermissionGroup.locationWhenInUse)
        .then((status) {
      if (status == PermissionStatus.granted) {
        _gotPermission = true;
      } else if (status == PermissionStatus.restricted) {
        setState(() {
          _gotPermission = false;
          _restricted = true;
        });
        print('restricted');
      } else if (status == PermissionStatus.unknown) {
        _gotPermission = true;
      } else if (status == PermissionStatus.disabled) {
        _gotPermission = true;
      } else {
        _gotPermission = false;
      }
    });
    return _gotPermission;
  }

  Future<List<Stop>> fetchNearStops() async {
    var currentLocation;
    try {
      currentLocation = await geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
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
    super.initState();
    _checkNetworkStatus().then((status) {
      if (status) {
        getApplicationDocumentsDirectory().then((Directory directory) {
          nearStopsFile = new File(directory.path + '/' + nearStopsFileName);
          nearStopsExists = nearStopsFile.existsSync();
          if (nearStopsExists) {
            print('nearStops.json exists');
            var _nearStopsFile = List<Stop>();
            var nearStopsFileJson =
                json.decode((nearStopsFile.readAsStringSync()));
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
        _checkLocationStatus().then((status) {
          setState(() {
            _locationStatus = status;
          });
          if (status) {
            _checkPermisson().then((permission) {
              setState(() {
                _gotPermission = permission;
              });
              if (permission) {
                fetchNearStops().then((value) {
                  setState(() {
                    nearStops.clear();
                    nearStops.addAll(value);
                    _isLoadingNew = false;
                    getApplicationDocumentsDirectory()
                        .then((Directory directory) {
                      File file =
                          new File(directory.path + "/" + nearStopsFileName);
                      file.createSync();
                      file.writeAsStringSync(json.encode(nearStops));
                      print('nearStops saved');
                    });
                  });
                });
              } else {
                setState(() {
                  _isLoadingNew = false;
                  _locationStatus = false;
                });
              }
            });
          } else {
            _checkPermisson().then((permission) {
              setState(() {
                _gotPermission = permission;
              });
            });
            setState(() {
              _isLoadingNew = false;
              _locationStatus = false;
              _isLoading = false;
            });
          }
        });
      } else {
        setState(() {
          _networkStatus = status;
          _isLoading = true;
        });
        _checkPermisson().then((permission) {
          setState(() {
            _gotPermission = permission;
          });
        });       
         _checkLocationStatus().then((status) {
          setState(() {
            _locationStatus = status;
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Nearest stops'),
        actions: _networkStatus
            ? <Widget>[
                _isLoadingNew
                    ? Padding(
                        padding: EdgeInsets.only(
                            top: 21.0, bottom: 19.0, right: 15.0),
                        child: SizedBox(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
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
                                  currentLocation =
                                      await geolocator.getCurrentPosition(
                                          desiredAccuracy:
                                              LocationAccuracy.best);
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
                                  var nearStopsJson = json
                                      .decode(utf8.decode(response.bodyBytes));
                                  for (var nearStopJson in nearStopsJson) {
                                    _nearStops.add(Stop.fromJson(nearStopJson));
                                  }
                                }
                                setState(() {
                                  nearStops.clear();
                                  nearStops.addAll(_nearStops);
                                  _isLoadingNew = false;
                                  getApplicationDocumentsDirectory()
                                      .then((Directory directory) {
                                    File file = new File(directory.path +
                                        "/" +
                                        nearStopsFileName);
                                    file.createSync();
                                    file.writeAsStringSync(
                                        json.encode(nearStops));
                                    print('nearStops saved');
                                  });
                                });
                              }
                            : null)
              ]
            : null,
        backgroundColor: Color(0xFFe90007),
      ),
      body: _networkStatus
          ? Center(
              child: _isLoading
                  ? Center()
                  : _locationStatus
                      ? Scrollbar(
                          child: ListView.builder(
                            scrollDirection: Axis.vertical,
                            itemCount: nearStops.length,
                            itemBuilder: (context, index) {
                              return new FlatButton(
                                child: NearStopRow(nearStops[index]),
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      new MaterialPageRoute(
                                          builder: (context) => new StopWebView(
                                              nearStops[index])));
                                },
                              );
                            },
                          ),
                        )
                      : Padding(
                          padding: EdgeInsets.only(top: 250.0),
                          child: Center(
                            child: Column(
                              children: _restricted
                                  ? <Widget>[
                                      Icon(
                                        Icons.not_interested,
                                        size: 200.0,
                                        color: Colors.grey[300],
                                      ),
                                      Text(
                                          'Access to your location is restricted by OS!',
                                          style: TextStyle(
                                              color: Colors.grey[500]))
                                    ]
                                  : <Widget>[
                                      Icon(
                                        Icons.location_off,
                                        size: 200.0,
                                        color: Colors.grey[300],
                                      ),
                                      _gotPermission
                                          ? Text('Location is turned off!',
                                              style: TextStyle(
                                                  color: Colors.grey[500]))
                                          : _locationStatus
                                              ? Text('Something went wrong!',
                                                  style: TextStyle(
                                                      color: Colors.grey[500]))
                                              : Text(
                                                  'Access to location is denied!',
                                                  style: TextStyle(
                                                      color: Colors.grey[500])),
                                    ],
                            ),
                          ),
                        ),
            )
          : Center(
              child: Padding(
              padding: EdgeInsets.only(top: 250.0),
              child: Column(
                children: <Widget>[
                  Icon(
                    Icons.signal_cellular_off,
                    size: 200.0,
                    color: Colors.grey[300],
                  ),
                  Text(
                    'No internet connection!',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  RaisedButton(
                    child: Text('RETRY'),
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
                          getApplicationDocumentsDirectory()
                              .then((Directory directory) {
                            nearStopsFile = new File(
                                directory.path + '/' + nearStopsFileName);
                            nearStopsExists = nearStopsFile.existsSync();
                            if (nearStopsExists) {
                              print('nearStops.json exists');
                              var _nearStopsFile = List<Stop>();
                              var nearStopsFileJson = json
                                  .decode((nearStopsFile.readAsStringSync()));
                              for (var nearStopFileJson in nearStopsFileJson) {
                                _nearStopsFile
                                    .add(Stop.fromJson(nearStopFileJson));
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
              ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(
                      top: 16.0, bottom: 16.0, left: 16.0),
                  child: Text(
                    stop.name,
                    style: TextStyle(
                        fontSize: 17.5, fontWeight: FontWeight.normal),
                  ),
                ),
              ],
            ),
          ],
        ),
        Divider(
          height: 2.0,
          color: Colors.grey,
        )
      ],
    );
  }
}
