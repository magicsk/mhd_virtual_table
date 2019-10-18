import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:connectivity/connectivity.dart';

import 'locale/locales.dart';

class ActualPage extends StatefulWidget {
  @override
  _ActualPageState createState() => _ActualPageState();
}

class _ActualPageState extends State<ActualPage> {
  bool _networkStatus = true;
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
    _checkNetworkStatus();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _networkStatus
        ? Padding(
          padding: EdgeInsets.only(bottom: 50.0),
            child: WebviewScaffold(
              url:
                  "https://imhd.sk/ba/online-zastavkova-tabula?skin=0&fullscreen=0",
              geolocationEnabled: true,
              appBar: CupertinoNavigationBar(),
            ),
          )
        : Center(
            child: Padding(
              padding: EdgeInsets.only(top: 300.0),
              child: Column(children: <Widget>[
                Icon(
                  Icons.signal_cellular_off,
                  size: 200.0,
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
