import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:native_color/native_color.dart';

import 'main.dart';
import 'widgets/settings.dart';
// import 'locale/locales.dart';
import 'widgets/stopList.dart';

class TripPlannerPage extends StatefulWidget {
  @override
  _TripPlannerState createState() => _TripPlannerState();
}

class _TripPlannerState extends State<TripPlannerPage> {
  var url = 'https://google.com';
  bool _isSearched = false;
  List<Stop> stops = List<Stop>();
  File stopsFile;
  File savedFile;
  Directory dir;
  String stopsFileName = 'stops.json';
  String savedFileName = 'saved.json';
  String _selectedFromStop;
  String _selectedToStop;
  String arrivalDeparatureText = '&departure_time=';
  String arrivalDeparatureTime = DateTime.now()
      .millisecondsSinceEpoch
      .toString()
      .replaceAll(RegExp(r'\d(\d{0,2}$)'), '');
  bool arrivalDeparature = false;
  bool stopsExists = false;
  bool savedExists = false;
  List data;

  final flutterWebviewPlugin = new FlutterWebviewPlugin();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fromTextController = new TextEditingController();
  final TextEditingController _toTextController = new TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // fetch stops on init
  void initState() {
    getApplicationDocumentsDirectory().then((Directory directory) {
      dir = directory;
      stopsFile = new File(dir.path + '/' + stopsFileName);
      savedFile = new File(dir.path + '/' + savedFileName);
      stopsExists = stopsFile.existsSync();
      savedExists = savedFile.existsSync();
      var _saved = List<Stop>();
      if (savedExists) {
        print('saved.json exists');
        var savedFileJson = json.decode((savedFile.readAsStringSync()));
        for (var saveFileJson in savedFileJson) {
          _saved.add(Stop.fromJson(saveFileJson));
        }
        _saved.sort((a, b) {
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        stops.addAll(_saved);
        print('saved loaded');
      }
      if (stopsExists) {
        var _stops = List<Stop>();
        var stopsFileJson = json.decode((stopsFile.readAsStringSync()));
        for (var stopFileJson in stopsFileJson) {
          _stops.add(Stop.fromJson(stopFileJson));
        }
        _stops.sort((a, b) {
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        int i, s;
        for (s = 0; s < _saved.length; s++) {
          for (i = 0; i < _stops.length; i++) {
            if (_saved[s].name == _stops[i].name) {
              _stops.remove(_stops[i]);
            }
          }
        }
        print('stops cleared');
        stops.addAll(_stops);
      }
    });
    super.initState();
  }

  //Get GMaps directions
  Future<String> getDirection() async {
    if (_fromTextController.text != '' || _toTextController.text != '') {
      var jsonUrl =
          'https://maps.googleapis.com/maps/api/directions/json?key=AIzaSyCkGBN4ws8vyc8jlLtgFj5yTPUdDzPCeMY&mode=transit' +
              arrivalDeparatureText +
              arrivalDeparatureTime +
              '&origin=' +
              _fromTextController.value.text.toString() +
              ',Bratislava&destination=' +
              _toTextController.value.text.toString() +
              ',Bratislava&alternatives=true&region=sk&language=sk';
      print(jsonUrl);
      var response = await http.get(Uri.encodeFull(jsonUrl),
          headers: {"Accept": "application/json"});

      setState(() {
        // Get the JSON data
        if (response.statusCode == 200) {
          data = json.decode(response.body)['routes'];
          _isSearched = true;
          return "Successful";
        } else {
          return "Failed!";
        }
      });
    } else {
      return "Failed!";
    }
    return "Done!";
  }

  // Time and Date picker
  DateFormat dateFormat = DateFormat("dd.MM.yyyy");
  DateFormat timeFormat = DateFormat("HH:mm");
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();

  Future<Null> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
        context: context,
        initialDate: _date,
        firstDate: new DateTime(2019),
        lastDate: new DateTime(2025));

    if (picked != null && picked != _date) {
      print('Date selected: ${_date.toString()}');
      setState(() {
        _date = picked;
        _date = DateTime(
            _date.year, _date.month, _date.day, _time.hour, _time.minute);
        arrivalDeparatureTime = _date.millisecondsSinceEpoch
            .toString()
            .replaceAll(RegExp(r'\d(\d{0,2}$)'), '');
      });
      getDirection();
    }
  }

  Future<Null> _selectTime(BuildContext context) async {
    final TimeOfDay picked =
        await showTimePicker(context: context, initialTime: _time);

    if (picked != null && picked != _time) {
      print('Time selected: ${_time.toString()}');
      setState(() {
        _time = picked;
        _date = DateTime(
            _date.year, _date.month, _date.day, _time.hour, _time.minute);
        arrivalDeparatureTime = _date.millisecondsSinceEpoch
            .toString()
            .replaceAll(RegExp(r'\d(\d{0,2}$)'), '');
        getDirection();
      });
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Trip planner'),
        backgroundColor: primaryColor,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Settings(),
                ),
              );
            },
          )
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(188.0),
          child: _inputBar(),
        ),
      ),
      body: _isSearched
          ? _myListView(context)
          : Center(
              child: Column(
              children: <Widget>[
                Padding(padding: EdgeInsets.all(40.0),),
                Icon(Icons.search, size: 200.0, color: Colors.grey[300]),
                Text("Plan your journy via public transport!",
                    style: TextStyle(color: Colors.grey[500]))
              ],
            )),
    );
  }

  Widget _myListView(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      scrollDirection: Axis.vertical,
      itemCount: data.length,
      itemBuilder: (context, index) {
        return Padding(
            padding: EdgeInsets.only(top: 10.0, bottom: 0.0),
            child: Card(
                child: Column(
              children: <Widget>[
                Padding(
                    padding:
                        EdgeInsets.only(left: 15.0, bottom: 10.0, top: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(data[index]["legs"][0]["duration"]["text"] + " ",
                            style: TextStyle(
                              fontSize: 18,
                            )),
                        Text(
                          "(" +
                              data[index]["legs"][0]["departure_time"]["text"] +
                              "-" +
                              data[index]["legs"][0]["arrival_time"]["text"] +
                              ")",
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    )),
                ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: data[index]["legs"][0]["steps"].length - 1,
                    itemBuilder: (context, stepIndex) {
                      var details = data[index]["legs"][0]["steps"][stepIndex]
                          ["transit_details"];
                      var travelMode = data[index]["legs"][0]["steps"]
                          [stepIndex]["travel_mode"];
                      if (travelMode == "TRANSIT") {
                        bool sortname = details["line"]["short_name"] != null;
                        String color = details["line"]["color"];
                        return ListTile(
                          leading: Padding(
                            padding: EdgeInsets.only(bottom: 0.0),
                            child: Container(
                              decoration: BoxDecoration(
                                  color: HexColor(color),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5))),
                              width: 45.0,
                              height: 30.0,
                              child: Center(
                                  child: Text(
                                      sortname
                                          ? details["line"]["short_name"]
                                          : "Train",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16.0,
                                          color: Colors.white))),
                            ),
                          ),
                          title: Container(
                            child: Stack(
                              children: <Widget>[
                                Positioned(
                                    child: Text("   " + details["headsign"])),
                                Positioned(
                                    left: -10.0,
                                    top: -2.8,
                                    child: Icon(Icons.arrow_right)),
                              ],
                            ),
                          ),
                          subtitle: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(details["departure_time"]["text"] +
                                  " " +
                                  details["departure_stop"]["name"]),
                              Text(details["arrival_time"]["text"] +
                                  " " +
                                  details["arrival_stop"]["name"]),
                              Padding(
                                padding: EdgeInsets.all(5.0),
                              )
                            ],
                          ),
                        );
                      } else if (travelMode == "WALKING") {
                        var details =
                            data[index]["legs"][0]["steps"][stepIndex];
                        if (details["html_instructions"]
                                    .contains(_fromTextController.text) ==
                                false &&
                            details["html_instructions"]
                                    .contains(_toTextController.text) ==
                                false) {
                          return ListTile(
                            leading: Padding(
                              padding: EdgeInsets.only(bottom: 0.0),
                              child: Container(
                                  width: 45.0,
                                  height: 30.0,
                                  child: Icon(
                                    Icons.directions_walk,
                                    size: 35,
                                  )),
                            ),
                            title: Container(
                                child: Text(
                              details["html_instructions"]
                                      .toString()
                                      .replaceAll("miesto", "zastávku") +
                                  " (${details["duration"]["text"]})",
                              style: TextStyle(fontSize: 14),
                            )),
                          );
                        } else {
                          return SizedBox.shrink();
                        }
                      } else {
                        return SizedBox.shrink();
                      }
                    }),
              ],
            )));
      },
    );
  }

  _inputBar() {
    return Padding(
        padding: const EdgeInsets.only(
            bottom: 20.0, left: 15.0, right: 15.0, top: 0.0),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Flexible(
                  child: TypeAheadFormField(
                    textFieldConfiguration: TextFieldConfiguration(
                      decoration: InputDecoration(
                        hintText: 'From...',
                        contentPadding:
                            EdgeInsets.only(top: 15.0, bottom: 0.0, left: 16.0),
                        hintStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.white, width: 1.5)),
                        focusedBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.white, width: 2.0)),
                        suffixIcon: IconButton(
                          padding: EdgeInsets.only(top: 10.0),
                          icon: Icon(Icons.clear),
                          color: Colors.white70,
                          onPressed: () {
                            this.setState(() => {
                                  WidgetsBinding.instance.addPostFrameCallback(
                                      (_) => _fromTextController.clear())
                                });
                          },
                        ),
                      ),
                      controller: this._fromTextController,
                      autofocus: false,
                      autocorrect: false,
                      cursorColor: Colors.white,
                      maxLines: 1,
                      style: TextStyle(
                          fontSize: 20.0,
                          color: Colors.white,
                          decoration: TextDecoration.none),
                    ),
                    suggestionsCallback: (pattern) {
                      List<String> matches = List();
                      for (var i = 0; i < stops.length; i++) {
                        matches.add(stops[i].name);
                      }
                      matches.retainWhere((s) =>
                          removeDiacritics(s.toLowerCase()).contains(
                              removeDiacritics(pattern.toLowerCase())));
                      return matches;
                    },
                    itemBuilder: (context, suggestion) {
                      return ListTile(
                        title: Text(suggestion),
                      );
                    },
                    transitionBuilder: (context, suggestionsBox, controller) {
                      return suggestionsBox;
                    },
                    onSuggestionSelected: (suggestion) {
                      this._fromTextController.text = suggestion;
                      FocusScope.of(context).requestFocus(_focusNode);
                    },
                    onSaved: (value) => this._selectedFromStop = value,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.swap_vert,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      var _from = _fromTextController.text;
                      var _to = _toTextController.text;
                      _fromTextController.text = _to;
                      _toTextController.text = _from;
                    });
                  },
                )
              ],
            ),
            TypeAheadFormField(
              textFieldConfiguration: TextFieldConfiguration(
                decoration: InputDecoration(
                  hintText: 'To...',
                  contentPadding:
                      EdgeInsets.only(top: 15.0, bottom: 0.0, left: 16.0),
                  hintStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white, width: 1.5)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white, width: 2.0)),
                  suffixIcon: IconButton(
                    padding: EdgeInsets.only(top: 10.0),
                    icon: Icon(Icons.clear),
                    color: Colors.white70,
                    onPressed: () {
                      this.setState(() => {
                            WidgetsBinding.instance.addPostFrameCallback(
                                (_) => _toTextController.clear())
                          });
                    },
                  ),
                ),
                autofocus: false,
                autocorrect: false,
                controller: this._toTextController,
                focusNode: _focusNode,
                cursorColor: Colors.white,
                maxLines: 1,
                style: TextStyle(
                    fontSize: 20.0,
                    color: Colors.white,
                    decoration: TextDecoration.none),
                onSubmitted: (text) {
                  getDirection();
                },
              ),
              suggestionsCallback: (pattern) {
                List<String> matches = List();
                for (var i = 0; i < stops.length; i++) {
                  matches.add(stops[i].name);
                }
                matches.retainWhere((s) => removeDiacritics(s.toLowerCase())
                    .contains(removeDiacritics(pattern.toLowerCase())));
                return matches;
              },
              itemBuilder: (context, suggestion) {
                return ListTile(
                  title: Text(suggestion),
                );
              },
              transitionBuilder: (context, suggestionsBox, controller) {
                return suggestionsBox;
              },
              onSuggestionSelected: (suggestion) {
                this._toTextController.text = suggestion;
                getDirection();
              },
              onSaved: (value) => this._selectedToStop = value,
            ),
            Padding(
                padding: EdgeInsets.only(top: 5.0, bottom: 0.0, left: 0.0),
                child: Row(
                  children: <Widget>[
                    Flexible(
                      child: Row(
                        children: <Widget>[
                          FlatButton(
                            padding: EdgeInsets.all(0),
                            onPressed: () {
                              setState(() {
                                arrivalDeparature = false;
                                arrivalDeparatureText = '&departure_time=';
                                getDirection();
                              });
                            },
                            child: Row(
                              children: <Widget>[
                                Radio(
                                  onChanged: null,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  value: false,
                                  groupValue: arrivalDeparature,
                                  activeColor: Colors.white,
                                  inactiveColor: Colors.white,
                                ),
                                Text('Departure',
                                    style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                          FlatButton(
                            padding: EdgeInsets.all(0),
                            onPressed: () {
                              setState(() {
                                arrivalDeparature = true;
                                arrivalDeparatureText = '&arrival_time=';
                                getDirection();
                              });
                            },
                            child: Row(
                              children: <Widget>[
                                Radio(
                                  onChanged: null,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  value: true,
                                  groupValue: arrivalDeparature,
                                  activeColor: Colors.white,
                                  inactiveColor: Colors.white,
                                ),
                                Text(
                                  'Arrival',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    FlatButton(
                      padding: EdgeInsets.only(left: 16.0, right: 16.0),
                      child: Text(
                        dateFormat.format(_date),
                        style: TextStyle(
                            fontSize: 20.0,
                            color: Colors.white,
                            fontWeight: FontWeight.normal),
                      ),
                      onPressed: () => {_selectDate(context)},
                      shape: Border(
                        bottom: BorderSide(width: 1.5, color: Colors.white),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 15.0),
                    ),
                    FlatButton(
                      padding: EdgeInsets.only(left: 16.0, right: 16.0),
                      child: Text(
                        timeFormat.format(_date),
                        style: TextStyle(
                            fontSize: 20.0,
                            color: Colors.white,
                            fontWeight: FontWeight.normal),
                      ),
                      onPressed: () => {_selectTime(context)},
                      shape: Border(
                        bottom: BorderSide(width: 1.5, color: Colors.white),
                      ),
                    ),
                  ],
                ))
          ],
        ));
  }
}
