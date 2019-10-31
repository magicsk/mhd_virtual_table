import 'package:flutter/material.dart';

import 'locale/locales.dart';

class TripPlannerPage extends StatefulWidget {
  @override
  _TripPlannerState createState() => _TripPlannerState();
}

class _TripPlannerState extends State<TripPlannerPage> {
  final TextEditingController _fromTextController = new TextEditingController();
  final TextEditingController _toTextController = new TextEditingController();



  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Trip planner'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => Settings(),
              //   ),
              // );
            },
          )
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(118.0),
          child: _searchBar(),
        ),
      ),
    );
  }

  _searchBar() {
    return Padding(
        padding: const EdgeInsets.only(bottom: 20.0, left: 15.0, right: 15.0),
        child: Column(
          children: <Widget>[
            TextField(
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
                        _fromTextController.clear()
                      });
                    },
                ),
              ),
              autofocus: false,
              autocorrect: false,
              controller: _fromTextController,
              cursorColor: Colors.white,
              maxLines: 1,
              style: TextStyle(
                  fontSize: 20.0,
                  color: Colors.white,
                  decoration: TextDecoration.none),
            ),
            TextField(
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
                        _toTextController.clear()
                      });
                    },
                ),
              ),
              autofocus: false,
              autocorrect: false,
              controller: _toTextController,
              cursorColor: Colors.white,
              maxLines: 1,
              style: TextStyle(
                  fontSize: 20.0,
                  color: Colors.white,
                  decoration: TextDecoration.none),
            )
          ],
        ));
  }
}
