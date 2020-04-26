import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:connectivity/connectivity.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'locale/locales.dart';

class ActualPage extends StatefulWidget {
  @override
  _ActualPageState createState() => _ActualPageState();
}

class _ActualPageState extends State<ActualPage> {
  int tableThemeInt;
  bool _networkStatus = true;
  bool _isLoading = true;
  var baseUrl = "https://imhd.sk/ba/online-zastavkova-tabula?fullscreen=0&skin=";
  var url;

  _getPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      tableThemeInt = prefs.getInt('tableThemeInt');
      url = baseUrl + tableThemeInt.toString();
      print(url);
      _isLoading = false;
    });
  }

  _checkNetworkStatus() async {
    await (Connectivity().checkConnectivity()).then((status) {
      if (status == ConnectivityResult.none) {
        setState(() {
          _networkStatus = false;
        });
      } else {
        setState(() {
          _networkStatus = true;
        });
      }
    });
  }

  @override
  void initState() {
    _getPrefs();
    _checkNetworkStatus();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(preferredSize: Size.fromHeight(0.0), child: AppBar(backgroundColor: Colors.black)),
      body: _networkStatus
          ? _isLoading
              ? CircularProgressIndicator()
              : WebviewScaffold(
                  url: tableThemeInt == 3 ? Theme.of(context).brightness == Brightness.dark ? (baseUrl + "0") : (baseUrl + "1"): url,
                  geolocationEnabled: true,
                )
          : Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                Icon(
                  Icons.signal_cellular_off,
                  size: 150.0,
                  color: Colors.grey[300],
                ),
                Text(
                  AppLocalizations.of(context).noConnectionNearMe,
                  style: TextStyle(color: Colors.grey[500]),
                ),
                RaisedButton(
                    child: Text(AppLocalizations.of(context).retryBtn),
                    onPressed: () {
                      _checkNetworkStatus();
                    }),
              ]),
            ),
    );
  }
}
