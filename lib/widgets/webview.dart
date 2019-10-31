import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'stopList.dart';

class StopWebView extends StatefulWidget {
  final Stop stop;
  StopWebView(this.stop);
  @override
  StopWebViewState createState() => StopWebViewState(stop);
}

class StopWebViewState extends State<StopWebView> {
  int tableThemeInt;
  bool _isLoading = true;
  var url;

  _getPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      tableThemeInt = prefs.getInt('tableThemeInt');
      url = stop.url+tableThemeInt.toString();
      print(url);
      _isLoading = false;
    });
  }

  @override
  void initState() {
    _getPrefs();
    super.initState();
  }
  final Stop stop;
  StopWebViewState(this.stop);
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0.0),
        child: AppBar(backgroundColor: Colors.black),
      ),
      body: _isLoading ? Scaffold() :  WebView(
          initialUrl: url, javascriptMode: JavascriptMode.unrestricted,),
    );
  }
}
