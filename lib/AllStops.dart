import 'package:flutter/material.dart';
import 'package:diacritic/diacritic.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity/connectivity.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import 'widgets/stopwebview.dart';
import 'widgets/stopList.dart';
import 'widgets/settings.dart';
import 'locale/locales.dart';

class AllStopsPage extends StatefulWidget {
  const AllStopsPage({Key key}) : super(key: key);
  @override
  _AllStopsState createState() => _AllStopsState();
}

class _AllStopsState extends State<AllStopsPage> {
  List<Stop> stops = [];
  List<Stop> saved = [];
  List<Stop> favorites = [];
  List<Stop> _stopsForDisplay = [];
  List<Stop> _favoritesForDisplay = [];
  File stopsFile;
  File savedFile;
  File favoritesFile;
  Directory dir;
  String stopsFileName = 'stops.json';
  String savedFileName = 'saved.json';
  String favoritesFileName = 'favorites.json';
  bool stopsExists = false;
  bool savedExists = false;
  bool favoritesExists = false;
  bool _isLoading = true;
  bool _networkStatus = false;

  final ScrollController scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  Future<List<Stop>> fetchStops() async {
    var url = 'https://api.magicsk.eu/stops';
    var response = await http.get(url);

    List<Stop> _stops = [];
    print("Fetching: " + url);
    if (response.statusCode == 200) {
      var stopsJson = json.decode(utf8.decode(response.bodyBytes));
      for (var stopJson in stopsJson) {
        _stops.add(Stop.fromJson(stopJson));
      }
    }
    return _stops;
  }

  checkNetworkStatus() async {
    await (Connectivity().checkConnectivity()).then((status) {
      if (status == ConnectivityResult.none) {
        _networkStatus = false;
      } else {
        _networkStatus = true;
      }
    });
    return _networkStatus;
  }

  @override
  void initState() {
    setState(() {
      getApplicationDocumentsDirectory().then((Directory directory) {
        dir = directory;
        savedFile = new File(dir.path + '/' + savedFileName);
        savedExists = savedFile.existsSync();
        if (savedExists) {
          print('saved.json exists');
          savedFile.delete();
          print('saved.json deleted');
        }
        favoritesFile = new File(dir.path + '/' + favoritesFileName);
        favoritesExists = favoritesFile.existsSync();
        if (favoritesExists) {
          print('favorites.json exists');
          List<Stop> _favorites = [];
          var favoritesFileJson = json.decode((favoritesFile.readAsStringSync()));
          for (var favoritesFileJson in favoritesFileJson) {
            _favorites.add(Stop.fromJson(favoritesFileJson));
          }
          favorites.addAll(_favorites);
          print('favorites loaded');
          // favorites.sort((a, b) {
          //   return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          // });
          int i, s;
          for (i = 0; i < favorites.length; i++) {
            for (s = 0; s < stops.length; s++) {
              if (favorites[i].id == stops[s].id) {
                _favoritesForDisplay.add(stops[s]);
              }
            }
          }
          setState(() {
            _favoritesForDisplay = favorites;
          });
        }
        stopsFile = new File(dir.path + '/' + stopsFileName);
        stopsExists = stopsFile.existsSync();
        if (stopsExists) {
          print('stops.json exists');
          List<Stop> _stops = [];
          var stopsFileJson = json.decode((stopsFile.readAsStringSync()));
          for (var stopFileJson in stopsFileJson) {
            _stops.add(Stop.fromJson(stopFileJson));
          }
          stops.addAll(_stops);
          int i, s;
          for (i = 0; i < favorites.length; i++) {
            for (s = 0; s < stops.length; s++) {
              if (favorites[i].id == stops[s].id) {
                stops.remove(stops[s]);
              }
            }
          }
          print('stops cleared');
          // stops.sort((a, b) {
          //   return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          // });
          // print('stops sorted');
          setState(() {
            _stopsForDisplay = stops;
            _isLoading = false;
          });
        }
        checkNetworkStatus().then((status) {
          if (status) {
            fetchStops().then((value) {
              setState(() {
                stops.removeRange(0, stops.length);
                stops.addAll(value);
                int i, s;
                for (i = 0; i < favorites.length; i++) {
                  for (s = 0; s < stops.length; s++) {
                    if (favorites[i].id == stops[s].id) {
                      stops.remove(stops[s]);
                    }
                  }
                }
                print('stops cleared');
                getApplicationDocumentsDirectory().then((Directory dir) {
                  File file = new File(dir.path + "/" + stopsFileName);
                  file.createSync();
                  file.writeAsStringSync(json.encode(stops));
                  print('stops saved');
                });
                // stops.sort((a, b) {
                //   return a.name.toLowerCase().compareTo(b.name.toLowerCase());
                // });
                // print('stops sorted');
                setState(() {
                  _stopsForDisplay = stops;
                  _isLoading = false;
                });
              });
            });
          }
        });
      });
    });
    super.initState();
  }

