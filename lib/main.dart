import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import './Actual.dart';
import './AllStops.dart';
import './NearMe.dart';


void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    
    PermissionHandler().requestPermissions([PermissionGroup.location]);
    return MyAppState();
  }
}

class MyAppState extends State<MyApp> {
  int _selectedPage = 1;
  final _pageOptions = [
    NearMePage(),
    ActualPage(),
    AllStopsPage(),
  ];
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MHD Virtual Table',
      theme: ThemeData(
        primaryColor: Colors.black,
      ),
      home: Scaffold(
        body: _pageOptions[_selectedPage],
        bottomNavigationBar: BottomNavigationBar(
          // type: BottomNavigationBarType.shifting,
          selectedItemColor: Color(0xFFe90007),
          unselectedItemColor: Color(0xFF737373),
          currentIndex: _selectedPage,
          onTap: (int index) {
            setState((){
              _selectedPage = index;
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.near_me),
              title: Text("Near me")
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.my_location),
              title: Text("Actual")
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              title: Text("All stops")
            ),
          ]
        ),
      )
    );
  }
}
