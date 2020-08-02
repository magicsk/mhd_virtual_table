import 'dart:convert';
import 'dart:developer';
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
import 'package:shared_preferences/shared_preferences.dart';

import 'widgets/favoritesList.dart';
// import 'locale/locales.dart';
import 'widgets/stopList.dart';

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}

class TripPlannerPage extends StatefulWidget {
  const TripPlannerPage({Key key}) : super(key: key);
  @override
  TripPlannerState createState() => TripPlannerState();
}

class TripPlannerState extends State<TripPlannerPage> {
  bool _isSearched = false;
  List<Stop> stops = List<Stop>();
  List<Trip> favoriteTrips = List<Trip>();
  List<Trip> recentTrip = List<Trip>();
  File stopsFile;
  File favoritesFile;
  File favoriteTripsFile;
  File recentTripFile;
  Directory dir;
  String stopsFileName = 'stops.json';
  String favoritesFileName = 'favorites.json';
  String favoriteTripsFileName = 'favoriteTrips.json';
  String recentTripFileName = 'recentTrip.json';
  String _fromHint = "From...";
  String arrivalDepartureText = '&departure_time=';
  String arrivalDepartureTime = DateTime.now().millisecondsSinceEpoch.toString().replaceAll(RegExp(r'\d(\d{0,2}$)'), '');
  bool arrivalDeparture = false;
  bool stopsExists = false;
  bool favoritesExists = false;
  bool favoriteTripsExists = false;
  bool recentTripExists = false;
  bool imhd = false;
  bool _typeError = false;
  bool _networkError = false;
  bool _searchError = false;
  bool _isSearching = false;
  bool _favoritesNotEmpty = false;
  bool _recentNotEmpty = false;
  bool _pickedTime = false;
  bool _used = false;
  var detail = false;

  List data;
  var currentLocation;

  Geolocator geolocator = Geolocator();
  final flutterWebviewPlugin = new FlutterWebviewPlugin();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fromTextController = new TextEditingController();
  final TextEditingController _toTextController = new TextEditingController();
  final ScrollController scrollController = ScrollController();

  Future<bool> _checkLocationStatus() async {
    return await PermissionHandler().checkServiceStatus(PermissionGroup.location).then((status) {
      if (status == ServiceStatus.enabled) {
        return true;
      } else {
        return false;
      }
    });
  }

