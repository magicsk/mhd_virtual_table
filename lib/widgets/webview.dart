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

  _getprefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      tableThemeInt = prefs.getInt('tableThemeInt');
      url = stop.url + tableThemeInt.toString();
      print(url);
      _isLoading = false;
    });
  }

  @override
  void initState() {
    _getprefs();
    super.initState();
  }

  final Stop stop;
  StopWebViewState(this.stop);
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(stop.name),
        backgroundColor: Colors.black,
      ),
      body: _isLoading
          ? Scaffold()
          : WebView(
              initialUrl: url,
              javascriptMode: JavascriptMode.unrestricted,
            ),
    );
  }
}
