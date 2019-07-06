import 'package:flutter/material.dart';
import 'package:diacritic/diacritic.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'widgets/webview.dart';

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
      appBar:AppBar(
            title: Center(child: Text('Stops'),),
            backgroundColor: Color(0xFFe90007),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(60.0),
              child: _searchBar(),
           ),
          ),
      body: Center(
          child: _isLoading
              ? CircularProgressIndicator()
              : Scrollbar(
                  child: ListView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: _stopsForDisplay.length,
                  itemBuilder: (context, index) {
                    return _listItem(index);
                  },
                ))),
    );
  }

  _searchBar() {
    return
        Padding(
          padding: const EdgeInsets.only(bottom: 20.0,left: 15.0,right: 15.0),
          child: TextField(
            decoration: InputDecoration(
                hintText: 'Search...',
                contentPadding:
                    EdgeInsets.only(top: 8.0, bottom: 8.0, left: 16.0),
                hintStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white, width: 2.0)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white, width: 2.5))),
            autofocus: false,
            cursorColor: Colors.white,
            maxLines: 1,
            style: TextStyle(fontSize: 20.0, color: Colors.white),
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
    return FlatButton(
        onPressed: () {
          Navigator.push(
              context,
              new MaterialPageRoute(
                  builder: (context) =>
                      new StopWebView(_stopsForDisplay[index])));
        },
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 4.0, bottom: 4.0, left: 12.0, right: 16.0),
                      child: Text(
                        _stopsForDisplay[index].name,
                        style: TextStyle(
                            fontSize: 18.0, fontWeight: FontWeight.normal),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      top: 4.0, bottom: 4.0, left: 16.0, right: 0.0),
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
        ));
  }
}
