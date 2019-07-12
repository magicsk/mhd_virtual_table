import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
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
    getApplicationDocumentsDirectory().then((Directory directory) {
      nearStopsFile = new File(directory.path + '/' + nearStopsFileName);
      nearStopsExists = nearStopsFile.existsSync();
      if (nearStopsExists) {
        print('nearStops.json exists');
        var _nearStopsFile = List<Stop>();
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
    fetchNearStops().then((value) {
      setState(() {
        nearStops.clear();
        nearStops.addAll(value);
        _isLoadingNew = false;
        getApplicationDocumentsDirectory().then((Directory directory) {
          File file = new File(directory.path + "/" + nearStopsFileName);
          file.createSync();
          file.writeAsStringSync(json.encode(nearStops));
          print('nearStops saved');
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Stops nearby'),
        actions: <Widget>[
          _isLoadingNew
              ? Padding(
                  padding:
                      EdgeInsets.only(top: 21.0, bottom: 19.0, right: 15.0),
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
                  onPressed: () async {
                    setState(() {
                     _isLoadingNew = true; 
                    });
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
                      var nearStopsJson =
                          json.decode(utf8.decode(response.bodyBytes));
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
                        File file =
                            new File(directory.path + "/" + nearStopsFileName);
                        file.createSync();
                        file.writeAsStringSync(json.encode(nearStops));
                        print('nearStops saved');
                      });
                    });
                  })
        ],
        backgroundColor: Color(0xFFe90007),
      ),
      body: Center(
          child: _isLoading
              ? Scaffold()
              : Scrollbar(
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
                                builder: (context) =>
                                    new StopWebView(nearStops[index])));
                      },
                    );
                  },
                ))),
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
