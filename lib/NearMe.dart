import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'widgets/webview.dart';

class NearMePage extends StatefulWidget {
  @override
  _NearMeState createState() => _NearMeState();
}

class NearStop {
  final String name;
  final String url;
  NearStop(this.name, this.url);
}

Geolocator geolocator = Geolocator();
Position userLocation;

class _NearMeState extends State<NearMePage> {
  final stops = new List<NearStop>();
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNearStops();
  }

  _fetchNearStops() async {
    var currentLocation;
    try {
      currentLocation = await geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
    } catch (e) {
      currentLocation = null;
    }
    final urlString = 'https://api.magicsk.eu/nearme?lat=' +
        currentLocation.latitude.toString() +
        '&long=' +
        currentLocation.longitude.toString();
    print("Fetching: " + urlString);
    final response = await http.get(urlString);
    final stopsJson = json.decode(utf8.decode(response.bodyBytes));
    stopsJson.forEach((stopJson) {
      final stop = new NearStop(stopJson["name"], stopJson["url"]);
      stops.add(stop);
    });
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: PreferredSize(
          preferredSize: Size.fromHeight(0.0),
          child: AppBar()),
      body: new Center(
          child: _isLoading
              ? new CircularProgressIndicator()
              : new Scrollbar(
                  child: ListView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: stops.length,
                  itemBuilder: (context, i) {
                    final stop = stops[i];
                    return new FlatButton(
                      padding: new EdgeInsets.all(0.0),
                      child: NearStopRow(stop),
                      onPressed: () {
                        Navigator.push(
                            context,
                            new MaterialPageRoute(
                                builder: (context) => new NearStopWebView(stop)));
                      },
                    );
                  },
                ))),
    );
  }
}

class NearStopRow extends StatelessWidget {
  final NearStop stop;
  NearStopRow(this.stop);
  Widget build(BuildContext context) {
    return new Column(
      children: <Widget>[
        new Container(
          padding: new EdgeInsets.all(14.0),
          child: new Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              new Flexible(
                child: new Column(
                  children: <Widget>[
                    new Text(
                      stop.name,
                      style: new TextStyle(
                          fontSize: 18.0, fontWeight: FontWeight.normal),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
        new Divider(
          height: 1.0,
        )
      ],
    );
  }
}
