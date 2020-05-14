import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:native_color/native_color.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:persist_theme/data/models/theme_model.dart';

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
  String _fromHint = "From...";
  String arrivalDeparatureText = '&departure_time=';
  String arrivalDeparatureTime = DateTime.now().millisecondsSinceEpoch.toString().replaceAll(RegExp(r'\d(\d{0,2}$)'), '');
  bool arrivalDeparature = false;
  bool stopsExists = false;
  bool savedExists = false;
  bool _typeError = false;
  bool _networkError = false;
  bool _isSearching = false;
  List data;
  var currentLocation;

  Geolocator geolocator = Geolocator();
  final flutterWebviewPlugin = new FlutterWebviewPlugin();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fromTextController = new TextEditingController();
  final TextEditingController _toTextController = new TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Future<bool> _checkLocationStatus() async {
    return await PermissionHandler().checkServiceStatus(PermissionGroup.location).then((status) {
      if (status == ServiceStatus.enabled) {
        return true;
      } else {
        return false;
      }
    });
  }

  // fetch stops on init
  void initState() {
    DotEnv().load('.env');
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
    _checkLocationStatus().then((status) => {
          if (status)
            {
              geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best).then((loc) => {
                    setState(() {
                      currentLocation = loc;
                      _fromHint = "Actual position";
                    })
                  })
            }
        });
    super.initState();
  }

  //Get GMaps directions
  getDirection() async {
    if (_toTextController.value.text != '' && _fromTextController.value.text != _toTextController.value.text) {
      setState(() {
        _typeError = false;
        _networkError = false;
        _isSearching = true;
      });

      String _from = _fromTextController.value.text.toString() + ',Bratislava';
      String _to = _toTextController.value.text.toString();

      if (currentLocation != null && _fromTextController.value.text == '') {
        _from = currentLocation.latitude.toString() + "," + currentLocation.longitude.toString();
      }
      var jsonUrl = 'https://maps.googleapis.com/maps/api/directions/json?key=' + 
          DotEnv().env['API_KEY'] +
          '&mode=transit' +
          arrivalDeparatureText +
          arrivalDeparatureTime +
          '&origin=' +
          _from +
          '&destination=' +
          _to +
          ',Bratislava&alternatives=true&region=sk&language=sk';
      print(jsonUrl);
      var response = await http.get(Uri.encodeFull(jsonUrl), headers: {"Accept": "application/json"});

      setState(() {
        // Get the JSON data
        if (response.statusCode == 200) {
          data = json.decode(response.body)['routes'];
          _isSearched = true;
          _isSearching = false;
        } else {
          setState(() {
            _isSearching = false;
            _networkError = true;
          });
        }
      });
    } else {
      setState(() {
        _isSearching = false;
        _typeError = true;
      });
    }
  }

  // chcking for stop in list
  isItStop(stop) {
    bool _found = false;
    for (int s = 0; s < stops.length; s++) {
      if (stop == stops[s].name) _found = true;
    }
    return _found;
  }

  // Time and Date picker
  DateFormat dateFormat = DateFormat("dd.MM.yyyy");
  DateFormat timeFormat = DateFormat("HH:mm");
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();

  Future<Null> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(context: context, initialDate: _date, firstDate: new DateTime(2019), lastDate: new DateTime(2025));

    if (picked != null && picked != _date) {
      print('Date selected: ${_date.toString()}');
      setState(() {
        _date = picked;
        _date = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
        arrivalDeparatureTime = _date.millisecondsSinceEpoch.toString().replaceAll(RegExp(r'\d(\d{0,2}$)'), '');
      });
      getDirection();
    }
  }

  Future<Null> _selectTime(BuildContext context) async {
    final TimeOfDay picked = await showTimePicker(context: context, initialTime: _time);

    if (picked != null && picked != _time) {
      print('Time selected: ${_time.toString()}');
      setState(() {
        _time = picked;
        _date = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
        arrivalDeparatureTime = _date.millisecondsSinceEpoch.toString().replaceAll(RegExp(r'\d(\d{0,2}$)'), '');
        getDirection();
      });
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Trip planner'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings),
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
          preferredSize: Size.fromHeight(186.0),
          child: _inputBar(),
        ),
      ),
      body: _isSearched
          ? _isSearching
              ? Center(child: CircularProgressIndicator())
              : _typeError || _networkError
                  ? Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            Icons.error,
                            size: 150.0,
                            color: Colors.grey[300],
                          ),
                          Text('Something went wrong!', style: TextStyle(color: Colors.grey[500]))
                        ],
                      ),
                  )
                  : _myListView(context)
          : Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.search, size: 150.0, color: Colors.grey[300]),
                  Text("Plan your journy via public transport!", style: TextStyle(color: Colors.grey[500]))
                ],
              ),
          ),
    );
  }

  Widget _myListView(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      scrollDirection: Axis.vertical,
      itemCount: data.length + 1,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(top: 10.0, bottom: 0.0),
          child: index == data.length
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Theme.of(context).brightness == Brightness.dark
                      ? Image(height: 15.0, image: AssetImage('assets/google/powered_by_google_on_non_white.png'))
                      : Image(height: 15.0, image: AssetImage('assets/google/powered_by_google_on_white.png')),
                )
              : Card(
                  child: Column(
                    children: <Widget>[
                      Padding(
                          padding: EdgeInsets.only(left: 15.0, bottom: 10.0, top: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              Text(data[index]["legs"][0]["duration"]["text"] + " ",
                                  style: TextStyle(
                                    fontSize: 18,
                                  )),
                              data[index]["legs"][0]["departure_time"] == null
                                  ? Text("")
                                  : Text(
                                      "( ${data[index]["legs"][0]["departure_time"]["text"]}-${data[index]["legs"][0]["arrival_time"]["text"]})",
                                      style: TextStyle(fontSize: 13),
                                    ),
                            ],
                          )),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: data[index]["legs"][0]["steps"].length,
                        itemBuilder: (context, stepIndex) {
                          var details = data[index]["legs"][0]["steps"][stepIndex];
                          var transitDetails = data[index]["legs"][0]["steps"][stepIndex]["transit_details"];
                          var travelMode = data[index]["legs"][0]["steps"][stepIndex]["travel_mode"];
                          if (travelMode == "TRANSIT") {
                            return _transitDetail(transitDetails);
                          } else if (travelMode == "WALKING") {
                            if (_fromTextController.text != '' &&
                                details["html_instructions"].contains(data[index]["legs"][0]["steps"][1]["transit_details"]["departure_stop"]["name"])) {
                              return SizedBox.shrink();
                            } else if (data[index]["legs"][0]["steps"].length == stepIndex + 1 && data[index]["legs"][0]["steps"].length != 1) {
                              if (data[index]["legs"][0]["steps"][stepIndex - 1]["transit_details"]["arrival_stop"]["name"] == _toTextController.text) {
                                return SizedBox.shrink();
                              } else {
                                return _walkingDetails(details, true, index);
                              }
                            } else {
                              return _walkingDetails(details, false, index);
                            }
                          } else {
                            return SizedBox.shrink();
                          }
                        },
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  _transitDetail(details) {
    bool sortname = details["line"]["short_name"] != null;
    String color = details["line"]["color"];
    return ListTile(
      leading: Padding(
        padding: EdgeInsets.only(bottom: 0.0),
        child: Container(
          decoration: BoxDecoration(color: HexColor(color), borderRadius: BorderRadius.all(Radius.circular(5))),
          width: 45.0,
          height: 30.0,
          child: Center(
              child:
                  Text(sortname ? details["line"]["short_name"] : "Train", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0, color: Colors.white))),
        ),
      ),
      title: Container(
        child: Stack(
          children: <Widget>[
            Positioned(child: Text("   " + details["headsign"])),
            Positioned(left: -10.0, top: -2.8, child: Icon(Icons.arrow_right)),
          ],
        ),
      ),
      subtitle: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(details["departure_time"]["text"] + " " + details["departure_stop"]["name"]),
          Text(details["arrival_time"]["text"] + " " + details["arrival_stop"]["name"]),
          Padding(
            padding: EdgeInsets.all(5.0),
          )
        ],
      ),
    );
  }

  _walkingDetails(details, last, index) {
    bool onlyOne = data[index]["legs"][0]["steps"].length == 1;
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
        child: (isItStop(_toTextController.text))
            ? Text("Prejdite na zastávku ${_toTextController.text}. (${details["duration"]["text"]})", style: TextStyle(fontSize: 14))
            : Text(
                last
                    ? details["html_instructions"].toString()
                    : onlyOne
                        ? details["html_instructions"].toString()
                        : details["html_instructions"].toString().replaceAll('miesto', 'zastávku') + " (${details["duration"]["text"]})",
                style: TextStyle(fontSize: 14)),
      ),
    );
  }

  _inputBar() {
    return Padding(
        padding: const EdgeInsets.only(bottom: 5.0, left: 15.0, right: 15.0, top: 0.0),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Flexible(
                  child: TypeAheadFormField(
                    textFieldConfiguration: TextFieldConfiguration(
                      decoration: InputDecoration(
                        hintText: _fromHint,
                        contentPadding: EdgeInsets.only(top: 15.0, bottom: 0.0, left: 16.0),
                        hintStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white, width: 1.5)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white, width: 2.0)),
                        suffixIcon: IconButton(
                          padding: EdgeInsets.only(top: 10.0),
                          icon: Icon(Icons.clear),
                          color: Colors.white70,
                          onPressed: () {
                            this.setState(() => {WidgetsBinding.instance.addPostFrameCallback((_) => _fromTextController.clear())});
                          },
                        ),
                      ),
                      controller: this._fromTextController,
                      autofocus: false,
                      autocorrect: false,
                      cursorColor: Colors.white,
                      maxLines: 1,
                      style: TextStyle(fontSize: 20.0, color: Colors.white, decoration: TextDecoration.none),
                    ),
                    suggestionsCallback: (pattern) {
                      List<String> matches = List();
                      for (var i = 0; i < stops.length; i++) {
                        matches.add(stops[i].name);
                      }
                      matches.retainWhere((s) => removeDiacritics(s.toLowerCase()).contains(removeDiacritics(pattern.toLowerCase())));
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
                  contentPadding: EdgeInsets.only(top: 15.0, bottom: 0.0, left: 16.0),
                  hintStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white, width: 1.5)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white, width: 2.0)),
                  suffixIcon: IconButton(
                    padding: EdgeInsets.only(top: 10.0),
                    icon: Icon(Icons.clear),
                    color: Colors.white70,
                    onPressed: () {
                      this.setState(() => {WidgetsBinding.instance.addPostFrameCallback((_) => _toTextController.clear())});
                    },
                  ),
                ),
                autofocus: false,
                autocorrect: false,
                controller: this._toTextController,
                focusNode: _focusNode,
                cursorColor: Colors.white,
                maxLines: 1,
                style: TextStyle(fontSize: 20.0, color: Colors.white, decoration: TextDecoration.none),
                onSubmitted: (text) {
                  getDirection();
                },
              ),
              suggestionsCallback: (pattern) {
                List<String> matches = List();
                for (var i = 0; i < stops.length; i++) {
                  matches.add(stops[i].name);
                }
                matches.retainWhere((s) => removeDiacritics(s.toLowerCase()).contains(removeDiacritics(pattern.toLowerCase())));
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
                      child: Column(
                        children: <Widget>[
                          FlatButton(
                            padding: EdgeInsets.all(0),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  value: false,
                                  groupValue: arrivalDeparature,
                                  activeColor: Colors.white,
                                  inactiveColor: Colors.white,
                                ),
                                Padding(padding: EdgeInsets.only(right: 10.0)),
                                Text('Departure', style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                          FlatButton(
                            padding: EdgeInsets.all(0),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  value: true,
                                  groupValue: arrivalDeparature,
                                  activeColor: Colors.white,
                                  inactiveColor: Colors.white,
                                ),
                                Padding(padding: EdgeInsets.only(right: 10.0)),
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
                      padding: EdgeInsets.only(left: 8.0, right: 8.0),
                      child: Text(
                        dateFormat.format(_date),
                        style: TextStyle(fontSize: 20.0, color: Colors.white, fontWeight: FontWeight.normal),
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
                      padding: EdgeInsets.only(left: 0.0, right: 0.0),
                      child: Text(
                        timeFormat.format(_date),
                        style: TextStyle(fontSize: 20.0, color: Colors.white, fontWeight: FontWeight.normal),
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