  File createFile() {
    File file = File(dir.path + "/" + favoritesFileName);
    file.createSync();
    file.writeAsStringSync(json.encode(favorites));
    print('favorites created');
    return file;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(AppLocalizations.of(context).allstopsTitle),
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
          preferredSize: Size.fromHeight(70.0),
          child: _searchBar(),
        ),
      ),
      body: Center(
          child: _isLoading
              ? CircularProgressIndicator()
              : DraggableScrollbar.semicircle(
                  backgroundColor: Theme.of(context).canvasColor,
                  controller: scrollController,
                  child: ListView.builder(
                    controller: scrollController,
                    scrollDirection: Axis.vertical,
                    itemCount: _favoritesForDisplay.length + _stopsForDisplay.length,
                    itemBuilder: (context, index) {
                      return  _listItem(index, index < _favoritesForDisplay.length);
                    },
                  ))),
    );
  }

  _searchBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0, left: 15.0, right: 15.0),
      child: TextField(
        decoration: InputDecoration(
            hintText: AppLocalizations.of(context).searchHint,
            contentPadding: EdgeInsets.only(top: 15.0, bottom: 0.0, left: 16.0),
            hintStyle: TextStyle(color: Colors.white70),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white, width: 1.5)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white, width: 2.0)),
            suffixIcon: IconButton(
              padding: EdgeInsets.only(top: 10.0),
              icon: Icon(Icons.clear),
              color: Colors.white70,
              onPressed: () {
                var text = "";
                this.setState(() {
                  WidgetsBinding.instance.addPostFrameCallback((_) => _textController.clear());
                  _stopsForDisplay = stops.where((stop) {
                    var stopName = removeDiacritics(stop.name).toLowerCase();
                    return stopName.contains(text);
                  }).toList();
                  _favoritesForDisplay = favorites.where((stop) {
                    var stopName = removeDiacritics(stop.name).toLowerCase();
                    return stopName.contains(text);
                  }).toList();
                });
              },
            )),
        autofocus: false,
        autocorrect: false,
        controller: _textController,
        cursorColor: Colors.white,
        maxLines: 1,
        style: TextStyle(fontSize: 20.0, color: Colors.white, decoration: TextDecoration.none),
        onChanged: (text) {
          text = removeDiacritics(text).toLowerCase();
          setState(() {
            _stopsForDisplay = stops.where((stop) {
              var stopName = removeDiacritics(stop.name).toLowerCase();
              return stopName.contains(text);
            }).toList();
            _favoritesForDisplay = favorites.where((stop) {
              var stopName = removeDiacritics(stop.name).toLowerCase();
              return stopName.contains(text);
            }).toList();
          });
        },
      ),
    );
  }

  _listItem(index, bool favorite) {
    int defaultIndex = index - _favoritesForDisplay.length;
    return Column(
      children: [
        TextButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => StopWebView( favorite ? _favoritesForDisplay[index] : _stopsForDisplay[defaultIndex])));
          },
          child: Flex(
            direction: Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Padding(padding: EdgeInsets.only(left: 16.0)),
              Expanded(
                child: Text(
                  favorite ? _favoritesForDisplay[index].name :_stopsForDisplay[defaultIndex].name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 17.5, fontWeight: FontWeight.normal, color: Theme.of(context).textTheme.bodyText1.color),
                ),
              ),
              IconButton(
                icon: favorite ? Icon(Icons.star) :Icon(Icons.star_border),
                color: favorite ? Colors.yellow : Theme.of(context).textTheme.bodyText1.color,
                onPressed: () {
                  if (favorite) {
                    setState(() {
                      stops.add(_favoritesForDisplay[index]);
                      favorites.remove(_favoritesForDisplay[index]);
                      stops.sort((a, b) {
                        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
                      });
                      var text = _textController.text;
                      _stopsForDisplay = stops.where((stop) {
                        var stopName = removeDiacritics(stop.name).toLowerCase();
                        return stopName.contains(text);
                      }).toList();
                      _favoritesForDisplay = favorites.where((stop) {
                        var stopName = removeDiacritics(stop.name).toLowerCase();
                        return stopName.contains(text);
                      }).toList();
                      createFile();
                    });
                  } else {
                    setState(() {
                      print(defaultIndex);
                      favorites.add(_stopsForDisplay[defaultIndex]);
                      print(defaultIndex);
                      stops.remove(_stopsForDisplay[defaultIndex]);
                      favorites.sort((a, b) {
                        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
                      });
                      var text = _textController.text;
                      _stopsForDisplay = stops.where((stop) {
                        var stopName = removeDiacritics(stop.name).toLowerCase();
                        return stopName.contains(text);
                      }).toList();
                      _favoritesForDisplay = favorites.where((stop) {
                        var stopName = removeDiacritics(stop.name).toLowerCase();
                        return stopName.contains(text);
                      }).toList();
                      createFile();
                    });
                  }
                },
              ),
            ],
          ),
        ),
        Divider(
          height: 2.0,
          color: Colors.grey,
        ),
      ],
    );
  }
}
