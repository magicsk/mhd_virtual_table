import 'package:flutter/material.dart';
import 'package:diacritic/diacritic.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';

import 'widgets/webview.dart';
import 'widgets/stopList.dart';

class AllStopsPage extends StatefulWidget {
  @override
  _AllStopsState createState() => _AllStopsState();
}

class _AllStopsState extends State<AllStopsPage> {
  List<Stop> stops = List<Stop>();
  List<Stop> saved = List<Stop>();
  List<Stop> _stopsForDisplay = List<Stop>();
  List<Stop> _savedForDisplay = List<Stop>();
  File stopsFile;
  File savedFile;
  Directory dir;
  String stopsFileName = 'stops.json';
  String savedFileName = 'saved.json';
  bool stopsExists = false;  
  bool savedExists = false;
  bool _isLoading = true;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = new TextEditingController();

  @override
  void initState() {
    setState(() {
      getApplicationDocumentsDirectory().then((Directory directory) {
        dir = directory;
        savedFile = new File(dir.path + '/' + savedFileName);
        savedExists = savedFile.existsSync();
        if (savedExists) { 
          print('saved.json exists');
          var _saved = List<Stop>();
          var savedFileJson = json.decode((savedFile.readAsStringSync()));
          for (var saveFileJson in savedFileJson) {
            _saved.add(Stop.fromJson(saveFileJson));
          }
          saved.addAll(_saved);
          print('saved loaded');
          saved.sort((a, b) {
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });
          setState(() {
            _savedForDisplay = saved;
          });
        }
        stopsFile = new File(dir.path + '/' + stopsFileName);
        stopsExists = stopsFile.existsSync();
        if (stopsExists) {
          print('stops.json exists');
          var _stops = List<Stop>();
          var stopsFileJson = json.decode((stopsFile.readAsStringSync()));
          for (var stopFileJson in stopsFileJson) {
            _stops.add(Stop.fromJson(stopFileJson));
          }
          stops.addAll(_stops);
          int i, s;
          for(s = 0;s <saved.length; s ++){
            for (i = 0;i < stops.length; i++){
              if (saved[s].name == stops[i].name){
                stops.remove(stops[i]);
              }
            }
          }
          print('stops cleared');
          stops.sort((a, b) {
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });
          print('stops sorted');
          setState(() {
            _stopsForDisplay = stops;
            _isLoading = false;
          });
        }
      });
    });
    super.initState();
  }

  File createFile(){
    File file = new File(dir.path + "/" + savedFileName);
    file.createSync();
    file.writeAsStringSync(json.encode(saved));
    print('saved');
    return file;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Stops'),
        backgroundColor: Color(0xFFe90007),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(70.0),
          child: _searchBar(),
        ),
      ),
      body: Center(
          child: _isLoading ? Scaffold() : DraggableScrollbar.semicircle(
                  controller: _scrollController,
                  child: ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.vertical,
                    itemCount: _savedForDisplay.length + _stopsForDisplay.length,
                    itemBuilder: (context, index) {
                      return index < _savedForDisplay.length ? _listSavedItem(index) :  _listItem(index);
                    },
                  ))),
    );
  }

  _searchBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0, left: 15.0, right: 15.0),
      child: TextField(
        decoration: InputDecoration(
            hintText: 'Search...',
            contentPadding: EdgeInsets.only(top: 8.0, bottom: 8.0, left: 16.0),
            hintStyle: TextStyle(color: Colors.white70),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white, width: 1.5)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white, width: 2.0)),
            suffixIcon: IconButton(
              icon: Icon(Icons.clear),
              color: Colors.white70,
              onPressed: () {
                var text = "";
                this.setState(() {
                  _textController.clear();
                  _stopsForDisplay = stops.where((stop) {
                    var stopName = removeDiacritics(stop.name).toLowerCase();
                    return stopName.contains(text);
                  }).toList();
                  _savedForDisplay = saved.where((stop) {
                    var stopName = removeDiacritics(stop.name).toLowerCase();
                    return stopName.contains(text);
                  }).toList();
                });
              },
            )
          ),
        autofocus: false,
        autocorrect: false,
        controller: _textController,
        cursorColor: Colors.white,
        maxLines: 1,
        style: TextStyle(
            fontSize: 20.0,
            color: Colors.white,
            decoration: TextDecoration.none),
        onChanged: (text) {
          text = removeDiacritics(text).toLowerCase();
          setState(() {
            _stopsForDisplay = stops.where((stop) {
              var stopName = removeDiacritics(stop.name).toLowerCase();
              return stopName.contains(text);
            }).toList();
            _savedForDisplay = saved.where((stop) {
              var stopName = removeDiacritics(stop.name).toLowerCase();
              return stopName.contains(text);
            }).toList();
          });
        },
      ),
    );
  }

  _listItem(index) {
    index = index - _savedForDisplay.length;
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
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Text(
                        _stopsForDisplay[index].name,
                        style: TextStyle(
                            fontSize: 17.5, fontWeight: FontWeight.normal),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      top: 4.0, bottom: 4.0, left: 0.0, right: 0.0),
                  child: IconButton(
                    icon: Icon(Icons.star_border),
                    color: null,
                    onPressed: () {
                      setState(() {
                          saved.add(stops[index]);
                          stops.remove(stops[index]);
                          saved.sort((a, b) {
                            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
                          });
                          createFile();
                      });
                    },
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
  _listSavedItem(index) {
    return FlatButton(
        onPressed: () {
          Navigator.push(
              context,
              new MaterialPageRoute(
                  builder: (context) =>
                      new StopWebView(_savedForDisplay[index])));
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
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Text(
                        _savedForDisplay[index].name,
                        style: TextStyle(
                            fontSize: 17.5, fontWeight: FontWeight.normal),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      top: 4.0, bottom: 4.0, left: 0.0, right: 0.0),
                  child: IconButton(
                    icon: Icon(Icons.star),
                    color: Colors.yellow[800],
                    onPressed: () {
                      setState(() {
                          stops.add(saved[index]);
                          saved.remove(saved[index]);
                          stops.sort((a, b) {
                            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
                          });
                          createFile();
                      });
                    },
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
