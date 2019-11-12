import 'dart:convert';
import 'dart:io';

import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
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
  bool _isLoading = true;
  bool _isPageLoading = false;
  List<Stop> stops = List<Stop>();
  File stopsFile;
  Directory dir;
  String stopsFileName = 'stops.json';
  String _selectedFromStop;
  String _selectedToStop;
  bool stopsExists = false;
  List data;

  final flutterWebviewPlugin = new FlutterWebviewPlugin();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fromTextController = new TextEditingController();
  final TextEditingController _toTextController = new TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void initState() {
    getApplicationDocumentsDirectory().then((Directory directory) {
      dir = directory;
      stopsFile = new File(dir.path + '/' + stopsFileName);
      stopsExists = stopsFile.existsSync();
      if (stopsExists) {
        var _stops = List<Stop>();
        var stopsFileJson = json.decode((stopsFile.readAsStringSync()));
        for (var stopFileJson in stopsFileJson) {
          _stops.add(Stop.fromJson(stopFileJson));
        }
        stops.addAll(_stops);
        stops.sort((a, b) {
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      }
    });
    // flutterWebviewPlugin.onProgressChanged.listen((double progress) {
    //   if (progress == 1.0) {
    //     setState(() {
    //       _isPageLoading = false;
    //     });
    //   }
    // });
    super.initState();
  }

  Future<String> getDirection() async {
    var jsonUrl =
        'https://maps.googleapis.com/maps/api/directions/json?key=API_KEY&mode=transit&origin=' +
            _fromTextController.value.text.toString() +
            ',Bratislava&destination=' +
            _toTextController.value.text.toString() +
            ',Bratislava&alternatives=true&region=sk&language=sk';
    print(jsonUrl);
    var response = await http
        .get(Uri.encodeFull(jsonUrl), headers: {"Accept": "application/json"});

    setState(() {
      // Get the JSON data
      if (response.statusCode == 200) {
        data = json.decode(response.body)['routes'];
        _isLoading = false;
      }
      // print(data[0]["legs"][0]["steps"][1]);
      // print(data.length);
    });

    return "Successful";
  }

  _plan() {
    for (var i = 0; i < stops.length; i++) {
      if (_fromTextController.text.toString() == stops[i].name) {
        for (var i = 0; i < stops.length; i++) {
          if (_toTextController.text.toString() == stops[i].name) {
            this.setState(() {
              var tempUrl = 'https://api.magicsk.eu/planner?from=' +
                  _fromTextController.text.toString() +
                  '&to=' +
                  _toTextController.text.toString();
              setState(() {
                _isPageLoading = true;
                url = tempUrl;
                print(url);
                flutterWebviewPlugin.reloadUrl(url);
                // _loaded();
              });
            });
          } else {
            // TODO alert
          }
        }
      } else {
        // TODO alert
      }
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
          preferredSize: Size.fromHeight(118.0),
          child: _inputBar(),
        ),
      ),
      body: _isLoading ? Container() : _myListView(context),
    );
  }

  Widget _myListView(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      scrollDirection: Axis.vertical,
      itemCount: data.length,
      itemBuilder: (context, index) {
        return Padding(padding: EdgeInsets.only(top: 10.0, bottom: 0.0), child:Card(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(left: 15.0, bottom: 10.0),
              child: Text(
                data[index]["legs"][0]["departure_time"]["text"] +
                    "-" +
                    data[index]["legs"][0]["arrival_time"]["text"] +
                    " (" +
                    data[index]["legs"][0]["duration"]["text"] +
                    ")",
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
            ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: data[index]["legs"][0]["steps"].length,
                itemBuilder: (context, stepIndex) {
                  var details = data[index]["legs"][0]["steps"][stepIndex]
                      ["transit_details"];
                  // print(sortname);
                  if (data[index]["legs"][0]["steps"][stepIndex]
                          ["travel_mode"] ==
                      "TRANSIT") {
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
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0, color: Colors.white))),
                        ),
                      ),
                      title: Container(
                        child: Stack(
                          children: <Widget>[
                            Positioned( child:Text("   " + details["headsign"])),
                            Positioned(left: -10.0, top: -2.8, child:Icon(Icons.arrow_right)),
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
                          Padding(padding: EdgeInsets.all(5.0),)
                        ],
                      ),
                    );
                  } else {
                    return SizedBox.shrink();
                  }
                }),
          ],
        )));
        // return ListTile(
        //   leading: Text(data[index]["legs"][0]["steps"][1]["transit_details"]["line"]["short_name"]),
        //   title: Text(data[index]['legs'][0]['steps'][1]["transit_details"]["headsign"]),
        //   title: Text(data[index]['legs'][0]['steps'][0]["html_instructions"]),
        //   subtitle: Text(data[index]['legs'][0]['steps'][1]["transit_details"]["departure_time"]["text"]),
        // );
      },
    );
  }

  _inputBar() {
    return Padding(
        padding: const EdgeInsets.only(
            bottom: 20.0, left: 15.0, right: 15.0, top: 0.0),
        child: Column(
          children: <Widget>[
            TypeAheadFormField(
              textFieldConfiguration: TextFieldConfiguration(
                decoration: InputDecoration(
                  hintText: 'From...',
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
                this._fromTextController.text = suggestion;
                FocusScope.of(context).requestFocus(_focusNode);
              },
              onSaved: (value) => this._selectedFromStop = value,
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
                  _plan();
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
          ],
        ));
  }
}
