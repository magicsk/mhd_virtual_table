import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:diacritic/diacritic.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AllStopsPage extends StatefulWidget {
  @override
  _AllStopsState createState() => _AllStopsState();
}

class Stop {
  String name;
  String url;

  Stop(this.name, this.url);

  Stop.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    url = json['url'];
  }
}

class _AllStopsState extends State<AllStopsPage> {
  List<Stop> _stops = List<Stop>();
  List<Stop> _stopsForDisplay = List<Stop>();
  var _isLoading = true;

  Future<List<Stop>> fetchStops() async {
    var url = 'https://api.magicsk.eu/stops';
    var response = await http.get(url);

    var stops = List<Stop>();

    if (response.statusCode == 200) {
      var stopsJson = json.decode(utf8.decode(response.bodyBytes));
      for (var stopJson in stopsJson) {
        stops.add(Stop.fromJson(stopJson));
      }
    }
    return stops;
  }

  @override
  void initState() {
    fetchStops().then((value) {
      setState(() {
        _stops.addAll(value);
        _stopsForDisplay = _stops;
        _isLoading = false;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: _isLoading
              ? CircularProgressIndicator()
              : Scrollbar(
                  child: ListView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: _stopsForDisplay.length + 1,
                  itemBuilder: (context, index) {
                    return index == 0 ? _searchBar() : _listItem(index - 1);
                  },
                ))),
    );
  }

  _searchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: InputDecoration(hintText: 'Search...'),
        autofocus: true,
        maxLines: 1,
        style: TextStyle(fontSize: 18.0),
        onChanged: (text) {
          text = removeDiacritics(text).toLowerCase();
          setState(() {
            _stopsForDisplay = _stops.where((stop) {
              var stopName = removeDiacritics(stop.name).toLowerCase();
              return stopName.contains(text);
            }).toList();
          });
        },
      ),
    );
  }

  _listItem(index) {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                 padding: const EdgeInsets.only(top: 4.0, bottom: 4.0, left: 26.0, right: 16.0),
                  child: Text(
                    _stopsForDisplay[index].name,
                    style: TextStyle(
                        fontSize: 18.0, fontWeight: FontWeight.normal),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 4.0, left: 16.0, right: 12.0),
              child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.star_border,
                      size: 30.0,
                      color: Colors.grey,
                    ),
                  ),
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

class StopWebView extends StatelessWidget {
  final Stop stop;
  StopWebView(this.stop);
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0.0),
        child: AppBar(),
      ),
      body: WebView(
          initialUrl: stop.url, javascriptMode: JavascriptMode.unrestricted),
    );
  }
}