  _getPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      imhd = prefs.getBool('imhd') == null ? false : prefs.getBool('imhd');
    });
  }

  _setPrefs(bool) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('imhd', bool);
  }

  // fetch stops on init
  void initState() {
    DotEnv().load('.env');
    _getPrefs();
    getApplicationDocumentsDirectory().then((Directory directory) {
      dir = directory;
      stopsFile = File(dir.path + '/' + stopsFileName);
      favoritesFile = File(dir.path + '/' + favoritesFileName);
      favoriteTripsFile = File(dir.path + '/' + favoriteTripsFileName);
      recentTripFile = File(dir.path + '/' + recentTripFileName);
      stopsExists = stopsFile.existsSync();
      favoritesExists = favoritesFile.existsSync();
      favoriteTripsExists = favoriteTripsFile.existsSync();
      recentTripExists = recentTripFile.existsSync();
      var _favorites = List<Stop>();
      if (favoritesExists) {
        print('favorites.json exists');
        var favoritesFileJson = json.decode((favoritesFile.readAsStringSync()));
        for (var favoriteFileJson in favoritesFileJson) {
          _favorites.add(Stop.fromJson(favoriteFileJson));
        }
        stops.addAll(_favorites);
        print('favorites loaded');
      }
      if (favoriteTripsExists) {
        var _favoriteTrips = List<Trip>();
        print('favoriteTrips.json exists');
        var favoriteTripsFileJson = json.decode(favoriteTripsFile.readAsStringSync());
        for (var favoriteTripFileJson in favoriteTripsFileJson) {
          _favoriteTrips.add(Trip.fromJson(favoriteTripFileJson));
        }
        favoriteTrips.addAll(_favoriteTrips);
        _favoritesNotEmpty = favoriteTrips.length > 0;
        print('favoriteTrips loaded');
      }
      if (recentTripExists) {
        var _recentTrip = List<Trip>();
        print('recentTrip.json exists');
        var recentTripFileJson = json.decode(recentTripFile.readAsStringSync());
        for (var recentTripFileJson in recentTripFileJson) {
          _recentTrip.add(Trip.fromJson(recentTripFileJson));
        }
        recentTrip.addAll(_recentTrip);
        _recentNotEmpty = recentTrip.length > 0;
        print('recentTrip loaded');
      }
      if (stopsExists) {
        var _stops = List<Stop>();
        var stopsFileJson = json.decode((stopsFile.readAsStringSync()));
        for (var stopFileJson in stopsFileJson) {
          _stops.add(Stop.fromJson(stopFileJson));
        }
        // _stops.sort((a, b) {
        //   return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        // });
        int i, s;
        for (s = 0; s < _favorites.length; s++) {
          for (i = 0; i < _stops.length; i++) {
            if (_favorites[s].name == _stops[i].name) {
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

  //save favorites in json
  File createFile(trip, tripFileName) {
    File file = File(dir.path + "/" + tripFileName);
    file.createSync();
    file.writeAsStringSync(json.encode(trip));
    print('saved');
    return file;
  }

  //Source decision
  getDirection() async {
    imhd ? await getDirectionIMHD() : await getDirectionGoogle();
  }

  //Get GMaps directions
  getDirectionGoogle() async {
    if (_toTextController.value.text != '' && _fromTextController.value.text != _toTextController.value.text) {
      setState(() {
        _typeError = false;
        _networkError = false;
        _searchError = false;
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
          arrivalDepartureText +
          arrivalDepartureTime +
          '&origin=' +
          _from +
          '&destination=' +
          _to +
          ',Bratislava&alternatives=true&region=sk&language=sk';
      print(jsonUrl);
      var response = await http.get(Uri.encodeFull(jsonUrl), headers: {"Accept": "application/json"});
      await isUsed();

      setState(() {
        // Get the JSON data
        if (response.statusCode == 200) {
          data = json.decode(response.body)['routes'];
          if (json.decode(response.body)['status'] != "OK") {
            _searchError = true;
            _isSearching = false;
          } else {
            _isSearched = true;
            _isSearching = false;
            addToRecent();
          }
        } else {
          _isSearching = false;
          _networkError = true;
        }
      });
    } else {
      setState(() {
        _isSearching = false;
        _typeError = true;
      });
    }
  }

  //Get imhd directions
  getDirectionIMHD() async {
    if (_toTextController.value.text != '' && _fromTextController.value.text != _toTextController.value.text) {
      setState(() {
        // c48.15,17.1078
        _typeError = false;
        _networkError = false;
        _isSearching = true;
      });

      String _from = _fromTextController.value.text.toString();
      String _to = _toTextController.value.text.toString();
      String _time = _pickedTime ? arrivalDepartureTime : DateTime.now().millisecondsSinceEpoch.toString().replaceAll(RegExp(r'\d(\d{0,2}$)'), '');

      if (currentLocation != null && _fromTextController.value.text == '') {
        _from = 'c' + currentLocation.latitude.toString() + "," + currentLocation.longitude.toString();
      } else if (currentLocation == null && _fromTextController.value.text == '') {
        var _loc = await geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
        setState(() {
          currentLocation = _loc;
        });
        _from = 'c' + currentLocation.latitude.toString() + "," + currentLocation.longitude.toString();
      }
      var jsonUrl = 'https://api.magicsk.eu/trip?time=' + _time + '000' + '&from=' + _from + '&to=' + _to;
      print(jsonUrl);
      var response = await http.get(Uri.encodeFull(jsonUrl), headers: {"Accept": "application/json"});
      await isUsed();

      setState(() {
        // Get the JSON data
        if (response.statusCode == 200) {
          data = json.decode(response.body)['routes'];
          if (json.decode(response.body)['status'] != "OK") {
            _searchError = true;
            _isSearching = false;
          } else {
            _isSearched = true;
            _isSearching = false;
            addToRecent();
          }
        } else {
          _isSearching = false;
          _networkError = true;
        }
      });
    } else {
      setState(() {
        _isSearching = false;
        _typeError = true;
      });
    }
  }

  // checking for stop in list
  isItStop(stop) {
    bool _found = false;
    for (int s = 0; s < stops.length; s++) {
      if (stop == stops[s].name) _found = true;
    }
    return _found;
  }

  //favoriteTrips

  isUsed() {
    String _from = _fromTextController.value.text.toString();
    String _to = _toTextController.value.text.toString();
    int _time = _pickedTime ? int.parse(arrivalDepartureTime) : 0;
    Trip _trip = Trip(_from, _to, _time);

    for (int _i = 0; _i < favoriteTrips.length; _i++) {
      if (favoriteTrips[_i].from == _trip.from && favoriteTrips[_i].to == _trip.to && favoriteTrips[_i].time == _trip.time) {
        setState(() {
          _used = true;
        });
        break;
      } else {
        setState(() {
          _used = false;
        });
      }
    }
    setState(() {
      return favoriteTrips.length == 0 ? _used = false : _used;
    });
  }

  favoriteTrip() {
    String _from = _fromTextController.value.text.toString();
    String _to = _toTextController.value.text.toString();
    int _time = _pickedTime ? int.parse(arrivalDepartureTime) : 0;
    Trip _trip = Trip(_from, _to, _time);

    if (!_used) {
      favoriteTrips.add(_trip);
      createFile(favoriteTrips, favoriteTripsFileName);
      isUsed();
    } else {
      for (int _i = 0; _i < favoriteTrips.length; _i++) {
        if (favoriteTrips[_i].from == _trip.from && favoriteTrips[_i].to == _trip.to && favoriteTrips[_i].time == _trip.time) {
          setState(() {
            favoriteTrips.remove(favoriteTrips[_i]);
            createFile(favoriteTrips, favoriteTripsFileName);
            isUsed();
          });
        }
      }
    }
  }

  addToRecent() {
    String _from = _fromTextController.value.text.toString();
    String _to = _toTextController.value.text.toString();
    int _time = int.parse(arrivalDepartureTime);
    Trip _trip = Trip(_from, _to, _time);

    recentTrip.clear();
    recentTrip.add(_trip);
    createFile(recentTrip, recentTripFileName);
  }

  // Time and Date picker
  DateFormat dateFormat = DateFormat("dd.MM.yyyy");
  DateFormat timeFormat = DateFormat("HH:mm");
  DateTime date = DateTime.now();
  TimeOfDay time = TimeOfDay.now();

  Future<Null> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(context: context, initialDate: date, firstDate: new DateTime(2020), lastDate: new DateTime(2025));

    if (picked != null && picked != date) {
      print('Date selected: ${date.toString()}');
      setState(() {
        date = picked;
        date = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        arrivalDepartureTime = date.millisecondsSinceEpoch.toString().replaceAll(RegExp(r'\d(\d{0,2}$)'), '');
      });
      getDirection();
    }
  }

  Future<Null> _selectTime(BuildContext context) async {
    final TimeOfDay picked = await showTimePicker(context: context, initialTime: time);

    if (picked != null && picked != time) {
      print('Time selected: ${time.toString()}');
      setState(() {
        time = picked;
        date = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        arrivalDepartureTime = date.millisecondsSinceEpoch.toString().replaceAll(RegExp(r'\d(\d{0,2}$)'), '');
        _pickedTime = true;
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
            icon: Icon(Icons.more_vert),
            onPressed: () {
              showMenu(
                context: context,
                position: RelativeRect.fromLTRB(20, 75, 0, 100),
                items: <PopupMenuEntry>[
                  PopupMenuItem(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.all(0),
                      title: Text('Alternative api'),
                      value: imhd,
                      onChanged: (bool) {
                        setState(() {
                          imhd = bool;
                        });
                        _setPrefs(bool);
                      },
                    ),
                  )
                ],
              );
            },
          )
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(186.0),
          child: _inputBar(),
        ),
      ),
      body: _isSearched || _isSearching
          ? _isSearching
              ? Center(child: CircularProgressIndicator())
              : _typeError || _networkError || _searchError
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            _searchError ? Icons.search_off : Icons.error,
                            size: 150.0,
                            color: Colors.grey[300],
                          ),
                          Text(_searchError ? 'No results found!' : 'Something went wrong!', style: TextStyle(color: Colors.grey[500]))
                        ],
                      ),
                    )
                  : _resultsListView(context)
          : _favoritesNotEmpty || _recentNotEmpty
              ? _favoritesListView(context)
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.search, size: 150.0, color: Colors.grey[300]),
                      Text("Plan your journey via public transport!", style: TextStyle(color: Colors.grey[500]))
                    ],
                  ),
                ),
    );
  }

  Widget _resultsListView(BuildContext context) {
    return Column(
      children: <Widget>[
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.only(left: 15.0, bottom: 0, top: 0),
            child: Row(
              children: <Widget>[
                Text('Add to Favorites'),
                IconButton(
                  icon: Icon(_used ? Icons.favorite : Icons.favorite_border),
                  onPressed: () => favoriteTrip(),
                  tooltip: 'save',
                )
              ],
            ),
          ),
        ),
        Flexible(
          child: ListView.builder(
            controller: scrollController,
            scrollDirection: Axis.vertical,
            itemCount: data.length + 1,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(top: 10.0, bottom: 0.0),
                child: index == data.length
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Theme.of(context).brightness == Brightness.dark
                            ? imhd
                                ? SizedBox.shrink() //TODO imhd logo
                                : Image(height: 15.0, image: AssetImage('assets/google/powered_by_google_on_non_white.png'))
                            : imhd
                                ? SizedBox.shrink() //TODO imhd logo
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
                                    Text(imhd ? data[index]["duration"] : data[index]["legs"][0]["duration"]["text"] + " ",
                                        style: TextStyle(
                                          fontSize: 18.0,
                                        )),
                                    Text(
                                      imhd
                                          ? "  (${data[index]["arrival_departure_time"]})"
                                          : "  (${data[index]["legs"][0]["departure_time"]["text"]}-${data[index]["legs"][0]["arrival_time"]["text"]})",
                                      style: TextStyle(fontSize: 12.0, height: 1.8),
                                    ),
                                  ],
                                )),
                            imhd
                                ? ListView.builder(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemCount: data[index]["steps"].length,
                                    itemBuilder: (context, stepIndex) {
                                      var step = data[index]["steps"][stepIndex];
                                      var travelMode = data[index]["steps"][stepIndex]["type"];
                                      if (travelMode == "TRANSIT") {
                                        return _transitDetail(step);
                                      } else if (travelMode == "WALKING") {
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
                                          title: Text(step["text"]),
                                        );
                                      } else {
                                        return SizedBox.shrink();
                                      }
                                    },
                                  )
                                : ListView.builder(
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
                                            details["html_instructions"]
                                                .contains(data[index]["legs"][0]["steps"][1]["transit_details"]["departure_stop"]["name"])) {
                                          return SizedBox.shrink();
                                        } else if (data[index]["legs"][0]["steps"].length == stepIndex + 1 && data[index]["legs"][0]["steps"].length != 1) {
                                          if (data[index]["legs"][0]["steps"][stepIndex - 1]["transit_details"]["arrival_stop"]["name"] ==
                                              _toTextController.text) {
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
          ),
        ),
      ],
    );
  }

  _transitDetail(details) {
    String color = details["line"]["color"];
    var rgbColor = color.split(',').map((n) {
      return n.replaceAll(RegExp(r"(\D+)"), '');
    }).toList();
    int r = imhd ? int.parse(rgbColor[0]) : 0;
    int g = imhd ? int.parse(rgbColor[1]) : 0;
    int b = imhd ? int.parse(rgbColor[2]) : 0;
    var _stops = details["stops"];
    String lineNumber = imhd ? details["line"]["number"] : details["line"]["short_name"];
    String departureTime = imhd ? details["departure_time"] : details["departure_time"]["text"];
    String departureStop = imhd ? details["departure_stop"] : details["departure_stop"]["name"];
    String arrivalTime = imhd ? details["arrival_time"] : details["arrival_time"]["text"];
    String arrivalStop = imhd ? details["arrival_stop"] : details["arrival_stop"]["name"];
    String headsign = imhd ? details["headsign"].toString().toLowerCase().capitalize() : details["headsign"];
    bool shortName = lineNumber != null;

    return ListTile(
      leading: Padding(
        padding: EdgeInsets.only(bottom: 0.0),
        child: Container(
          decoration: BoxDecoration(color: imhd ? Color.fromRGBO(r, g, b, 1.0) : HexColor(color), borderRadius: BorderRadius.all(Radius.circular(5))),
          width: 45.0,
          height: 30.0,
          child: Center(child: Text(shortName ? lineNumber : "Train", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0, color: Colors.white))),
        ),
      ),
      title: Container(
        child: Stack(
          children: <Widget>[
            Positioned(child: Text("   " + headsign)),
            Positioned(left: -10.0, top: -2.8, child: Icon(Icons.arrow_right)),
          ],
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('$departureTime    $departureStop'),
          Text('$arrivalTime    $arrivalStop'),
        ],
      ),
      // subtitle: ExpansionTile(
      //   title: Text('data'),
      //   children:
      //    <Widget>[
      //     ListView.builder(
      //       shrinkWrap: true,
      //       physics: NeverScrollableScrollPhysics(),
      //       itemCount: _stops.length,
      //       itemBuilder: (context, i) {
      //         String _stopsTime = _stops[i]["time"];
      //         String _stopsName = _stops[i]["stop"];
      //         return Text('$_stopsTime    $_stopsName');
      //       },
      //     ),
      //   ],
      // ),
    );
  }

  _stopsDetail(_stops, departureTime, departureStop, arrivalTime, arrivalStop) {
    int _count = 1;
    return InkWell(
      child: ListView.builder(
        addAutomaticKeepAlives: true,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: _count,
        itemBuilder: (context, i) {
          String _stopsTime = _stops[i]["time"];
          String _stopsName = _stops[i]["stop"];
          return Text('$_stopsTime    $_stopsName');
        },
      ),
      onTap: () {
        setState(() {
          log(_count.toString());
          _count = 20;
          log(_count.toString());
        });
      },
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
      title: (!isItStop(_toTextController.text))
          ? Text("Prejdite na zastávku ${_toTextController.text}. (${details["duration"]["text"]})", style: TextStyle(fontSize: 14))
          : Text(
              last
                  ? details["html_instructions"].toString()
                  : onlyOne
                      ? details["html_instructions"].toString()
                      : details["html_instructions"].toString().replaceAll('miesto', 'zastávku') + " (${details["duration"]["text"]})",
              style: TextStyle(fontSize: 14)),
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
                                arrivalDeparture = false;
                                arrivalDepartureText = '&departure_time=';
                                getDirection();
                              });
                            },
                            child: Row(
                              children: <Widget>[
                                Radio(
                                  onChanged: null,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  value: false,
                                  groupValue: arrivalDeparture,
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
                                arrivalDeparture = true;
                                arrivalDepartureText = '&arrival_time=';
                                getDirection();
                              });
                            },
                            child: Row(
                              children: <Widget>[
                                Radio(
                                  onChanged: null,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  value: true,
                                  groupValue: arrivalDeparture,
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
                        dateFormat.format(date),
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
                        timeFormat.format(date),
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

  Widget _favoritesListView(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 15.0, bottom: 10.0),
          child: Text(
            'Favorites',
            style: TextStyle(fontSize: 20.0),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
          child: Card(
            margin: EdgeInsets.all(3.0),
            child: InkWell(
              onTapDown: _storePosition,
              onLongPress: () {
                final RenderBox overlay = Overlay.of(context).context.findRenderObject();
                showMenu(
                  items: <PopupMenuEntry>[
                    PopupMenuItem(
                        child: ListTile(
                      onTap: () {
                        log('removed');
                        setState(() {
                          _recentNotEmpty = false;
                          recentTrip.remove(recentTrip[0]);
                          Navigator.pop(context);
                        });
                        createFile(recentTrip, recentTripFileName);
                      },
                      contentPadding: EdgeInsets.all(0),
                      title: Icon(Icons.delete),
                      trailing: Text('Delete'),
                    )),
                  ],
                  context: context,
                  position: RelativeRect.fromRect(_tapPosition & Size(40, 40), Offset.zero & overlay.size),
                );
              },
              onTap: () {
                _fromTextController.text = recentTrip[0].from;
                _toTextController.text = recentTrip[0].to;
                time = recentTrip[0].time == 0
                    ? TimeOfDay.now()
                    : TimeOfDay.fromDateTime(DateTime.fromMillisecondsSinceEpoch(int.parse(recentTrip[0].time.toString() + '000')));
                date = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                arrivalDepartureTime =
                    recentTrip[0].time == 0 ? date.millisecondsSinceEpoch.toString().replaceAll(RegExp(r'\d(\d{0,2}$)'), '') : recentTrip[0].time.toString();
                _pickedTime = recentTrip[0].time != 0;
                getDirection();
              },
              child: Padding(
                padding: EdgeInsets.only(left: 15.0, bottom: 15.0, top: 20.0, right: 20.0),
                child: Flex(
                  direction: Axis.horizontal,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Icon(Icons.access_time),
                    Padding(padding: EdgeInsets.all(7.5)),
                    Container(
                      constraints: BoxConstraints(maxWidth: 180.0),
                      child: Text(
                        recentTrip[0].from != "" ? recentTrip[0].from : 'Actual position',
                        overflow: TextOverflow.clip,
                      ),
                    ),
                    Text('  >  '),
                    Expanded(
                      child: Text(
                        recentTrip[0].to,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(recentTrip[0].time == 0
                        ? TimeOfDay.now().format(context)
                        : TimeOfDay.fromDateTime(DateTime.fromMillisecondsSinceEpoch(int.parse(recentTrip[0].time.toString() + '000')))
                            .format(context)), // can be NOW
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            scrollDirection: Axis.vertical,
            itemCount: favoriteTrips.length,
            itemBuilder: (context, index) {
              String _from = favoriteTrips[index].from != "" ? favoriteTrips[index].from : 'Actual position';
              String _to = favoriteTrips[index].to;
              String _time = favoriteTrips[index].time == 0
                  ? TimeOfDay.now().format(context)
                  : TimeOfDay.fromDateTime(DateTime.fromMillisecondsSinceEpoch(int.parse(favoriteTrips[index].time.toString().toString() + '000')))
                      .format(context); // can be NOW
              return Padding(
                padding: EdgeInsets.only(top: 5.0, bottom: 5.0),
                child: Card(
                  margin: EdgeInsets.all(3.0),
                  child: InkWell(
                    onTapDown: _storePosition,
                    onLongPress: () {
                      final RenderBox overlay = Overlay.of(context).context.findRenderObject();
                      showMenu(
                        items: <PopupMenuEntry>[
                          PopupMenuItem(
                            child: InkWell(
                              radius: 10,
                              onTap: () {
                                log('removed');
                                setState(() {
                                  favoriteTrips.remove(favoriteTrips[index]);
                                });
                                createFile(favoriteTrips, favoriteTripsFileName);
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
                                child: Row(
                                  children: <Widget>[
                                    Icon(Icons.delete),
                                    Text("Delete"),
                                  ],
                                ),
                              ),
                            ),
                          )
                        ],
                        context: context,
                        position: RelativeRect.fromRect(_tapPosition & Size(40, 40), Offset.zero & overlay.size),
                      );
                    },
                    onTap: () {
                      _fromTextController.text = favoriteTrips[index].from;
                      _toTextController.text = favoriteTrips[index].to;
                      time = favoriteTrips[index].time == 0
                          ? TimeOfDay.now()
                          : TimeOfDay.fromDateTime(DateTime.fromMillisecondsSinceEpoch(int.parse(favoriteTrips[index].time.toString() + '000')));
                      date = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                      arrivalDepartureTime = favoriteTrips[index].time == 0
                          ? date.millisecondsSinceEpoch.toString().replaceAll(RegExp(r'\d(\d{0,2}$)'), '')
                          : favoriteTrips[index].time.toString();
                      _pickedTime = favoriteTrips[index].time != 0;
                      getDirection();
                    },
                    child: Padding(
                      padding: EdgeInsets.only(left: 15.0, bottom: 15.0, top: 20.0, right: 20.0),
                      child: Flex(
                        direction: Axis.horizontal,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Icon(Icons.favorite),
                          Padding(padding: EdgeInsets.all(7.5)),
                          Container(
                            constraints: BoxConstraints(maxWidth: 180.0),
                            child: Text(
                              _from,
                              overflow: TextOverflow.clip,
                            ),
                          ),
                          Text('  >  '),
                          Expanded(
                            child: Text(
                              _to,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _time,
                            textAlign: TextAlign.left,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  var _tapPosition;
  void _storePosition(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }
}
