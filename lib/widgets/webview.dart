import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'stopList.dart';

class StopWebView extends StatelessWidget {
  final Stop stop;
  StopWebView(this.stop);
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0.0),
        child: AppBar(backgroundColor: Colors.black),
      ),
      body: WebView(
          initialUrl: stop.url, javascriptMode: JavascriptMode.unrestricted),
    );
  }
}

// class NearStopWebView extends StatelessWidget {
//   final NearStop stop;
//   NearStopWebView(this.stop);
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: PreferredSize(
//         preferredSize: Size.fromHeight(0.0),
//         child: AppBar(backgroundColor: Colors.black),
//       ),
//       body: WebView(
//           initialUrl: stop.url, javascriptMode: JavascriptMode.unrestricted),
//     );
//   }
// }