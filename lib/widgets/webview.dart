import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:url_launcher/url_launcher.dart';

class BasicWebView extends StatefulWidget {
  final url;
  BasicWebView(this.url);
  @override
  BasicWebViewState createState() => BasicWebViewState(url);
}

class BasicWebViewState extends State<BasicWebView> {
  var url;
  var actualUrl;
  var webviewTitle;
  final flutterWebviewPlugin = new FlutterWebviewPlugin();

  @override
  initState() {
    flutterWebviewPlugin.onUrlChanged.listen((url) async {
      webviewTitle = await flutterWebviewPlugin.evalJavascript('window.document.title');
      actualUrl = await flutterWebviewPlugin.evalJavascript('window.document.URL');
      webviewTitle = jsonDecode(webviewTitle);
      actualUrl = jsonDecode(actualUrl);
      setState(() => {});
    });
    super.initState();
  }

  BasicWebViewState(this.url);
  Widget build(BuildContext context) {
    return WebviewScaffold(
      appBar: AppBar(
        title: webviewTitle != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    webviewTitle,
                    style: TextStyle(fontSize: 16.0),
                  ),
                  Text(
                    url,
                    style: TextStyle(fontSize: 8.0),
                  )
                ],
              )
            : Text(
                url,
                style: TextStyle(fontSize: 10.0),
              ),
        actions: <Widget>[
          IconButton(icon: Icon(Icons.exit_to_app), onPressed: (() => launch(actualUrl)))
        ],
      ),
      url: url,
      withJavascript: true,
    );
  }
}
