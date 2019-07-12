import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import 'Actual.dart';
import 'AllStops.dart';
import 'NearMe.dart';
import 'widgets/stopList.dart';


void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MyAppState();
  }
}

class MyAppState extends State<MyApp> {
  List<Stop> stops = List<Stop>();
  List<Stop> nearStops = List<Stop>();
  Geolocator geolocator = Geolocator();
  Position userLocation;
  String stopsFileName = 'stops.json';
  String nearStopsFileName = 'nearStops.json';
  File stopsFile;
  File nearStopsFile;
  bool _isLoading = false;

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
    fetchNearStops().then((value){
      setState(() {
        nearStops.addAll(value);
        getApplicationDocumentsDirectory().then((Directory directory){
          File file = new File(directory.path + "/" + nearStopsFileName);
          file.createSync();
          file.writeAsStringSync(json.encode(nearStops));
          print('nearStops saved');
        });
      });
    });
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
    super.initState();
  }

  int _selectedPage = 1;
  final _pageOptions = [
    NearMePage(),
    ActualPage(),
    AllStopsPage(),
  ];
  @override
  Widget build(BuildContext context) {
    return _isLoading ? MaterialApp(home: Scaffold(body:Center(child:Icon(Icons.directions_transit, color: Colors.red,size: 250.0,)))):
    MaterialApp(
      title: 'MHD Virtual Table',
      theme: ThemeData(
        primaryColor: Colors.black,
      ),
      home: Scaffold(
        body: _pageOptions[_selectedPage],
        bottomNavigationBar: BottomNavigationBar(
          // type: BottomNavigationBarType.shifting,
          selectedItemColor: Color(0xFFe90007),
          unselectedItemColor: Color(0xFF737373),
          currentIndex: _selectedPage,
          onTap: (int index) {
            setState((){
              _selectedPage = index;
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.near_me),
              title: Text("Near me")
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.my_location),
              title: Text("Actual")
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              title: Text("All stops")
            ),
          ]
        ),
      )
    );
  }
}