import 'package:flutter/material.dart';
import 'package:preferences/preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:persist_theme/persist_theme.dart';

import 'package:mhd_virtual_table/locale/locales.dart';

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final TextEditingController cloudPhraseField = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(AppLocalizations.of(context).settingsTitle),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AutoSwitch(title: Text(AppLocalizations.of(context).autoTheme),),
          DarkModeSwitch(title: Text(AppLocalizations.of(context).darkTheme),),
          TrueBlackSwitch(title: Text(AppLocalizations.of(context).blackTheme),),
          DropdownPreference(
            AppLocalizations.of(context).tableTheme,
            'tableTheme',
            defaultVal: 'Auto',
            values: ['Auto', 'Light', 'Dark', 'Blue'],
            onChange: (value) async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              setState(() {
                switch (value) {
                  case 'Dark':
                    prefs.setString('tableTheme', 'black');
                    break;
                  case 'Light':
                    prefs.setString('tableTheme', 'white');
                    break;
                  case 'Blue':
                    prefs.setString('tableTheme', 'blue');
                    break;
                  case 'Auto':
                    prefs.setString('tableTheme', 'auto');
                    break;
                }
                print(prefs.getString('tableTheme'));
              });
            },
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.only(left:16.0, top: 8.0),
            child: Text(AppLocalizations.of(context).anonymousCloudSave, style: TextStyle(fontSize: 16.0)),
          ),
          Padding(
            padding: const EdgeInsets.only(left:16.0, right:16.0, bottom: 10.0),
            child: TextField(
              controller: cloudPhraseField,
              decoration: InputDecoration(
                hintStyle: TextStyle(fontSize: 14.0),hintText: 'Work in progress',contentPadding: EdgeInsets.all(15.0)),
            ),
          ),
          Flex(
            direction: Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              ElevatedButton(child: Text(AppLocalizations.of(context).loadSettings), onPressed: null),
              ElevatedButton( child: Text(AppLocalizations.of(context).saveSettings), onPressed: null),
            ],
          )
        ],
      ),
    );
  }
}
