import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

class ActualPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
          preferredSize: Size.fromHeight(0.0),
          child: AppBar(backgroundColor: Colors.black)),
      body: WebviewScaffold(
        url: "https://imhd.sk/ba/online-zastavkova-tabula?skin=0&fullscreen=0",
        geolocationEnabled: true,
      ),
    );
  }
}
