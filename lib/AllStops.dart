import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AllStopsPage extends StatefulWidget {
  @override
  _AllStopsState createState() => _AllStopsState();
}

class Stop {
  final String name;
  final String url;
  Stop(this.name, this.url);
}

class _AllStopsState extends State<AllStopsPage> {
  final stops = new List<Stop>();
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStops();
  }

  _fetchStops() async {
    final urlString = 'https://api.magicsk.eu/stops';
    print("Fetching: " + urlString);
    final response = await http.get(urlString);
    final stopsJson = json.decode(utf8.decode(response.bodyBytes));
    stopsJson.forEach((stopJson) {
      final stop = new Stop(stopJson["name"], stopJson["url"]);
      stops.add(stop);
    });
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
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
                      child: StopRow(stop),
                      onPressed: () {
                        Navigator.push(
                            context,
                            new MaterialPageRoute(
                                builder: (context) => new StopWebView(stop)));
                      },
                    );
                  },
                ))),
    );
  }
}

class StopWebView extends StatelessWidget {
  final Stop stop;
  StopWebView(this.stop);
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0.0),
        child: AppBar(),
      ),
      body: WebView(initialUrl: stop.url,javascriptMode: JavascriptMode.unrestricted),
    );
  }
}

class StopRow extends StatelessWidget {
  final Stop stop;
  StopRow(this.stop);
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
