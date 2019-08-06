import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:persist_theme/persist_theme.dart';
import 'package:preferences/preferences.dart';

import 'package:mhd_virtual_table/locale/locales.dart';

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool darkTheme = false;
  bool blackTheme = false;
  var tableTheme = 'Dark';

  _getprefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      darkTheme = prefs.getBool('darkTheme');
      blackTheme = prefs.getBool('blackTheme');
      tableTheme = prefs.getString('tableTheme');
    });
  }

  @override
  void initState() {
    _getprefs();
    super.initState();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(AppLocalizations.of(context).settingsTitle),
      ),
      body: Column(
        children: <Widget>[
          DarkModeSwitch(),
          TrueBlackSwitch(),
          DropdownPreference(
            'Table theme',
            'tableTheme',
            defaultVal: 'Light',
            values: ['Light', 'Dark', 'Blue'],
            onChange: (value) async{
              SharedPreferences prefs = await SharedPreferences.getInstance();
              setState(() {
                prefs.setString('tableTheme', value);
                switch (value){
                  case 'Dark':
                    prefs.setInt('tableThemeInt', 0);
                    break;
                  case 'Light':
                    prefs.setInt('tableThemeInt', 1);
                    break;
                  case 'Blue':
                    prefs.setInt('tableThemeInt', 2);
                    break;
                }
                print(prefs.getInt('tableThemeInt'));
              });
            },
          ),
        ],
      ),
    );
  }
}
